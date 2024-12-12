{ config, lib, pkgs, options, ... }:

with lib;

let
  cfg = config.services.prometheus.exporters.smartctl-ssacli;
  servUser = "smartctl-ssacli-exporter";
  servGroup = "smartctl-ssacli-exporter";
in
{
  options.services.prometheus.exporters.smartctl-ssacli = {
    enable = mkEnableOption (lib.mdDoc "HP Smart Array S.M.A.R.T. Exporter");

    port = mkOption {
      type = types.port;
      default = 9633;
      description = lib.mdDoc ''
        Port to listen on.
      '';
    };

    listenAddress = mkOption {
      type = types.str;
      default = "0.0.0.0";
      description = lib.mdDoc ''
        Address to listen on.
      '';
    };

    metricsPath = mkOption {
      type = types.str;
      default = "/metrics";
      description = lib.mdDoc ''
        URL path for surfacing collected metrics
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = nixpkgs.config.allowUnfree;
        message = "HP Smart Array S.M.A.R.T. Exporter requires unfree packages";
      }
      {
        assertion = hardware.raid.HPSmartArray.enable;
        message = "HP Smart Array S.M.A.R.T. Exporter requires hardware support for HP Smart Array";
      }
    ];

    environment.systemPackages = with pkgs; [
      smartctl-ssacli-exporter
      hpssacli
      smartmontools
      lsscsi
    ];

    users.groups = {
      "${servGroup}" = { };
    };

    users.users."${servUser}" = {
      description = "Prometheus HP Smart Array S.M.A.R.T. exporter service user";
      isSystemUser = true;
      group = "${servGroup}";
    };

    security.sudo.extraRules = [
      {
        users = [ "${servUser}" ];
        commands = [
          { command = "${pkgs.smartmontools}/bin/smartctl"; options = [ "NOPASSWD" ]; }
          { command = "${pkgs.hpssacli}/bin/hpssacli"; options = [ "NOPASSWD" ]; }
        ];
      }
    ];

    systemd.services."prometheus-smartctl-ssacli-exporter" = {
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      serviceConfig.User = "${servUser}";
      serviceConfig.Group = "${servGroup}";

      serviceConfig.ExecStart = ''
        ${pkgs.smartctl-ssacli-exporter}/bin/smartctl_ssacli_exporter \
          -web.listen-address ${cfg.listenAddress}:${toString cfg.port} \
          -web.telemetry-path ${cfg.metricsPath} \
          -smartctl.path ${pkgs.smartmontools}/bin/smartctl -ssacli.path ${pkgs.hpssacli}/bin/hpssacli \
          -lsscsi.path ${pkgs.lsscsi}/bin/lsscsi -sudo.path /run/wrappers/bin/sudo
      '';

      # Needed for `hpssacli` and `smartctl` to execute correctly
      serviceConfig.PrivateDevices = false;
      serviceConfig.ProtectKernelModules = false;
      serviceConfig.NoNewPrivileges = false;

      serviceConfig.Restart = "always";
      serviceConfig.PrivateTmp = true;
      serviceConfig.WorkingDirectory = /tmp;

      # Hardening
      serviceConfig.LockPersonality = true;
      serviceConfig.MemoryDenyWriteExecute = true;
      serviceConfig.ProtectClock = true;
      serviceConfig.ProtectControlGroups = true;
      serviceConfig.ProtectHome = true;
      serviceConfig.ProtectHostname = true;
      serviceConfig.ProtectKernelLogs = true;
      serviceConfig.ProtectKernelTunables = true;
      serviceConfig.ProtectSystem = "strict";
      serviceConfig.RemoveIPC = true;
      serviceConfig.RestrictAddressFamilies = [ "AF_INET" "AF_INET6" ];
      serviceConfig.RestrictNamespaces = true;
      serviceConfig.RestrictRealtime = true;
      serviceConfig.RestrictSUIDSGID = true;
      serviceConfig.SystemCallArchitectures = "native";
      serviceConfig.UMask = "0077";
    };
  };
}
