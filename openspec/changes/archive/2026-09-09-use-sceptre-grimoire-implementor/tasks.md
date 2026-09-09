## 1. Sceptre Compatibility

- [x] 1.1 Identify and pin an upstream Sceptre revision that supports the required `specset` JSON fields and repeatable explicit implementation paths, update the source hash and package documentation, and verify `nix build .#sceptre` plus the relevant `sceptre specset ... --help` commands succeed.
- [x] 1.2 Extend the Sceptre package check with a hermetic publication fixture that proves explicit implementation files and the materialized specification are committed while an unrelated changed file is excluded, and verify the focused flake check passes without contacting a live provider.

## 2. Home Manager Module

- [x] 2.1 Add `home-modules/project-manager/automated-development-workflows/sceptre-implementor/default.nix` with the disabled-by-default option namespace, runtime package overrides, catalog and relative manifest settings, work-root/model/failure-retention settings, nullable schedule, timer persistence, and assertions; verify module evaluation succeeds when valid and fails for missing required configuration.
- [x] 2.2 Generate and install `sceptre-openspec-implementor` with a self-contained runtime closure and argument validation for configured and command-line catalog/manifest inputs, and verify `--help`, invalid paths, traversal attempts, and missing executables fail as specified.
- [x] 2.3 Export the module as `projectManagerAutomatedDevelopmentWorkflowsSceptreImplementor` from `home-modules/default.nix` and verify the flake exposes the stable Home Manager module name.

## 3. Catalog Selection And Preparation

- [x] 3.1 Implement private temporary-state creation and a clean snapshot of the configured Grimoire checkout's upstream default branch without changing the source checkout, and verify a fixture with uncommitted local catalog edits selects only committed upstream data.
- [x] 3.2 Invoke `sceptre specset ready` and `sceptre specset next`, validate their JSON contracts, and implement distinct ready, complete/no-work, and blocked outcomes; verify fake Sceptre responses cover each path and that blocked/no-work runs never invoke the agent.
- [x] 3.3 Resolve the selected repository mapping, clone its upstream/default branch into isolated state, and invoke Sceptre materialization for the exact target; verify invalid mappings fail before agent execution and configured `local_path` checkouts remain unchanged.

## 4. Agent Execution And Publication

- [x] 4.1 Invoke `opencode-agent` with the exact Sceptre-assigned agent, isolated directory, optional model, and bounded implementation prompt, and verify an unknown assigned environment fails without developer fallback or publication.
- [x] 4.2 Record and validate the target's pre-agent Git state, reject agent commits/branch changes/submodules/unsafe paths, run diff checks, and derive a NUL-safe non-empty implementation path list excluding the materialized specification; verify focused fixtures cover valid, empty, malformed-name, and history-mutating results.
- [x] 4.3 Invoke `sceptre specset publish` with the immutable catalog snapshot and explicit validated implementation paths, parse and report its JSON branch/PR result, and verify success, existing-PR update, and publication-failure cases never stage unrelated files or claim false success.
- [x] 4.4 Implement stage-oriented status-file output, `umask 077`, success/no-work cleanup, optional failed-state retention, and credential-safe diagnostics; verify temporary state permissions and cleanup/retention behavior in focused tests.

## 5. Scheduling

- [x] 5.1 Generate the optional Linux `systemd.user` oneshot service and timer only when a schedule is configured, passing the configured runner settings and persistence value, and verify enabled, disabled, interval, and persistent unit evaluation.
- [x] 5.2 Add a non-blocking runtime lock around scheduled execution and verify concurrent fixture invocations produce one active implementation and one successful skipped result without duplicate Sceptre selection or publication.

## 6. Verification And Documentation

- [x] 6.1 Add the module and workflow checks to `flake.nix`, using fake Sceptre, OpenCode agent, provider clients, and local Git remotes to cover end-to-end selection, exact-agent execution, explicit-path publication, no-work, blocked, failure, and cleanup behavior; verify the new focused checks pass.
- [x] 6.2 Update `home-modules/project-manager/automated-development-workflows/README.md` with manual and scheduled Home Manager examples using `/home/evak/programming/by_category/project_management/grimoire`, a catalog-relative manifest, authentication prerequisites, behavior boundaries, and failure recovery; verify every documented option and command matches the evaluated module.
- [x] 6.3 Run `nix flake check`, `nix build .#sceptre`, and `git diff --check`, and record or resolve every failure before marking the change complete.
