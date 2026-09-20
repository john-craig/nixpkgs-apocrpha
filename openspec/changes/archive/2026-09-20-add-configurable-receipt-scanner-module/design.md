## Context

`../panoply` currently combines a shared `scan-document`/`scan-receipt` uploader with host-specific Ansible provisioning and a NixOS `epsonEs2Button` module. The NixOS implementation already demonstrates the important lifecycle: the root listener only queues validated events, the worker owns serialization and listener handoff, systemd credentials protect the Paperless token, and failed uploads remain in a restricted recovery directory. See `proposal.md` and `specs/configurable-receipt-scanner/spec.md` for the behavior contract.

## Goals / Non-Goals

**Goals:**

- Produce a standalone exported NixOS module that downstream users can configure with their own hardware and Paperless endpoint.
- Preserve the repaired ES-50 event, USB-session, output-validation, upload, credential, and recovery behavior.
- Keep the scanner uploader reusable as a packaged command rather than duplicating SANE and Paperless logic in each host module.
- Make generated services and scripts testable without requiring physical hardware or a live Paperless instance.
- Keep host-specific secret managers optional by accepting a token-file source rather than declaring a particular SOPS integration.

**Non-Goals:**

- Supporting arbitrary scanner button protocols or replacing `es2button` with a generic event daemon.
- Managing Paperless users, tags, correspondents, document types, or server-side configuration.
- Providing a GUI, desktop notification workflow, or general-purpose document-management service.
- Reproducing Panoply's existing `hostServices.mediaServices` namespace or migrating its current host configuration in this change.

## Decisions

### Export a generic `services.receiptScanner` module

The module will use a conventional public NixOS service namespace and will be exported from `nixosModules`. Hardware-specific options will describe the ES-50-compatible listener, while the public service name will describe the user-facing capability. Reusing Panoply's host-service namespace was rejected because it makes the module depend on a private repository structure.

### Package the shared uploader separately from orchestration

Add or adapt a small `receipt-scanner` package containing the scan-and-upload command, with the module accepting an override for downstream variants. The worker will invoke that command with explicit device, URL, token-file, output-directory, and receipt-title inputs. Duplicating `curl` and SANE validation inside the module was rejected because it would create divergent upload and recovery behavior.

### Use a token source plus systemd credential loading

The public option will identify a file readable at activation/runtime, while the worker unit maps it to a credential named for the Paperless token. The module will not assume SOPS, agenix, home-manager, or a particular secret path. Embedding token text in Nix-generated shell code or passing the source path directly to the uploader was rejected because it broadens exposure.

### Separate listener, worker, and manual-trigger units

The listener runs with the privileges required to receive scanner events and writes only an atomic pending request. The worker runs as a dedicated system user, stops/restarts the listener through a narrowly allowlisted helper, and owns the single scan/upload path. The manual trigger only writes the same request format and starts the worker. Running scanning in the event callback or providing a second manual implementation was rejected because either approach risks USB-session races and bypasses serialization.

### Make hardware matching and stable identity independent options

USB vendor/product IDs will scope udev access and event activation, while the stable SANE device identifier will be passed to the scanner command. The module will reject transient `libusb:` identities and avoid deriving scanner identity from bus/device numbers. Combining the two into one inferred value was rejected because USB topology is not a stable scan backend identity.

### Keep runtime support explicit and bounded

The module will default to compatible packaged runtime inputs where this repository can provide them, while allowing explicit package/path overrides and an explicit external-runtime escape hatch. Assertions and a runtime check will prevent an enabled listener from silently operating without Epson Scan 2 support. Unbounded listener restarts were rejected because a disconnected or broken scanner can otherwise create a restart loop.

### Test generated behavior rather than hardware availability

Nix evaluation tests will inspect option assertions, generated units, credentials, sandbox paths, udev rules, package references, and service relationships. Shell-level tests will exercise event validation, request coalescing, worker serialization, output validation, upload failure retention, and token non-leakage with fake scanner/Paperless commands. Real hardware acceptance remains an operator task documented for downstream deployments.

## Risks / Trade-offs

- **Epson Scan 2 remains proprietary and hardware-sensitive** → Keep runtime overrides, activation checks, diagnostics, and documented `scanimage -L`/manual acceptance steps.
- **A generic token-file option can point at an unsafe path** → Require readability before scanning, set worker credential ownership/mode defaults, and never expose token contents in generated units or logs.
- **Recovery files contain sensitive receipts** → Create the recovery directory with restrictive ownership and permissions, document cleanup, and avoid automatic deletion on upload failure.
- **Different downstream secret managers have different activation timing** → Treat the token source as a runtime dependency and document that the file must exist and be readable when the worker starts.
- **The shared package may not match every downstream SANE setup** → Expose package/runtime overrides and keep scanner device selection explicit rather than hiding compatibility failures.
- **Changing the existing Panoply module could couple two contracts** → Add the reusable module independently and leave Panoply migration for a follow-up change.

## Migration Plan

1. Add the shared scanner package, generic module, flake export, documentation, and generated tests without changing existing modules.
2. Validate a downstream-style NixOS configuration with a custom Paperless URL, token source, stable scanner identity, and overridden paths/packages.
3. On hardware, verify scanner enumeration, manual trigger, one button scan, Paperless upload, listener recovery, repeated scan, and protected failed-upload recovery.
4. If activation or hardware behavior regresses, remove the new module import or roll back to the prior NixOS generation; existing Panoply host configurations remain available.

## Open Questions

- The exact public option namespace and package location can follow the repository's existing NixOS module naming conventions during implementation without changing the behavioral contract.
