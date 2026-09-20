## Why

The repaired Epson ES-50 workflow in `../panoply` is useful but currently coupled to one repository's host-service namespace, secret layout, Paperless URL, and hardware assumptions. Downstream NixOS users need to consume the same reliable button-triggered receipt-scanning behavior by configuring their own scanner identity and Paperless instance without copying host-specific implementation code.

## What Changes

- Add a reusable NixOS module for Epson ES-50-style receipt scanning and Paperless uploads.
- Expose declarative options for enablement, stable SANE device identity, USB vendor/product matching, Epson Scan 2/SANE and `es2button` packages or runtime, Paperless URL, token-file source, recovery/output paths, request/lock paths, and optional manual-scan access.
- Preserve the Panoply workflow's validated button-event filtering, atomic pending-request coalescing, serialized worker, listener stop/restart sequencing, Epson settings and temporary-directory preparation, non-empty JPEG upload gate, and protected failed-upload recovery.
- Keep Paperless credentials out of generated command arguments and logs by using systemd credentials or an equivalent protected file mapping owned by the worker service account.
- Provide least-privilege systemd units, scanner-group access, udev rules, narrowly scoped listener-control elevation, runtime assertions, bounded listener restart behavior, and operator-facing manual trigger/status/recovery documentation.
- Export the module through the flake's `nixosModules` output and document a downstream configuration example.
- Add evaluation and generated-configuration tests for defaults, required options, secret handling, service sandboxing, event validation, serialization, recovery, and scanner/Paperless configuration.

## Capabilities

### New Capabilities

- `configurable-receipt-scanner`: Reusable NixOS Epson receipt-scanner service with configurable hardware and Paperless upload targets.

### Modified Capabilities


## Impact

- Adds a new module under `nixos-modules/`, updates `nixos-modules/default.nix`, and extends flake checks and module exports.
- Adds generated unit/script tests and documentation for downstream consumers.
- Depends on NixOS hardware.sane, systemd, udev, sudo-rs, and a configurable Epson Scan 2/es2button runtime; no Paperless server changes are required.
- Existing modules and Panoply-specific namespaces remain unchanged; the new module must not require Panoply's `hostServices`, `sops` declarations, user names, paths, or hard-coded URL.
