# configurable-receipt-scanner Specification

## Purpose

Provide downstream NixOS users with a configurable, secure Epson ES-50 receipt-scanning service that captures button events, uploads valid scans to their Paperless instance, and preserves failed uploads for recovery.

## Requirements

### Requirement: Module configuration is independent of Panoply

The module SHALL be consumable without Panoply-specific option namespaces, user names, secret declarations, filesystem paths, or hard-coded Paperless endpoints.

#### Scenario: Downstream host enables the module
- **WHEN** a downstream NixOS configuration imports the exported module and enables it with its own scanner and Paperless options
- **THEN** evaluation SHALL succeed without defining Panoply host-service options or SOPS secrets
- **AND** generated services SHALL use the downstream values

#### Scenario: Required hardware identity is missing
- **WHEN** the module is enabled without a stable scanner device identity or valid USB match required by the selected listener path
- **THEN** evaluation or activation SHALL fail with an actionable assertion
- **AND** no listener SHALL accept scanner events

### Requirement: Module exposes configurable scanner and upload targets

The module SHALL expose options for enablement, stable SANE scanner device, USB vendor and product identifiers, scanner/backend and button-listener packages or runtime paths, Paperless base URL, protected token-file source, recovery/output directory, request directory, lock path, service account controls, and manual trigger access. Defaults SHALL be safe and SHALL NOT identify a specific user's host or Paperless instance.

#### Scenario: User selects a non-default Paperless instance
- **WHEN** the user sets a Paperless URL and token-file source
- **THEN** the worker SHALL upload to the normalized `/api/documents/post_document/` endpoint of that URL
- **AND** the generated configuration SHALL contain neither the token contents nor a Panoply-specific endpoint

#### Scenario: User overrides scanner runtime components
- **WHEN** the user supplies compatible SANE/Epson runtime and `es2button` packages or paths
- **THEN** the listener and worker SHALL use those configured components
- **AND** module evaluation SHALL not require an unrelated host-wide installation

### Requirement: Scanner events are validated and coalesced

The listener SHALL accept only a valid receipt event for button 1 with no card scan, validate event fields before using them, record document-present state only diagnostically, atomically create at most one pending request, and return without running the upload in the listener callback.

#### Scenario: Valid button event is queued
- **WHEN** the scanner reports button 1, valid device metadata, and no card scan
- **THEN** the listener SHALL create one protected pending request and queue the worker
- **AND** the callback SHALL return promptly

#### Scenario: Invalid or unrelated event is ignored
- **WHEN** the listener receives malformed fields, another button, or an event indicating card scanning
- **THEN** it SHALL ignore the event without creating a pending request or starting a worker

#### Scenario: Events overlap
- **WHEN** another valid event arrives while a request is pending or a scan is running
- **THEN** the system SHALL coalesce or serialize it
- **AND** it SHALL never start concurrent scans against the configured device

### Requirement: Receipt scans are uploaded only after output validation

The worker SHALL run under a dedicated least-privilege service account, acquire a scan through the configured SANE device, reject empty or non-JPEG output before upload, upload a titled receipt using the protected Paperless token, remove successfully uploaded temporary output, and retain failed physical scans in the protected recovery directory.

#### Scenario: Valid scan uploads successfully
- **WHEN** a pending request exists and the scanner produces a non-empty JPEG
- **THEN** the worker SHALL upload it as a receipt document to Paperless
- **AND** it SHALL remove the temporary document after successful upload

#### Scenario: Empty or invalid scan is produced
- **WHEN** scanning produces no file, an empty file, or a non-JPEG file
- **THEN** the worker SHALL fail without making a Paperless upload
- **AND** diagnostics SHALL identify the output-validation failure without exposing credentials

#### Scenario: Paperless upload fails
- **WHEN** a valid physical scan is produced but Paperless is unavailable or rejects the request
- **THEN** the worker SHALL return failure
- **AND** the scan SHALL remain in the protected recovery directory

### Requirement: Listener lifecycle and credentials are protected

The worker SHALL stop the button listener before opening the scanner, wait for the listener's scanner session to close, restart it only after the scan process exits, and use only a narrowly scoped elevation rule for listener control. The Paperless token SHALL be supplied through a protected systemd credential or equivalent file mapping and SHALL NOT appear in service arguments, generated scripts, or logs.

#### Scenario: Listener is recovered after a scan
- **WHEN** the worker stops the listener and the scan process exits successfully or unsuccessfully
- **THEN** cleanup SHALL attempt to restart the listener after the scanner session has been released
- **AND** repeated scans SHALL remain possible when recovery succeeds

#### Scenario: Credential is unavailable
- **WHEN** the worker starts without a readable configured token source
- **THEN** it SHALL fail before scanning or uploading
- **AND** the token value SHALL not be printed or embedded in generated configuration

#### Scenario: Listener restart loops are bounded
- **WHEN** the listener repeatedly fails because the scanner or runtime is unavailable
- **THEN** systemd SHALL apply a bounded restart policy
- **AND** the failure SHALL be observable through service status and journal diagnostics

### Requirement: Operators can trigger and recover scans

The module SHALL provide a documented manual trigger using the same serialized worker as hardware events, expose service names and recovery location, and provide enough status and journal guidance to diagnose enumeration, runtime, upload, and listener-recovery failures.

#### Scenario: Manual trigger is used
- **WHEN** an operator starts the generated manual-trigger service
- **THEN** it SHALL enqueue one receipt request and invoke the same worker path without requiring a physical button press
- **AND** it SHALL not bypass serialization or credential protection

#### Scenario: Operator handles a failed upload
- **WHEN** an upload fails after a valid scan
- **THEN** the documented recovery directory SHALL contain the scan with ownership and permissions restricted to the worker account
- **AND** the operator SHALL be able to locate the relevant worker journal entries
