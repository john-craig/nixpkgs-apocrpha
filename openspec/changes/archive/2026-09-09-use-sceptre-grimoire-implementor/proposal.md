## Why

The existing implementor discovers repository-local OpenSpec changes and cannot execute the coordinated implementation work described by the upstream Grimoire catalog. Users need an opt-in Home Manager workflow that delegates catalog validation, target selection, materialization, and pull-request publication to Sceptre while running the catalog-assigned OpenCode agent in an isolated target worktree.

## What Changes

- Add a Home Manager module for a Grimoire-backed specification implementation workflow, exported through a stable `homeModules` name and disabled by default.
- Add an executable that accepts a Grimoire catalog checkout and a spec-set manifest, refreshes the catalog safely, and uses the packaged Sceptre CLI to validate and select the next eligible implementation target.
- Update the pinned Sceptre package to a compatible upstream revision whose `specset publish` operation can publish an explicit, validated set of implementation paths in addition to the materialized specification.
- Resolve the selected repository from Grimoire metadata, create an isolated target worktree, materialize the selected specification, and invoke `opencode-agent` with the exact agent returned by Sceptre.
- Verify that the agent changed only the isolated target worktree, require a non-empty validated diff, and use `sceptre specset publish` to commit, push, and open or update the deterministic implementation pull request.
- Add an optional serialized `systemd.user` oneshot service and timer with private runtime state, explicit scheduling, and no-work behavior.
- Preserve the existing generic `openspec-implementor` and scheduler behavior for repository-local changes that are not represented by a Grimoire spec set.
- Add focused module and workflow tests using fake Sceptre, OpenCode agent, provider, and local Git inputs, plus operator documentation.

## Capabilities

### New Capabilities

- `sceptre-spec-implementor-workflow`: Configure and run an opt-in Home Manager workflow that selects Grimoire specification work through Sceptre, invokes the assigned OpenCode agent, and publishes one implementation pull request.

### Modified Capabilities

- `sceptre-package`: Require the packaged Sceptre revision to expose the complete spec-set selection, materialization, and implementation-publication interface consumed by the Home Manager workflow.

## Impact

- Adds a module below `home-modules/project-manager/automated-development-workflows/` and exports it from `home-modules/default.nix` and the flake's `homeModules` output.
- Updates the pinned Sceptre source revision and depends at runtime on `sceptre` and `opencode-agent` plus Git, jq, and the provider clients required by Sceptre.
- Reads the configured Grimoire checkout, manifest, repository mappings, and agent records; writes only temporary workflow state and the selected target repository branch/PR through Sceptre.
- Requires existing Git transport, provider CLI, and OpenCode authentication at runtime; no credentials or host-specific secret values are embedded in Nix store outputs.
- Adds focused checks to `tests/` and `flake.nix`, and updates automated-development-workflow documentation.
