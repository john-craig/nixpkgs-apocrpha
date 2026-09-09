{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.evak.project-manager.automated-development-workflows.sceptre-implementor;
  packageFor = name:
    if builtins.hasAttr name pkgs then builtins.getAttr name pkgs else null;
  runner = pkgs.writeShellApplication {
    name = "sceptre-openspec-implementor";
    runtimeInputs = lib.filter (package: package != null) [
      cfg.gitPackage
      cfg.jqPackage
      cfg.sceptrePackage
      cfg.opencodeAgentPackage
      cfg.flockPackage
    ];
    text = ''
      set -euo pipefail
      umask 077

      usage() {
        cat >&2 <<'EOF'
      Usage: sceptre-openspec-implementor [OPTIONS]

      Options:
        --catalog PATH       Grimoire checkout (default: configured value)
        --manifest PATH      Manifest relative to the catalog (default: configured value)
        --model MODEL        OpenCode model override
        --work-root PATH     Parent directory for private workflow state
        --keep-worktree      Preserve failed workflow state
        --status-file PATH   Write success, no-work, blocked, or failure
        --help               Show this help
      EOF
      }
      fail() {
        [[ -z ''${status_file:-} ]] || printf '%s\n' failure >"$status_file" || true
        printf 'sceptre-openspec-implementor: %s\n' "$*" >&2
        exit 1
      }
      catalog=${if cfg.catalogPath == null then "" else lib.escapeShellArg cfg.catalogPath}
      manifest=${if cfg.manifestPath == null then "" else lib.escapeShellArg cfg.manifestPath}
      model=${lib.escapeShellArg (if cfg.model == null then "" else cfg.model)}
      work_root=${lib.escapeShellArg (if cfg.workRoot == null then "" else cfg.workRoot)}
      keep_worktree=${lib.boolToString cfg.keepWorktree}
      status_file=""
      while (($# > 0)); do
        case "$1" in
          --catalog) (($# >= 2)) || fail '--catalog requires a path'; catalog="$2"; shift 2 ;;
          --manifest) (($# >= 2)) || fail '--manifest requires a relative path'; manifest="$2"; shift 2 ;;
          --model) (($# >= 2)) || fail '--model requires a value'; model="$2"; shift 2 ;;
          --work-root) (($# >= 2)) || fail '--work-root requires a path'; work_root="$2"; shift 2 ;;
          --keep-worktree) keep_worktree=true; shift ;;
          --status-file) (($# >= 2)) || fail '--status-file requires a path'; status_file="$2"; shift 2 ;;
          --help|-h) usage; exit 0 ;;
          *) fail "unknown argument: $1" ;;
        esac
      done
      [[ -d "$catalog/.git" ]] || fail "catalog is not a Git checkout: $catalog"
      [[ "$manifest" != /* && "$manifest" != .. && "$manifest" != ../* && "$manifest" != */../* && "$manifest" != */.. ]] ||
        fail 'manifest must be a path relative to the catalog without parent traversal'
      [[ -n "$manifest" ]] || fail 'manifest must not be empty'
      [[ -z "$work_root" || -d "$work_root" ]] || fail "work root does not exist: $work_root"

      parent="''${work_root:-''${TMPDIR:-/tmp}}"
      root=$(mktemp -d "$parent/sceptre-openspec-implementor.XXXXXX")
      catalog_snapshot="$root/catalog"
      target="$root/target"
      cleanup() {
        rc=$?
        if [[ "$rc" -ne 0 && "$keep_worktree" == true ]]; then
          printf 'sceptre-openspec-implementor: preserved failed state at %s\n' "$root" >&2
          trap - EXIT
          return "$rc"
        fi
        rm -rf "$root"
        return "$rc"
      }
      trap cleanup EXIT

      catalog_remote=$(git -C "$catalog" remote get-url origin) || fail 'unable to resolve catalog origin'
      catalog_branch=$(git -C "$catalog" ls-remote --symref "$catalog_remote" HEAD 2>/dev/null |
        awk '$1 == "ref:" && $2 ~ /^refs\/heads\// {sub("refs/heads/", "", $2); print $2; exit}') ||
        fail 'unable to resolve catalog default branch'
      if [[ -z "$catalog_branch" ]]; then
        catalog_branch=$(git -C "$catalog" branch --show-current)
      fi
      [[ -n "$catalog_branch" ]] || fail 'catalog default branch is empty'
      git clone --quiet --branch "$catalog_branch" --single-branch "$catalog_remote" "$catalog_snapshot" || fail 'unable to clone catalog snapshot'
      manifest_path="$catalog_snapshot/$manifest"
      [[ -f "$manifest_path" ]] || fail "manifest does not exist in catalog snapshot: $manifest"

      ready=$(sceptre specset ready --manifest "$manifest_path" --catalog "$catalog_snapshot") || fail 'Sceptre readiness check failed'
      jq -e 'type == "object" and (.status == "ready" or .status == "complete")' >/dev/null <<<"$ready" || {
        printf '%s\n' "$ready" >&2
        fail 'Sceptre returned an invalid readiness result'
      }
      if jq -e '.status == "complete"' >/dev/null <<<"$ready"; then
        [[ -z "$status_file" ]] || printf '%s\n' no-work >"$status_file"
        printf '%s\n' "$ready"
        exit 0
      fi
      jq -e '.status == "ready"' >/dev/null <<<"$ready" || {
        printf '%s\n' "$ready" >&2
        fail 'spec set is blocked'
      }

      next=$(sceptre specset next --manifest "$manifest_path" --catalog "$catalog_snapshot") || fail 'Sceptre target selection failed'
      jq -e '.status == "complete" or (.status == "available" and (.target.repository | type == "string") and (.target.specification | type == "string") and (.target.agent | type == "string"))' >/dev/null <<<"$next" || {
        printf '%s\n' "$next" >&2
        fail 'Sceptre returned an invalid target result'
      }
      if jq -e '.status == "complete"' >/dev/null <<<"$next"; then
        [[ -z "$status_file" ]] || printf '%s\n' no-work >"$status_file"
        printf '%s\n' "$next"
        exit 0
      fi
      specset_id=$(jq -r '.specset_id // .specsetId // empty' <<<"$next")
      repository=$(jq -r '.target.repository' <<<"$next")
      specification=$(jq -r '.target.specification' <<<"$next")
      agent=$(jq -r '.target.agent' <<<"$next")
      branch=$(jq -r '.branch // empty' <<<"$next")
      [[ -n "$specset_id" && -n "$repository" && -n "$specification" && -n "$agent" && "$branch" == "feature/$specset_id" ]] || fail 'Sceptre target is missing required identity fields'
      [[ "$repository" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]] || fail "unsafe repository identifier: $repository"
      [[ "$specification" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]] || fail "unsafe specification identifier: $specification"
      mapping="$catalog_snapshot/repos/$repository.json"
      [[ -f "$mapping" ]] || fail "repository mapping does not exist: $repository"
      upstream=$(jq -r '.upstream // empty' "$mapping")
      base_branch=$(jq -r '.default_branch // empty' "$mapping")
      upstream_created=$(jq -r '.upstream_created // false' "$mapping")
      [[ "$upstream_created" == true && -n "$upstream" && -n "$base_branch" ]] || fail "invalid repository mapping: $repository"
      git clone --quiet --branch "$base_branch" --single-branch "$upstream" "$target" || fail 'unable to clone target repository'
      sceptre specset materialize --manifest "$manifest_path" --catalog "$catalog_snapshot" --worktree "$target" >/dev/null || fail 'Sceptre materialization failed'
      before_head=$(git -C "$target" rev-parse HEAD)
      before_branch=$(git -C "$target" branch --show-current)
      [[ "$before_branch" == "$base_branch" ]] || fail "target clone is on unexpected branch: $before_branch"

      prompt=$(cat <<EOF
      Implement the materialized OpenSpec specification '$specification' for the
      '$repository' repository. Inspect the specification and existing code, make
      the smallest required changes, and run focused validation. Do not commit,
      push, open a pull request, merge, deploy, mutate external systems, or change
      unrelated files; the calling workflow handles publication.
      EOF
      )
      agent_args=(--agent "$agent" --directory "$target" --prompt "$prompt")
      [[ -z "$model" ]] || agent_args+=(--model "$model")
      opencode-agent "''${agent_args[@]}" || fail 'OpenCode agent failed'
      [[ "$(git -C "$target" rev-parse HEAD)" == "$before_head" ]] || fail 'agent changed repository history'
      [[ "$(git -C "$target" branch --show-current)" == "$before_branch" ]] || fail 'agent changed the target branch'
      git -C "$target" diff --check || fail 'implementation diff contains whitespace errors'
      materialized="openspec/specs/$specification/spec.md"
      mapfile -d $'\0' -t implementation_paths < <(
        { git -C "$target" diff --name-only -z; git -C "$target" ls-files --others --exclude-standard -z; } |
          while IFS= read -r -d $'\0' path; do [[ "$path" != "$materialized" ]] && printf '%s\0' "$path"; done
      )
      ((''${#implementation_paths[@]} > 0)) || fail 'agent produced no implementation changes'
      for path in "''${implementation_paths[@]}"; do
        [[ "$path" != /* && "$path" != .. && "$path" != ../* && "$path" != */../* && "$path" != */.. ]] || fail "unsafe implementation path: $path"
        [[ ! -L "$target/$path" ]] || fail "implementation path is a symlink: $path"
      done
      publish_args=(specset publish --manifest "$manifest_path" --catalog "$catalog_snapshot" --worktree "$target" --message "Implement $specification" --title "Implement $specification")
      for path in "''${implementation_paths[@]}"; do publish_args+=(--implementation-path "$path"); done
      result=$(sceptre "''${publish_args[@]}") || fail 'Sceptre publication failed'
      jq -e '.status == "published" and (.pull_request != null)' >/dev/null <<<"$result" || fail 'Sceptre returned an invalid publication result'
      [[ -z "$status_file" ]] || printf '%s\n' success >"$status_file"
      printf '%s\n' "$result"
    '';
  };
  scheduledRunner = pkgs.writeShellApplication {
    name = "sceptre-openspec-implementor-scheduled";
    runtimeInputs = [cfg.flockPackage runner];
    text = ''
      set -euo pipefail
      lock_file="''${XDG_RUNTIME_DIR:-/tmp}/evak-sceptre-openspec-implementor.lock"
      exec 9>"$lock_file"
      if ! flock -n 9; then
        printf '%s\n' 'sceptre-openspec-implementor: skipped; a previous run is still active'
        exit 0
      fi
      exec sceptre-openspec-implementor "$@"
    '';
  };
in {
  options.evak.project-manager.automated-development-workflows.sceptre-implementor = {
    enable = lib.mkEnableOption "Sceptre-backed Grimoire OpenSpec implementation";
    catalogPath = lib.mkOption { type = lib.types.nullOr lib.types.str; default = null; description = "Local Grimoire Git checkout used to resolve its upstream snapshot."; };
    manifestPath = lib.mkOption { type = lib.types.nullOr lib.types.str; default = null; description = "Manifest path relative to the Grimoire checkout."; };
    model = lib.mkOption { type = lib.types.nullOr lib.types.str; default = null; description = "Optional OpenCode model override."; };
    workRoot = lib.mkOption { type = lib.types.nullOr lib.types.str; default = null; description = "Optional parent directory for private workflow state."; };
    keepWorktree = lib.mkOption { type = lib.types.bool; default = false; description = "Preserve failed workflow state."; };
    interval = lib.mkOption { type = lib.types.nullOr (lib.types.strMatching "[0-9]+(ms|s|min|h|d|weeks?)"); default = null; description = "Optional systemd user timer interval."; };
    persistent = lib.mkOption { type = lib.types.bool; default = false; description = "Replay a missed timer activation."; };
    gitPackage = lib.mkOption { type = lib.types.nullOr lib.types.package; default = packageFor "git"; description = "Git package."; };
    jqPackage = lib.mkOption { type = lib.types.nullOr lib.types.package; default = packageFor "jq"; description = "jq package."; };
    sceptrePackage = lib.mkOption { type = lib.types.nullOr lib.types.package; default = packageFor "sceptre"; description = "Sceptre package."; };
    opencodeAgentPackage = lib.mkOption { type = lib.types.nullOr lib.types.package; default = packageFor "opencode-agent"; description = "OpenCode agent runner package."; };
    flockPackage = lib.mkOption { type = lib.types.nullOr lib.types.package; default = packageFor "util-linux"; description = "Package providing flock."; };
  };
  config = lib.mkIf cfg.enable {
    assertions = [
      { assertion = cfg.gitPackage != null; message = "sceptre-implementor requires Git."; }
      { assertion = cfg.jqPackage != null; message = "sceptre-implementor requires jq."; }
      { assertion = cfg.sceptrePackage != null; message = "sceptre-implementor requires Sceptre."; }
      { assertion = cfg.opencodeAgentPackage != null; message = "sceptre-implementor requires opencode-agent."; }
      { assertion = cfg.catalogPath != null; message = "sceptre-implementor requires catalogPath."; }
      { assertion = cfg.manifestPath != null; message = "sceptre-implementor requires manifestPath."; }
      { assertion = cfg.interval == null || cfg.flockPackage != null; message = "scheduled sceptre-implementor requires flock."; }
    ];
    home.packages = [runner];
    systemd.user.services = lib.mkIf (cfg.interval != null) {
      "evak-sceptre-openspec-implementor" = {
        Unit.Description = "Run the Sceptre OpenSpec implementor";
        Service = { Type = "oneshot"; ExecStart = "${scheduledRunner}/bin/sceptre-openspec-implementor-scheduled"; };
      };
    };
    systemd.user.timers = lib.mkIf (cfg.interval != null) {
      "evak-sceptre-openspec-implementor" = {
        Unit.Description = "Periodically run the Sceptre OpenSpec implementor";
        Timer = { OnBootSec = cfg.interval; OnUnitActiveSec = cfg.interval; Persistent = cfg.persistent; Unit = "evak-sceptre-openspec-implementor.service"; };
        Install.WantedBy = ["timers.target"];
      };
    };
  };
}
