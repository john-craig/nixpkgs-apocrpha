## 1. Shared Scanner Package

- [x] 1.1 Add the reusable `receipt-scanner` package and carry over the `scan-document`/`scan-receipt` interface, configurable device/URL/token/output arguments, receipt title generation, and Paperless endpoint normalization; verify the package builds and exposes both commands without embedding a host URL or credential.
- [x] 1.2 Preserve non-empty JPEG validation, scanner diagnostics, successful-upload cleanup, and failed-upload recovery behavior in the packaged command; verify shell tests reject empty/non-JPEG output before a fake Paperless request and retain files when the request fails.
- [x] 1.3 Add package-level dependency declarations for SANE, curl, file/coreutils, and shell utilities without relying on mutable host paths; verify the generated scripts resolve all runtime commands from declared inputs.

## 2. Configurable NixOS Module

- [x] 2.1 Add the standalone exported NixOS module with a public receipt-scanner option namespace and enablement guard; verify a downstream-style module evaluation succeeds without Panoply namespaces or SOPS declarations.
- [x] 2.2 Define documented options for stable scanner device, USB vendor/product IDs, scanner/backend and `es2button` packages or runtime paths, Paperless URL/token source, output/request/lock paths, service account names/groups, and manual trigger behavior; verify defaults contain no personal host, URL, username, or secret assumptions.
- [x] 2.3 Add assertions rejecting missing stable device identity, transient `libusb:` identities, invalid USB identifiers, missing runtime inputs, and unsafe enabled configurations; verify each invalid fixture fails with an actionable message.
- [x] 2.4 Generate the scanner-group system user/group, tmpfiles directories, udev match, backend configuration, and optional manual-user access from the configured values; verify generated ownership, permissions, and USB rules match the downstream configuration.

## 3. Event and Worker Lifecycle

- [x] 3.1 Implement the root listener event action with field validation, button/card filtering, diagnostic document-present handling, atomic pending-file creation, duplicate coalescing, and prompt worker queuing; verify valid, malformed, unrelated, and overlapping event fixtures.
- [x] 3.2 Implement the dedicated worker around the packaged scanner command with a lock, protected systemd credential, configured Paperless URL/device/output paths, and least-privilege service settings; verify generated unit text contains no token value or direct secret argument.
- [x] 3.3 Implement listener stop/wait/restart orchestration, Epson settings initialization, private temporary transfer directories, and bounded listener restart policy; verify a fake listener/scan fixture proves restart occurs after scanner exit for success and failure paths.
- [x] 3.4 Add the narrow listener-control helper and elevation rule, keeping all other worker elevation unavailable; verify generated sudo-rs configuration allows only the expected helper commands for the worker account.
- [x] 3.5 Add the manual-trigger unit using the same pending request and worker path; verify manual invocation cannot launch a concurrent worker and does not bypass credential or output validation.

## 4. Generated Configuration and Behavioral Tests

- [x] 4.1 Add a NixOS module evaluation test covering custom Paperless URL, token source, scanner identity, USB IDs, storage paths, package overrides, and optional manual access; verify generated service names and command references use those values.
- [x] 4.2 Add generated-unit assertions for systemd credentials, service users/groups, `ProtectSystem`, private temporary storage, writable-path boundaries, timeout, environment/library paths, listener kill/restart behavior, and udev activation; verify no broad writable or secret-exposing permissions appear.
- [x] 4.3 Add shell fixtures for event validation, request coalescing, worker serialization, missing credential failure-before-scan, empty-output rejection, successful upload cleanup, upload-failure retention, and listener recovery; verify the focused test suite passes.
- [x] 4.4 Add negative checks for credentials and hard-coded Panoply values across generated files and source; verify no token contents, personal paths, private Paperless hostname, or unintended host-service namespace is present.

## 5. Flake Export and Documentation

- [x] 5.1 Export the module through `nixosModules` and expose the reusable package through the repository's package/overlay surface as appropriate; verify a downstream flake can import the module and evaluate a minimal host configuration.
- [x] 5.2 Document module options, token-file timing and ownership expectations, scanner identity discovery, package/runtime overrides, manual trigger, service journals, recovery handling, and hardware acceptance steps; verify every documented command and unit name matches generated configuration.
- [x] 5.3 Add focused flake checks for package build, module evaluation, generated configuration, and behavioral fixtures; verify `nix flake check` passes without changing existing module behavior.

## 6. Final Verification

- [x] 6.1 Run formatting, focused package/module tests, OpenSpec validation, and full flake checks; verify all required checks pass and the change remains isolated to the approved files.
- [x] 6.2 Inspect the final generated units, scripts, package closure, and diff for accidental credentials, hard-coded downstream values, unrestricted elevation, broad filesystem access, or concurrent scan paths; verify the implementation satisfies every configurable-receipt-scanner requirement.
- [x] 6.3 Record the hardware acceptance procedure for a real ES-50 and Paperless instance, including enumeration, manual scan, button scan, listener recovery, repeated scan, and failed-upload recovery; verify the procedure is executable by a downstream operator.
