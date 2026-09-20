{ config, lib, pkgs, ... }:

let
  cfg = config.services.receiptScanner;
  scannerPackage = pkgs.callPackage ../pkgs/receipt-scanner { };
  configuredEs2button = if cfg.es2buttonPackage == null then pkgs.writeShellApplication {
    name = "missing-es2button";
    runtimeInputs = [ pkgs.coreutils ];
    text = ''
      echo "services.receiptScanner.es2buttonPackage is not configured" >&2
      exit 1
    '';
  } else cfg.es2buttonPackage;
  listenerService = "receipt-scanner-listener";
  workerService = "receipt-scanner-worker";
  manualService = "receipt-scanner-manual-trigger";
  sudoPath = "/run/wrappers/bin/sudo";

  eventAction = pkgs.writeShellApplication {
    name = "receipt-scanner-event";
    runtimeInputs = [ pkgs.coreutils pkgs.systemd ];
    text = ''
      set -euo pipefail
      request_dir=${lib.escapeShellArg cfg.requestDir}
      log() { echo "receipt-scanner: $*" >&2; }
      valid_state() { [[ "$1" == Yes || "$1" == No ]]; }
      button="''${ES2_BUTTON_NUM:-}"
      present="''${ES2_DOC_PRESENT:-}"
      card="''${ES2_CARD_SCANNING:-}"
      device="''${ES2_DEV:-}"
      vid="''${ES2_DEV_VID:-}"
      pid="''${ES2_DEV_PID:-}"
      device_name="''${device%%:*}"
      device_rest="''${device#*:}"
      device_bus="''${device_rest%%:*}"
      device_number="''${device_rest#*:}"
      [[ "$button" =~ ^[0-9]{1,2}$ ]] || { log "ignored malformed button"; exit 0; }
      valid_state "$present" || { log "ignored malformed document state"; exit 0; }
      valid_state "$card" || { log "ignored malformed card state"; exit 0; }
      [[ "$device" == *:*:* && "$device_name" =~ ^[A-Za-z0-9_.\ -]{1,96}$ && "$device_bus" =~ ^[0-9]{1,3}$ && "$device_number" =~ ^[0-9]{1,3}$ && "$vid" =~ ^[0-9]{1,4}$ && "$pid" =~ ^[0-9]{1,4}$ ]] || {
        log "ignored malformed device data"
        exit 0
      }
      if [[ "$button" != 1 || "$card" == Yes ]]; then
        log "ignored button=$button document=$present card=$card device=$device"
        exit 0
      fi
      install -d -m 0730 -o root -g ${lib.escapeShellArg cfg.serviceGroup} "$request_dir"
      if [[ -e "$request_dir/pending" ]]; then
        log "coalesced receipt event"
      else
        umask 0077
        tmp="$request_dir/.pending.$$"
        printf 'button=1\ndocument_present=%s\ncard_scanning=No\ndevice=%s\n' "$present" "$device" > "$tmp"
        chown root:${lib.escapeShellArg cfg.serviceGroup} "$tmp"
        chmod 0640 "$tmp"
        mv -f "$tmp" "$request_dir/pending"
      fi
      systemctl start --no-block ${workerService}.service
    '';
  };

  listenerControl = pkgs.writeShellApplication {
    name = "receipt-scanner-listener-control";
    runtimeInputs = [ pkgs.systemd ];
    text = ''
      set -euo pipefail
      case "''${1:-}" in
        stop) systemctl stop ${listenerService}.service || true ;;
        start) systemctl start ${listenerService}.service || true ;;
        *) echo "usage: receipt-scanner-listener-control {stop|start}" >&2; exit 2 ;;
      esac
    '';
  };

  runtimeCheck = pkgs.writeShellApplication {
    name = "receipt-scanner-runtime-check";
    runtimeInputs = [ pkgs.coreutils ];
    text = if cfg.epsonScan2Runtime == null then ''
      echo "Epson Scan 2 runtime is externally provisioned; verify it before enabling hardware scanning." >&2
      exit 0
    '' else ''
      test -e ${lib.escapeShellArg cfg.epsonScan2Runtime} || {
        echo "Configured Epson Scan 2 runtime is unavailable: ${lib.escapeShellArg cfg.epsonScan2Runtime}" >&2
        exit 1
      }
    '';
  };

  manualTrigger = pkgs.writeShellApplication {
    name = "receipt-scanner-manual-trigger";
    runtimeInputs = [ pkgs.coreutils pkgs.systemd ];
    text = ''
      set -euo pipefail
      request_dir=${lib.escapeShellArg cfg.requestDir}
      install -d -m 0730 -o root -g ${lib.escapeShellArg cfg.serviceGroup} "$request_dir"
      if [[ ! -e "$request_dir/pending" ]]; then
        umask 0077
        tmp="$request_dir/.manual.$$"
        printf 'button=manual\ndocument_present=Yes\ncard_scanning=No\ndevice=manual\n' > "$tmp"
        chown root:${lib.escapeShellArg cfg.serviceGroup} "$tmp"
        chmod 0640 "$tmp"
        mv -f "$tmp" "$request_dir/pending"
      fi
      systemctl start --no-block ${workerService}.service
    '';
  };

  worker = pkgs.writeShellApplication {
    name = "receipt-scanner-worker";
    runtimeInputs = [ pkgs.bash pkgs.coreutils pkgs.util-linux pkgs.systemd cfg.receiptScannerPackage ];
    text = ''
      set -euo pipefail
      request_dir=${lib.escapeShellArg cfg.requestDir}
      output_dir=${lib.escapeShellArg cfg.outputDir}
      token_file="$CREDENTIALS_DIRECTORY/paperless_token"
      scanner_device=${lib.escapeShellArg cfg.scannerDevice}
      paperless_url=${lib.escapeShellArg cfg.paperlessUrl}
      control=${listenerControl}/bin/receipt-scanner-listener-control
      exec 9>${lib.escapeShellArg cfg.lockFile}
      flock -n 9 || { echo "receipt scan already in progress" >&2; exit 0; }
      if [[ ! -e "$request_dir/pending" ]]; then
        echo "no pending receipt event" >&2
        exit 0
      fi
      rm -f -- "$request_dir/pending"
      stopped=0
      cleanup() {
        rm -rf -- /tmp/receipt-scanner /tmp/receipt-scanner-work
        if (( stopped )); then
          sleep 2
          ${sudoPath} -n "$control" start || echo "failed to restart scanner listener" >&2
        fi
      }
      trap cleanup EXIT
      ${sudoPath} -n "$control" stop
      stopped=1
      sleep 3
      install -d -m 0700 /tmp/receipt-scanner /tmp/receipt-scanner-work
      settings_dir="$HOME/.epsonscan2"
      settings_file="$settings_dir/DefaultSettings.SF2"
      if [[ ! -s "$settings_file" && ${if cfg.epsonScan2Runtime == null then "0" else "1"} == 1 ]]; then
        install -d -m 0700 "$settings_dir"
        (cd "$settings_dir" && HOME="$HOME" ${lib.escapeShellArg cfg.epsonScan2Runtime}/bin/epsonscan2 --create)
        [[ -s "$settings_file" ]] || { echo "Epson Scan 2 did not create $settings_file" >&2; exit 1; }
      fi
      [[ -r "$token_file" ]] || { echo "Paperless credential is unavailable" >&2; exit 1; }
      ${cfg.receiptScannerPackage}/bin/scan-receipt \
        --device "$scanner_device" \
        --paperless-url "$paperless_url" \
        --token-file "$token_file" \
        --output-dir "$output_dir"
    '';
  };
