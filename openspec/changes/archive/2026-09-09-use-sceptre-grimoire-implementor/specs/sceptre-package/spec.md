## ADDED Requirements

### Requirement: Packaged specification implementation interface

The pinned Sceptre package SHALL provide the machine-readable `specset ready`, `specset next`, `specset materialize`, and `specset publish` operations required by the Grimoire-backed Home Manager implementation workflow. Publication SHALL accept an explicit repeatable set of implementation paths, stage no implementation path outside that set, include the materialized specification, and create or update the deterministic implementation branch and pull request.

#### Scenario: Compatible package is invoked

- **WHEN** the Home Manager workflow invokes the packaged Sceptre executable for a valid spec-set target
- **THEN** every required operation SHALL accept the documented inputs and emit one parseable JSON result

#### Scenario: Explicit implementation paths are published

- **WHEN** `specset publish` receives validated implementation paths from the workflow
- **THEN** it SHALL commit those paths together with the materialized specification and SHALL not stage unrelated worktree changes

#### Scenario: Current package lacks safe publication support

- **WHEN** a candidate pinned revision cannot publish explicit implementation paths or cannot provide the required JSON fields
- **THEN** package compatibility checks SHALL fail and the workflow SHALL not be released against that revision
