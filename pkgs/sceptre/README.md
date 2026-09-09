# sceptre

`sceptre` is a Rust CLI for Grimoire development workflows, including
repository creation, idea processing, MCP serving, and specification-set
coordination. This package is built from the upstream
[`john-craig/sceptre`](https://github.com/john-craig/sceptre) repository at a
pinned revision.

## Usage

With this repository available as a NUR input or overlay:

```nix
environment.systemPackages = [ pkgs.nur.repos.nixpkgs-apocrypha.sceptre ];
```

The executable is available as `sceptre`:

```console
sceptre repository --help
sceptre idea --help
sceptre mcp --help
```

## Package details

- Version: `0.1.0`
- Source revision: `93694d94313b3658644055414a5bded2c55a9e89`
- License: MIT
- Supported platforms: Unix platforms supported by Nixpkgs
- Build dependencies: Rust and the locked Cargo dependency set
- Runtime integrations: Git, SSH, `gh`, and `tea` are configured by the user

Credentials, repository mappings, provider endpoints, and remote services are
not embedded in this package.

The `specset publish` command accepts repeatable `--implementation-path` values
so callers can publish reviewed implementation files without staging unrelated
worktree changes.
