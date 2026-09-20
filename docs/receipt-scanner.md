# Receipt Scanner

`nixosModules.receiptScanner` provides a configurable Epson ES-50-style button
scanner that uploads receipts to a Paperless instance. It is independent of
Panoply host namespaces and does not create or manage a secret-manager entry.

## Example

```nix
{
  imports = [ inputs.apocrypha.nixosModules.receiptScanner ];

  services.receiptScanner = {
    enable = true;
    scannerDevice = "epsonscan2:Epson ES-50:SERIAL:esci2:usb:ES017E:364";
    usbVendorId = "04b8";
    usbProductId = "016c";
    paperlessUrl = "https://paperless.example.test";
    paperlessTokenFile = "/run/secrets/paperless-token";

    # Provide compatible packages for the scanner hardware.
    saneBackendPackage = pkgs.epsonscan2;
    epsonScan2Runtime = pkgs.epsonscan2;
    es2buttonPackage = myEs2buttonPackage;
  };
}
```

The token file must exist and be readable by the NixOS systemd credential
loader when `receipt-scanner-worker.service` starts. The token is then exposed
only through `$CREDENTIALS_DIRECTORY/paperless_token`; it is not placed in
generated command arguments or scripts.

## Hardware Identity

Use `scanimage -L` to find the stable SANE device identifier and set
`scannerDevice` to that value. Do not use `libusb:` bus/device identifiers,
which change when the scanner is reconnected. Set `usbVendorId` and
`usbProductId` from the scanner's USB hardware metadata.

## Operation

Start a manual scan through the same serialized worker used by the physical
button:

```sh
systemctl start receipt-scanner-manual-trigger.service
```

Inspect listener and worker diagnostics with:

```sh
journalctl -u receipt-scanner-listener.service -u receipt-scanner-worker.service
```

Successful temporary files are removed after upload. Failed uploads remain in
`/var/lib/receipt-scanner/recovery` by default and are owned by the dedicated
`receipt-scanner` service account.

## Acceptance

1. Confirm `scanimage -L` reports the configured stable ES-50 identifier.
2. Run the manual trigger and verify one non-empty Paperless receipt.
3. Press the scanner button once and verify one receipt, listener recovery, and
   no concurrent worker.
4. Repeat the button scan after recovery.
5. Temporarily make Paperless unavailable and verify the physical scan remains
   in the recovery directory.
