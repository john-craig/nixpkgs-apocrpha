# sceptre-spec-implementor-workflow Specification

## Purpose

Provide an opt-in Home Manager workflow that turns a coordinated Grimoire specification target into an isolated OpenCode implementation and a single reviewable pull request.

## Requirements

### Requirement: Public opt-in Home Manager module

The repository SHALL provide a Home Manager module for the Sceptre-backed implementation workflow, export it through `homeModules` as `projectManagerAutomatedDevelopmentWorkflowsSceptreImplementor`, and keep it disabled by default. When enabled, the module SHALL install `sceptre-openspec-implementor` and SHALL accept runtime configuration for the Grimoire checkout, spec-set manifest, packages, work root, model override, and failure retention.

#### Scenario: Module is disabled

- **WHEN** the module is imported without enabling it
- **THEN** it SHALL install no Sceptre implementation command and SHALL create no service, timer, runtime state, worktree, branch, or pull request

#### Scenario: Module is enabled

- **WHEN** the module is enabled with a valid Grimoire checkout and manifest configuration
- **THEN** it SHALL install `sceptre-openspec-implementor` with the configured reproducible runtime dependencies

#### Scenario: Required configuration is invalid

- **WHEN** an enabled module lacks a required package or receives an invalid runtime path or timer interval
- **THEN** Home Manager evaluation or command startup SHALL fail with an actionable error before implementation starts

### Requirement: Upstream Grimoire snapshot

The command SHALL treat the configured Grimoire path as a catalog Git checkout, resolve its configured upstream and default branch, and consult a clean temporary snapshot of that upstream branch. The configured checkout and its uncommitted contents SHALL not be modified or used as implementation authority.

#### Scenario: Clean upstream snapshot is available

- **WHEN** the configured checkout has a resolvable upstream and the requested manifest exists in the upstream snapshot
- **THEN** the command SHALL pass the snapshot and its catalog-relative manifest path to Sceptre

#### Scenario: Local Grimoire checkout has uncommitted changes

- **WHEN** the configured checkout contains local modifications that are absent from the upstream default branch
- **THEN** the command SHALL leave those modifications untouched and SHALL not include them in target selection

#### Scenario: Upstream cannot be resolved

- **WHEN** the configured Grimoire checkout, remote, default branch, or manifest cannot be resolved
- **THEN** the command SHALL fail before cloning a target repository or invoking an OpenCode agent

### Requirement: Sceptre owns readiness and target selection

The command SHALL invoke the packaged Sceptre CLI with machine-readable output to validate the configured spec set and select its next implementation target. The command SHALL use Sceptre's returned spec-set ID, repository, specification, assigned agent, branch identity, and completion state without independently reimplementing dependency or eligibility rules.

#### Scenario: Eligible target exists

- **WHEN** Sceptre reports a ready spec set with a next target
- **THEN** the command SHALL continue with exactly the repository, specification, agent, and branch returned for that target

#### Scenario: Spec set is complete

- **WHEN** Sceptre reports that all specifications in the configured spec set are complete
- **THEN** the command SHALL exit successfully with a machine-distinguishable no-work result and SHALL not create a target worktree, invoke an agent, or publish a pull request

#### Scenario: Spec set is blocked

- **WHEN** Sceptre reports invalid repository mappings, agent records, dependencies, or other readiness blockers
- **THEN** the command SHALL report the structured blockers and fail without invoking an agent or performing publication operations

### Requirement: Isolated target preparation and materialization

The command SHALL resolve the selected target repository from the snapshot's Grimoire mapping, clone its configured upstream and default branch into private temporary state, and ask Sceptre to materialize the selected specification there. It SHALL not modify a repository checkout named by Grimoire's `local_path` or any other existing user checkout.

#### Scenario: Target is prepared

- **WHEN** Sceptre returns an eligible target with a valid repository mapping
- **THEN** the command SHALL create an isolated clean target worktree and materialize the exact selected specification before invoking the agent

#### Scenario: Repository mapping is inconsistent

- **WHEN** the selected target does not match a valid upstream-created repository mapping or safe default branch
- **THEN** the command SHALL stop before agent invocation and SHALL preserve an actionable mapping error

