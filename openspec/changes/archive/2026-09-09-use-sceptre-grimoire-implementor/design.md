## Context

The repository already ships a generic `openspec-implementor`, a separate scheduler, generated OpenCode agent environments, and a pinned Sceptre package. The generic runner selects active changes from the cloned target repository and publishes through `gh` or `tea`; it intentionally does not understand Grimoire manifests. Sceptre already owns Grimoire spec-set validation, dependency-aware target selection, materialization, deterministic branch naming, and provider publication. See `proposal.md` for motivation and `specs/sceptre-spec-implementor-workflow/spec.md` for the new behavior contract.

The currently pinned Sceptre revision is not sufficient for safe end-to-end publication: its implementation stages `openspec/specs` but not an explicit set of agent-produced implementation files. The workflow therefore depends on pinning a revision that implements the publication contract in `specs/sceptre-package/spec.md`.

## Goals / Non-Goals

**Goals:**

- Keep Grimoire eligibility and ordering logic inside Sceptre.
- Run exactly the agent assigned by the selected Grimoire specification.
- Keep both the catalog snapshot and target implementation isolated from existing checkouts.
- Publish only a validated materialized specification and explicit implementation paths.
- Provide one manual command with optional serialized `systemd.user` scheduling.
- Preserve actionable state on request while cleaning successful runs automatically.

**Non-Goals:**

- Replacing or changing the generic repository-local implementor and scheduler.
- Discovering arbitrary repository-local `openspec/changes` through Sceptre.
- Implementing Sceptre's catalog, dependency, branch, or pull-request algorithms in shell.
- Merging pull requests, processing review feedback, synchronizing merged specs to Grimoire, or deploying results.
- Supporting multiple spec-set manifests in one command invocation.
- Storing credentials, creating provider accounts, or configuring Git, provider, and OpenCode authentication.

## Decisions

### Add a separate Sceptre implementor module

Add the sibling module `project-manager/automated-development-workflows/sceptre-implementor`, exporting `projectManagerAutomatedDevelopmentWorkflowsSceptreImplementor` and installing `sceptre-openspec-implementor`, instead of adding a mode flag to the generic implementor. The two workflows have different authorities and inputs: one selects repository-local changes, while the other selects a Grimoire spec-set target and delegates publication to Sceptre. Keeping separate commands avoids ambiguous option combinations and preserves the existing public contract. Shared shell construction can be extracted later only if meaningful duplication appears.

### Configure one catalog checkout and one catalog-relative manifest

The module will expose runtime string options for `catalogPath` and `manifestPath`, with the manifest required to be relative to the Grimoire root. String options avoid importing mutable user repositories into the Nix store during evaluation. One manifest per configured runner keeps selection deterministic and maps directly to Sceptre's interface; users can instantiate separate Home Manager configurations or invoke command overrides for other spec sets.

### Consult a clean upstream catalog snapshot

The runner will use the configured checkout only to resolve and fetch its `origin`, then create a temporary clean snapshot of the remote default branch. Selection will not read uncommitted catalog files. Cloning directly from the resolved remote was chosen over `git pull --ff-only` because it does not move the user's checkout or conflict with local work. The manifest path is validated as relative and resolved beneath the snapshot before Sceptre is called.

### Treat Sceptre JSON as the workflow authority

The runner will call `sceptre specset ready` followed by `sceptre specset next` and validate required JSON fields with jq. It will branch only on Sceptre's documented `ready`, `blocked`, and `complete` outcomes. It will not scan manifest dependencies or infer repository and agent identities itself. Repository metadata is read only to perform the clone requested by the selected target and is checked against the returned repository ID.

### Clone the target rather than reuse `local_path`

The selected mapping's `upstream` and `default_branch` will seed a temporary target clone. Grimoire's `local_path` is informative and will not be used as a mutable workspace. This costs an additional clone but prevents autonomous runs from altering an active developer checkout and makes cleanup reliable.

