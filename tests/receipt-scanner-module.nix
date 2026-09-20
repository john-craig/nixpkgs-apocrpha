{ pkgs ? import <nixpkgs> { } }:
let
  eval = modules: import "${pkgs.path}/nixos/lib/eval-config.nix" {
    system = "x86_64-linux";
    inherit modules;
  };
  fakeRuntime = pkgs.runCommand "fake-epson-runtime" { } ''
    mkdir -p "$out/bin"
    touch "$out/bin/epsonscan2"
  '';
  fakeEs2button = pkgs.runCommand "fake-es2button" { } ''
    mkdir -p "$out/bin"
    touch "$out/bin/es2button"
  '';
  base = {
    system.stateVersion = "24.11";
    services.receiptScanner = {
      enable = true;
      scannerDevice = "epsonscan2:Epson ES-50:SERIAL:esci2:usb:ES017E:364";
      usbVendorId = "04b8";
      usbProductId = "016c";
      paperlessUrl = "https://paperless.example.test";
      paperlessTokenFile = "/run/secrets/paperless-token";
      saneBackendPackage = fakeRuntime;
      epsonScan2Runtime = fakeRuntime;
      es2buttonPackage = fakeEs2button;
      manualUser = "scanner-operator";
    };
  };
  enabled = eval [ ../nixos-modules/receipt-scanner.nix base ];
  disabled = eval [ ../nixos-modules/receipt-scanner.nix ];
  invalid = eval [
    ../nixos-modules/receipt-scanner.nix
    { services.receiptScanner.enable = true; }
  ];
  invalidMessages = map (assertion: assertion.message) invalid.config.assertions;
in
pkgs.runCommand "apocrypha-receipt-scanner-module-evaluation" { }
  (assert !disabled.config.services.receiptScanner.enable;
   assert enabled.config.hardware.sane.enable;
   assert enabled.config.services.receiptScanner.paperlessUrl == "https://paperless.example.test";
   assert enabled.config.systemd.services.receipt-scanner-worker.serviceConfig.User == "receipt-scanner";
   assert enabled.config.systemd.services.receipt-scanner-worker.serviceConfig.LoadCredential == [ "paperless_token:/run/secrets/paperless-token" ];
   assert enabled.config.systemd.services.receipt-scanner-worker.serviceConfig.ProtectSystem == "strict";
   assert enabled.config.systemd.services.receipt-scanner-listener.serviceConfig.KillSignal == "SIGINT";
   assert builtins.elem "services.receiptScanner.scannerDevice must be set when receipt scanning is enabled." invalidMessages;
   assert builtins.elem "services.receiptScanner.es2buttonPackage must provide the es2button listener binary." invalidMessages;
   assert builtins.elem "services.receiptScanner.paperlessUrl must be set when receipt scanning is enabled." invalidMessages;
   ''touch $out'')