### Requirement: Catalog-assigned OpenCode agent execution

The command SHALL invoke `opencode-agent` with the exact agent identifier returned by Sceptre, the isolated target worktree, and an implementation prompt naming the selected specification. It SHALL preserve the selected generated agent definition and SHALL not infer an agent from the repository or specification name or silently fall back to `developer`.

#### Scenario: Assigned agent exists

- **WHEN** the selected agent has a generated OpenCode environment
- **THEN** the command SHALL run that environment against the materialized target worktree and instruct it to implement and validate the selected specification without committing, pushing, opening a pull request, or mutating external systems

#### Scenario: Assigned agent is unavailable

- **WHEN** the selected agent has no generated OpenCode environment
- **THEN** the command SHALL fail before implementation and SHALL not substitute another agent

#### Scenario: Agent fails or changes repository history

- **WHEN** the agent exits unsuccessfully, commits, changes the checked-out branch, or otherwise mutates the worktree's Git history
- **THEN** the command SHALL reject the result and SHALL not publish it

### Requirement: Validated Sceptre publication

After agent success, the command SHALL verify repository identity, unchanged Git history, a clean diff format, and a non-empty implementation diff beyond the materialized specification. It SHALL pass the explicit reviewed implementation paths to `sceptre specset publish`, which SHALL commit the materialized specification and those paths, push the deterministic `feature/<specset-id>` branch, and create or update exactly one pull request against the mapped default branch.

#### Scenario: Implementation is publishable

- **WHEN** the agent exits successfully and the isolated worktree contains a valid non-empty implementation diff
- **THEN** the command SHALL invoke Sceptre publication with only the materialized specification and explicit changed implementation paths and SHALL report the resulting branch and pull-request identity

#### Scenario: Agent produces no implementation

- **WHEN** the only worktree change is Sceptre's materialized specification or no change exists
- **THEN** the command SHALL fail without committing, pushing, or opening a pull request

#### Scenario: Existing implementation pull request exists

- **WHEN** Sceptre finds the one pull request associated with `feature/<specset-id>`
- **THEN** publication SHALL update that branch and pull request rather than create a duplicate

#### Scenario: Publication fails

- **WHEN** validation, commit, push, or pull-request creation fails
- **THEN** the command SHALL return failure, SHALL not claim publication succeeded, and SHALL retain enough stage information for diagnosis

### Requirement: Serialized optional scheduling

The module SHALL optionally provide a Linux `systemd.user` oneshot service and timer that invoke the same installed command for the configured spec set. Scheduled runs SHALL use a non-blocking process lock so only one implementation attempt can run at a time.

#### Scenario: Scheduling is not configured

- **WHEN** the module is enabled without a schedule
- **THEN** it SHALL install the command but SHALL create no implementation service or timer

#### Scenario: Scheduled run starts

- **WHEN** the configured timer activates and no previous run owns the lock
- **THEN** the oneshot service SHALL run at most one selected implementation target and expose its outcome in the user journal

#### Scenario: Previous run remains active

- **WHEN** a timer activation occurs while another workflow process owns the lock
- **THEN** the service SHALL exit successfully as skipped without selecting work or creating a worktree

### Requirement: Cleanup, observability, and secret isolation

The workflow SHALL remove temporary catalog and target state after success or no-work, support preserving failed state for diagnosis, write private runtime files with restrictive permissions, and report stage-oriented results without logging secret values. The module and generated command SHALL not embed provider, Git, or OpenCode credentials or host-specific secret contents in the Nix store.

#### Scenario: Workflow succeeds

- **WHEN** Sceptre reports successful pull-request publication
- **THEN** temporary workflow state SHALL be removed and the command SHALL emit a success result containing the selected target and pull-request identity

#### Scenario: Failure retention is enabled

- **WHEN** a workflow stage fails and failed-state retention is configured
- **THEN** the private temporary state SHALL remain available and its path and failed stage SHALL be reported

#### Scenario: Authentication is unavailable

- **WHEN** Git transport, provider CLI, or OpenCode authentication is unavailable
- **THEN** the workflow SHALL fail closed without synthesizing credentials, exposing secret contents, or publishing a partial result