in
{
  options.services.receiptScanner = {
    enable = lib.mkEnableOption "Epson receipt scanning with Paperless uploads";

    scannerDevice = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Stable SANE/Epson scanner identifier; transient libusb identities are not accepted.";
    };

    usbVendorId = lib.mkOption {
      type = lib.types.strMatching "^[0-9A-Fa-f]{1,4}$";
      default = "";
      description = "USB vendor ID used to grant scanner access and start the listener.";
    };

    usbProductId = lib.mkOption {
      type = lib.types.strMatching "^[0-9A-Fa-f]{1,4}$";
      default = "";
      description = "USB product ID used to grant scanner access and start the listener.";
    };

    paperlessUrl = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Base URL of the target Paperless instance.";
    };

    paperlessTokenFile = lib.mkOption {
      type = lib.types.path;
      default = "/run/secrets/paperless-token";
      description = "Runtime file containing the Paperless API token.";
    };

    receiptScannerPackage = lib.mkOption {
      type = lib.types.package;
      default = scannerPackage;
      description = "Package providing scan-document and scan-receipt.";
    };

    saneBackendPackage = lib.mkOption {
      type = lib.types.nullOr lib.types.package;
      default = if pkgs ? epsonscan2 then pkgs.epsonscan2 else null;
      description = "Epson Scan 2/SANE backend package, or null for an externally provisioned backend.";
    };

    es2buttonPackage = lib.mkOption {
      type = lib.types.nullOr lib.types.package;
      default = null;
      description = "Package providing the es2button listener binary.";
    };

    epsonScan2Runtime = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = cfg.saneBackendPackage;
      description = "Epson Scan 2 runtime path used to initialize settings and expose runtime libraries.";
    };

    allowExternallyProvisionedRuntime = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Allow the Epson runtime/backend to be provisioned outside NixOS.";
    };

    outputDir = lib.mkOption { type = lib.types.path; default = "/var/lib/receipt-scanner/recovery"; };
    requestDir = lib.mkOption { type = lib.types.path; default = "/run/receipt-scanner"; };
    lockFile = lib.mkOption { type = lib.types.path; default = "/run/lock/receipt-scanner.lock"; };
    manualUser = lib.mkOption { type = lib.types.nullOr lib.types.str; default = null; description = "Existing user to add to the scanner group."; };
    serviceUser = lib.mkOption { type = lib.types.str; default = "receipt-scanner"; };
    serviceGroup = lib.mkOption { type = lib.types.str; default = "receipt-scanner"; };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      { assertion = cfg.scannerDevice != ""; message = "services.receiptScanner.scannerDevice must be set when receipt scanning is enabled."; }
      { assertion = !(lib.hasInfix "libusb:" cfg.scannerDevice); message = "services.receiptScanner.scannerDevice must be a stable SANE identifier, not a transient libusb identity."; }
      { assertion = cfg.usbVendorId != "" && cfg.usbProductId != ""; message = "services.receiptScanner.usbVendorId and usbProductId must be set when receipt scanning is enabled."; }
      { assertion = cfg.paperlessUrl != ""; message = "services.receiptScanner.paperlessUrl must be set when receipt scanning is enabled."; }
      { assertion = cfg.es2buttonPackage != null; message = "services.receiptScanner.es2buttonPackage must provide the es2button listener binary."; }
      { assertion = cfg.epsonScan2Runtime != null || cfg.allowExternallyProvisionedRuntime; message = "services.receiptScanner needs an Epson Scan 2 runtime or allowExternallyProvisionedRuntime = true."; }
      { assertion = cfg.outputDir != cfg.requestDir; message = "services.receiptScanner.outputDir and requestDir must be separate directories."; }
    ];

    users.groups.${cfg.serviceGroup} = { };
    users.users = lib.recursiveUpdate {
      ${cfg.serviceUser} = {
        isSystemUser = true;
        group = cfg.serviceGroup;
        extraGroups = [ "scanner" ];
        home = "/var/lib/${cfg.serviceUser}";
        createHome = true;
        shell = "${pkgs.shadow}/bin/nologin";
        description = "Least-privilege receipt scanner worker";
      };
    } (lib.optionalAttrs (cfg.manualUser != null) {
      ${cfg.manualUser}.extraGroups = [ "scanner" ];
    });

    hardware.sane = {
      enable = true;
      extraBackends = lib.optional (cfg.saneBackendPackage != null) cfg.saneBackendPackage;
    };

    environment.systemPackages = [ manualTrigger listenerControl ];
    systemd.tmpfiles.rules = [
      "d ${cfg.outputDir} 0750 ${cfg.serviceUser} ${cfg.serviceGroup} - -"
      "d ${cfg.requestDir} 0730 root ${cfg.serviceGroup} - -"
      "f ${cfg.lockFile} 0660 ${cfg.serviceUser} ${cfg.serviceGroup} - -"
    ];
    services.udev.extraRules = ''
      ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="${cfg.usbVendorId}", ATTR{idProduct}=="${cfg.usbProductId}", ENV{libsane_matched}="yes", GROUP="scanner", MODE="0660", TAG+="systemd", ENV{SYSTEMD_WANTS}+="${listenerService}.service"
    '';

    security.sudo-rs.extraRules = [{
      users = [ cfg.serviceUser ];
      commands = [{ command = "${listenerControl}/bin/receipt-scanner-listener-control"; options = [ "NOPASSWD" ]; }];
    }];

    systemd.services.${listenerService} = {
      description = "Epson receipt scanner button listener";
      serviceConfig = {
        Type = "simple";
        User = "root";
        ExecStartPre = "${runtimeCheck}/bin/receipt-scanner-runtime-check";
        ExecStart = "${configuredEs2button}/bin/es2button ${eventAction}/bin/receipt-scanner-event";
        KillSignal = "SIGINT";
        TimeoutStopSec = 15;
        Restart = "on-failure";
        RestartSec = 2;
        NoNewPrivileges = true;
        PrivateTmp = true;
        Environment = [ "SANE_CONFIG_DIR=${config.hardware.sane.configDir}" ];
        BindReadOnlyPaths = lib.optional (cfg.epsonScan2Runtime != null)
          "${cfg.epsonScan2Runtime}/lib/x86_64-linux-gnu/epsonscan2:/usr/lib/x86_64-linux-gnu/epsonscan2";
      };
      unitConfig = { StartLimitIntervalSec = 30; StartLimitBurst = 3; };
    };

    systemd.services.${workerService} = {
      description = "Serialize receipt scans and Paperless uploads";
      serviceConfig = {
        Type = "oneshot";
        StateDirectory = cfg.serviceUser;
        User = cfg.serviceUser;
        Group = cfg.serviceGroup;
        ExecStart = "${worker}/bin/receipt-scanner-worker";
        LoadCredential = [ "paperless_token:${cfg.paperlessTokenFile}" ];
        UMask = "0077";
        NoNewPrivileges = false;
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        Environment = [
          "HOME=/var/lib/${cfg.serviceUser}"
          "SANE_CONFIG_DIR=${config.hardware.sane.configDir}"
          "SANE_DEBUG_DLL=255"
        ];
        BindReadOnlyPaths = lib.optional (cfg.epsonScan2Runtime != null)
          "${cfg.epsonScan2Runtime}/lib/x86_64-linux-gnu/epsonscan2:/usr/lib/x86_64-linux-gnu/epsonscan2";
        ReadWritePaths = [ cfg.outputDir cfg.requestDir cfg.lockFile ];
        TimeoutStartSec = 10 * 60;
      };
    };

    systemd.services.${manualService} = {
      description = "Manual receipt scanner trigger";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${manualTrigger}/bin/receipt-scanner-manual-trigger";
        RefuseManualStart = false;
      };
    };

    environment.etc."receipt-scanner/README".text = ''
      Configure scannerDevice with the stable identifier reported by scanimage -L.
      Do not use transient libusb bus/device numbers.
      Start a manual scan with: systemctl start ${manualService}.service
      Inspect services with: journalctl -u ${listenerService}.service -u ${workerService}.service
      Failed uploads remain in ${cfg.outputDir}.
    '';
  };
}
