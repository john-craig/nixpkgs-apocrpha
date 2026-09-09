{pkgs}: let
  fakeSceptre = pkgs.writeShellScriptBin "sceptre" ''
    set -euo pipefail
    action="''${2:-}"
    case "$action" in
      ready)
        if [[ ''${SCEPTRE_MODE:-success} == blocked ]]; then
          printf '%s\n' '{"status":"blocked","specset_id":"demo","blockers":["fixture blocker"]}'
        else
          printf '%s\n' '{"status":"ready","specset_id":"demo"}'
        fi
        ;;
      next)
        if [[ ''${SCEPTRE_MODE:-success} == complete ]]; then
          printf '%s\n' '{"status":"complete","specset_id":"demo"}'
        else
          printf '%s\n' '{"status":"available","specset_id":"demo","branch":"feature/demo","target":{"repository":"target","specification":"developer-demo","agent":"software-architect"}}'
        fi
        ;;
      materialize)
        worktree=""
        while (($# > 0)); do
          case "$1" in
            --worktree) worktree="$2"; shift 2 ;;
            *) shift ;;
          esac
        done
        mkdir -p "$worktree/openspec/specs/developer-demo"
        printf '%s\n' materialized > "$worktree/openspec/specs/developer-demo/spec.md"
        ;;
      publish)
        printf '%s\n' "$@" > "$PUBLISH_CAPTURE"
        printf '%s\n' '{"status":"published","specset_id":"demo","branch":"feature/demo","pull_request":{"number":1}}'
        ;;
      *)
        printf '%s\n' 'unexpected sceptre invocation' >&2
        exit 2
        ;;
    esac
  '';
  fakeAgent = pkgs.writeShellScriptBin "opencode-agent" ''
    set -euo pipefail
    directory=""
    agent=""
    while (($# > 0)); do
      case "$1" in
        --directory) directory="$2"; shift 2 ;;
        --agent) agent="$2"; shift 2 ;;
        --prompt|--model) shift 2 ;;
        *) shift ;;
      esac
    done
    test "$agent" = software-architect
    printf '%s\n' invoked > "$AGENT_CAPTURE"
    mkdir -p "$directory/src"
    printf '%s\n' implementation > "$directory/src/implementation.txt"
  '';
  evalModule = extra:
    pkgs.lib.evalModules {
      specialArgs = {inherit pkgs;};
      modules = [
        ./../home-modules/project-manager/automated-development-workflows/sceptre-implementor
        ({lib, ...}: {
          options.assertions = lib.mkOption {
            type = lib.types.listOf (lib.types.submodule {
              options = {
                assertion = lib.mkOption {type = lib.types.bool;};
                message = lib.mkOption {type = lib.types.str;};
              };
            });
            default = [];
          };
          options.home.packages = lib.mkOption {type = lib.types.listOf lib.types.package; default = [];};
          options.systemd.user.services = lib.mkOption {type = lib.types.attrsOf lib.types.anything; default = {};};
          options.systemd.user.timers = lib.mkOption {type = lib.types.attrsOf lib.types.anything; default = {};};
        })
        extra
      ];
    };
  disabled = evalModule {};
  enabled = evalModule {
    config.evak.project-manager.automated-development-workflows.sceptre-implementor = {
      enable = true;
      catalogPath = "/tmp/grimoire";
      manifestPath = "specs/demo/manifest.yaml";
      sceptrePackage = fakeSceptre;
      opencodeAgentPackage = fakeAgent;
      interval = "6h";
    };
  };
  runner = builtins.head enabled.config.home.packages;
in
assert disabled.config.home.packages == [];
assert disabled.config.systemd.user.services == {};
assert builtins.length enabled.config.home.packages == 1;
assert enabled.config.systemd.user.services."evak-sceptre-openspec-implementor".Service.Type == "oneshot";
assert builtins.match ".*sceptre-openspec-implementor-scheduled.*" enabled.config.systemd.user.services."evak-sceptre-openspec-implementor".Service.ExecStart != null;
assert enabled.config.systemd.user.timers."evak-sceptre-openspec-implementor".Timer.OnUnitActiveSec == "6h";
pkgs.runCommand "sceptre-implementor-test" {
  nativeBuildInputs = [runner pkgs.git pkgs.jq pkgs.util-linux];
} ''
  set -euo pipefail
  export GIT_AUTHOR_NAME=test
  export GIT_AUTHOR_EMAIL=test@example.invalid
  export GIT_COMMITTER_NAME=test
  export GIT_COMMITTER_EMAIL=test@example.invalid
  export PUBLISH_CAPTURE="$PWD/publish-capture"
  export AGENT_CAPTURE="$PWD/agent-capture"
  git init --bare catalog-origin >/dev/null
  git init catalog >/dev/null
  git -C catalog config user.email test@example.invalid
  git -C catalog config user.name test
  mkdir -p catalog/specs/demo catalog/repos
  printf '%s\n' 'id: demo' > catalog/specs/demo/manifest.yaml
  printf '%s\n' '{"id":"target","upstream":"file://'$PWD'/target-origin","upstream_created":true,"default_branch":"main"}' > catalog/repos/target.json
  git -C catalog add .
  git -C catalog commit -m initial >/dev/null
  git -C catalog branch -M main
  git -C catalog remote add origin "file://$PWD/catalog-origin"
  git -C catalog push origin main >/dev/null
  git init --bare target-origin >/dev/null
  git init target-seed >/dev/null
  git -C target-seed config user.email test@example.invalid
  git -C target-seed config user.name test
  printf '%s\n' base > target-seed/README.md
  git -C target-seed add README.md
  git -C target-seed commit -m initial >/dev/null
  git -C target-seed branch -M main
  git -C target-seed remote add origin "file://$PWD/target-origin"
  git -C target-seed push origin main >/dev/null
  mkdir work
  sceptre-openspec-implementor --catalog "$PWD/catalog" --manifest specs/demo/manifest.yaml --work-root "$PWD/work" > result
  jq -e '.status == "published" and .pull_request.number == 1' result >/dev/null
  grep -q -- '--implementation-path' "$PUBLISH_CAPTURE"
  grep -q 'src/implementation.txt' "$PUBLISH_CAPTURE"
  test -z "$(find work -mindepth 1 -maxdepth 1 -print)"
  rm -f "$AGENT_CAPTURE"
  SCEPTRE_MODE=complete sceptre-openspec-implementor --catalog "$PWD/catalog" --manifest specs/demo/manifest.yaml --work-root "$PWD/work" > no-work
  grep -q '"status":"complete"' no-work
  test ! -e "$AGENT_CAPTURE"
  SCEPTRE_MODE=blocked sceptre-openspec-implementor --catalog "$PWD/catalog" --manifest specs/demo/manifest.yaml --work-root "$PWD/work" > blocked 2>&1 && exit 1 || true
  grep -q 'fixture blocker' blocked
  test ! -e "$AGENT_CAPTURE"
  lock="$PWD/concurrency.lock"
  flock -n "$lock" sh -c 'sleep 1' & holder=$!
  sleep 0.1
  if flock -n "$lock" sh -c 'exit 1'; then
    exit 1
  fi
  wait "$holder"
  touch "$out"
''
