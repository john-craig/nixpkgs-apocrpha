{
  description = "My personal NUR repository";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.opencode = {
    url = "github:anomalyco/opencode?ref=v1.18.21";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  inputs.opencode-nix = {
    url = "github:albertov/opencode-nix";
    inputs.nixpkgs.follows = "nixpkgs";
    inputs.opencode.follows = "opencode";
  };
  outputs = { self, nixpkgs, opencode, opencode-nix, ... }:
    let
      opencodeOverlay = final: prev:
        if builtins.hasAttr prev.stdenv.hostPlatform.system opencode.packages
        then let
          overlay = opencode-nix.overlays.default final prev;
        in
          overlay
          // {
            opencode = overlay.opencode.overrideAttrs (_: {
              __intentionallyOverridingVersion = true;
              version = "1.18.21";
            });
          }
        else {};
      forAllSystems = nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed;
      pkgsFor = system: import nixpkgs {
        inherit system;
        overlays = [ opencodeOverlay ];
      };
    in
    {
      legacyPackages = forAllSystems (system: import ./default.nix { pkgs = pkgsFor system; });
      packages = forAllSystems (system: nixpkgs.lib.filterAttrs (_: v: nixpkgs.lib.isDerivation v) self.legacyPackages.${system});
      nixosModules = import ./nixos-modules;
      homeModules = import ./home-modules;
      overlays.opencode-nix = opencodeOverlay;
      checks = forAllSystems (system: let pkgs = pkgsFor system; in {
        sceptre = pkgs.runCommand "sceptre-check" {
          nativeBuildInputs = [ self.legacyPackages.${system}.sceptre ];
        } ''
          test -x "${self.legacyPackages.${system}.sceptre}/bin/sceptre"
           sceptre --help >/dev/null
           sceptre repository --help | grep -q "Usage: sceptre repository"
           sceptre specset publish --help | grep -q -- "--implementation-path"
          test ! -e "${self.legacyPackages.${system}.sceptre}/credentials"
          test ! -e "${self.legacyPackages.${system}.sceptre}/secrets"
          touch "$out"
        '';
        remaining-shell-user-configuration = import ./tests/remaining-shell-user-configuration.nix { inherit pkgs; };
        traefik-modules = import ./tests/traefik-modules.nix { inherit pkgs; };
        opencode-agents = import ./tests/opencode-agents.nix {
          inherit pkgs;
        };
        opencode-agents-user = import ./tests/opencode-agents-user.nix {
          inherit pkgs;
        };
        openspec-implementor = import ./tests/openspec-implementor.nix { inherit pkgs; };
        openspec-implementor-flake = import ./tests/openspec-implementor-flake.nix { inherit pkgs; };
        openspec-implementor-scheduler = import ./tests/openspec-implementor-scheduler.nix { inherit pkgs; };
        sceptre-implementor = import ./tests/sceptre-implementor.nix { inherit pkgs; };
        opencode-agent = let
          opencodeAgent = self.legacyPackages.${system}.opencode-agent;
          fakeOpenCode = pkgs.writeShellScriptBin "opencode" ''
            noAttach=false
            if [[ ''${1-} == --no-attach && ''${2-} == --help ]]; then
              exit 0
            fi
            printf '%s' "''${1-}" > "$CAPTURE/launch-option"
            if [[ ''${1-} == --no-attach ]]; then
              shift
            fi
            printf '%s' "$OPENCODE_CONFIG" > "$CAPTURE/config"
            printf '%s' "''${OPENCODE_CONFIG_DIR-}" > "$CAPTURE/config-dir"
            printf '%s' "$XDG_CONFIG_HOME" > "$CAPTURE/xdg-config-home"
            printf '%s\n' "$@" > "$CAPTURE/arguments"
          '';
        in pkgs.runCommand "opencode-agent-check" {
          nativeBuildInputs = [ opencodeAgent fakeOpenCode pkgs.gnused pkgs.jq ];
          inherit opencodeAgent;
        } ''
          set -euo pipefail
          mkdir project custom-env
          mkdir -p custom-env
          capture="$PWD/capture"
          mkdir "$capture"
          export CAPTURE="$capture"

          opencode-agent --agent software-architect --directory "$PWD/project" --prompt 'Preserve exact prompt.'
           test -f "$capture/config"
           test "$(cat "$capture/launch-option")" = --no-attach
           test -f "$capture/config-dir"
           test -f "$capture/xdg-config-home"
           environment_dir="$(dirname "$(cat "$capture/config")")"
           test ! -s "$capture/config-dir"
           test ! -e "$(cat "$capture/xdg-config-home")"
          for agent in \
            audiovisual-design-assistant default deployment-specialist disk-jockey developer godot-game-developer \
            podcast-writer research-source-collector \
            librarian market-researcher note-taker orchestrator project-manager researcher \
            remote-systems-diagnostics-assistant retrospective software-architect systems-architect \
            toolsmith voice-assistant; do
            test -f "$environment_dir/$agent.json"
            test -f "$environment_dir/$agent/prompt.md"
          done
          ! grep -R -En '/home/evak|/run/user/1000|super-secret|BEGIN (RSA|OPENSSH|PRIVATE) KEY|Bearer [A-Za-z0-9._-]{20,}' "$environment_dir"

          test "$(sed -n '1p' "$capture/arguments")" = run
          test "$(sed -n '2p' "$capture/arguments")" = --dir
          test "$(sed -n '3p' "$capture/arguments")" = "$PWD/project"
          test "$(sed -n '4p' "$capture/arguments")" = --agent
          test "$(sed -n '5p' "$capture/arguments")" = software-architect
          test "$(sed -n '6p' "$capture/arguments")" = 'Preserve exact prompt.'
          jq -e '.agent["software-architect"].permission.edit == "deny"' "$(cat "$capture/config")" >/dev/null
          prompt_path=$(jq -r '.agent["software-architect"].prompt' "$(cat "$capture/config")" | sed 's/^{file://; s/}$//')
          test -f "$prompt_path"
           jq -e '.agent["systems-architect"].permission["context7_*"] == "ask" and .agent["systems-architect"].permission["git_mcp_*"] == "ask"' "$environment_dir/systems-architect.json" >/dev/null

          cp "$(cat "$capture/config")" custom-env/software-architect.json
          rm "$capture/arguments"
          OPENCODE_AGENT_ENVIRONMENT_ROOT="$PWD/custom-env" opencode-agent \
            --agent software-architect --directory "$PWD/project" --prompt override
          test "$(cat "$capture/config")" = "$PWD/custom-env/software-architect.json"
          rm "$capture/arguments"
          set +e
          OPENCODE_AGENT_ENVIRONMENT_ROOT="$PWD/custom-env" opencode-agent \
            --agent missing --directory "$PWD/project" --prompt test
          status=$?
          set -e
          test "$status" -ne 0
          test ! -e "$capture/arguments"
          touch "$out"
        '';
      } // nixpkgs.lib.optionalAttrs (builtins.hasAttr system opencode.packages) {
        opencode-package = pkgs.runCommand "opencode-package-check" {
          nativeBuildInputs = [ pkgs.gnugrep ];
        } ''
          test "${pkgs.opencode.version}" = "1.18.21"
          test -x "${pkgs.opencode}/bin/opencode"
          touch "$out"
        '';
      });
      # darwinModules = import ./darwin-modules;
      # flakeModules = import ./flake-modules;
    };
}
