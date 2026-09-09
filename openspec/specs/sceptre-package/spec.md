# sceptre-package Specification

## Purpose

Provides a reproducible Nix package for the Sceptre Rust CLI so users can install and run its repository, idea, MCP, and specification-workflow commands through the repository's standard package outputs.

## Requirements

### Requirement: Reproducible Sceptre package

The repository SHALL provide a package named `sceptre` built from a pinned revision of `john-craig/sceptre` using its declared Rust project metadata and locked dependencies.

#### Scenario: Package is evaluated
- **WHEN** the package set is evaluated for a supported system
- **THEN** the `sceptre` derivation SHALL evaluate without fetching mutable source references or requiring a network connection during evaluation

#### Scenario: Package is built
- **WHEN** a user runs the documented Sceptre package build
- **THEN** the build SHALL complete successfully using the pinned source and produce the Sceptre executable

### Requirement: Public package exposure

The `sceptre` package SHALL be exposed through the repository's standard `default.nix`, flake `legacyPackages`, and flake `packages` interfaces with metadata identifying its license, homepage, description, and main program.

#### Scenario: Package is consumed through a flake
- **WHEN** a consumer references the repository's `sceptre` package output
- **THEN** the package SHALL resolve for the target system and expose `sceptre` as its main executable

### Requirement: CLI behavior is preserved

The package SHALL preserve the upstream Sceptre CLI entry point and support its documented command families without modifying upstream behavior or embedding credentials and provider configuration.

#### Scenario: CLI help is invoked
- **WHEN** a user runs `sceptre --help`
- **THEN** the command SHALL exit successfully and print the upstream command summary

#### Scenario: Runtime integrations are unavailable
- **WHEN** Sceptre is run without Git, `gh`, `tea`, or remote credentials configured
- **THEN** the package SHALL still start and report the upstream actionable runtime error rather than failing at build time or embedding substitute credentials

### Requirement: Package verification and documentation

The repository SHALL document installation, source revision, runtime dependencies, supported platforms, and basic invocation, and SHALL provide focused package evaluation/build coverage.

#### Scenario: Package contract is tested
- **WHEN** the documented package checks run
- **THEN** they SHALL verify derivation metadata, executable presence, CLI help output, and absence of embedded secret material

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