### Invoke the exact generated agent environment

The runner will pass Sceptre's `.target.agent` directly to `opencode-agent`. The runner package already rejects unknown generated environments, so no duplicated static agent list or developer fallback is needed. The prompt will identify the specification and boundaries: inspect the materialized spec and repository, implement it, run focused checks, preserve unrelated files, and do not commit, push, publish, merge, deploy, or recursively delegate.

### Detect implementation paths from a controlled worktree

The runner will record the target HEAD, branch, and status after Sceptre materialization and before agent invocation. After the agent exits it will require the same HEAD and expected checkout state, run `git diff --check`, and derive changed and untracked paths using NUL-delimited Git output. The known materialized `openspec/specs/<specification>/spec.md` path is excluded from the implementation-path list. Empty implementation lists, unsafe paths, submodules, history mutations, and paths outside the worktree are rejected. The resulting explicit list is supplied as repeated Sceptre publication arguments so unrelated files cannot be staged accidentally.

### Require Sceptre to own commit, push, and PR operations

The shell coordinator will not duplicate provider publication. After local validation it will call `sceptre specset publish` with the same snapshot, manifest, worktree, message, title, and explicit implementation paths. Sceptre remains responsible for `feature/<specset-id>`, commit creation, push, provider normalization, and create-or-update behavior. The package pin and tests must prove that implementation paths are included before the module is considered usable.

### Make scheduling an optional layer over the same command

The enabled module always installs the command. A nullable schedule option controls creation of one `systemd.user` oneshot service and timer. The service invokes the same command and acquires a non-blocking `flock` under `%t`; overlap exits as a successful skip. Timer persistence is separately configurable and disabled by default. This avoids a second scheduler implementation while keeping manual use available.

### Use stage-oriented status and private temporary state

The runner will set `umask 077`, create state below a configured work root or a private temporary parent, and track the current stage for errors. Success, no-work, blocked, and failure are distinguishable in command output and an optional status file. Successful and no-work runs clean up; failures clean up unless `keepWorktree` is enabled. Logs contain identifiers and paths needed for diagnosis but never credential values or raw provider diagnostics beyond Sceptre's redacted JSON.

## Risks / Trade-offs

- **The packaged Sceptre revision may lag the required publication API** -> Gate the module with CLI contract tests and update the pin only to a revision that accepts explicit implementation paths.
- **A catalog fetch can race with an upstream update** -> Resolve one remote commit and use the same immutable snapshot for readiness, selection, materialization, and publication.
- **Agent-generated files can contain unsafe names or unexpected repository constructs** -> Use NUL-delimited Git status, reject unsafe paths and submodules, and pass an explicit path list to Sceptre.
- **A generated agent may exist in Grimoire but not in the packaged OpenCode environments** -> Fail before implementation with the selected agent ID; never substitute a more permissive role.
- **Automated publication can expose unintended code** -> Require unchanged history, diff checks, non-empty implementation paths, explicit staging boundaries, and fail closed before Sceptre publication.
- **Temporary clones increase network and disk use** -> Perform at most one target per invocation, serialize scheduled execution, and clean state after success or no-work.
- **Home Manager systemd units are Linux-specific** -> Keep the command portable to supported Unix systems and generate scheduling units only where `systemd.user` is available.

## Migration Plan

1. Update the Sceptre pin and package checks to establish the required JSON and explicit-path publication contract.
2. Add the new module, command, export, and focused fake-command tests without changing the generic implementor modules.
3. Add optional service/timer tests and document manual and scheduled configuration using a catalog path and catalog-relative manifest.
4. Enable the module on a test user with scheduling disabled, run against a disposable spec set and remotes, and verify the selected agent, staged paths, branch, and single pull request.
5. Enable scheduling only after runtime Git, provider, and OpenCode authentication is confirmed.

Rollback consists of disabling the new module and reverting its export and Sceptre pin. Existing generic implementor behavior and already-open pull requests remain unaffected; no state migration is required.
