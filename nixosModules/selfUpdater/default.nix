{ pkgs, lib, config, ... }: {
  options.selfUpdater = {
    enable = lib.mkEnableOption "Self Updater";

    flakeUri = lib.mkOption {
      type = lib.types.str;
      default = "git+https://gitea.chiliahedron.wtf/chiliahedron/homelab-configurations";
      description = "The flake URI to build from";
    };

    extraArgs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Extra arguments to pass to nixos-rebuild";
    };
  };

  config = lib.mkIf config.selfUpdater.enable {
    users.groups."updater" = { };

    users.users."updater" = {
      isSystemUser = true;
      group = "updater";
    };

    environment.systemPackages = [
      pkgs.alucard
      pkgs.nixos-rebuild
      pkgs.git
    ];

    environment.etc."alucard/host-config.json".text = ''
      {
        "hosts": [
          {
            "hostname": "DD-WRT",
            "ipAddress": "192.168.1.1",
            "macAddress": "38:94:ED:6D:E0:9A"
          },
          {
            "hostname": "key_server",
            "ipAddress": "192.168.1.3",
            "macAddress": "DC:A6:32:10:4D:EC"
          },
          {
            "hostname": "pxe_server",
            "ipAddress": "192.168.1.5",
            "macAddress": "DC:A6:32:8F:2F:B8"
          },
          {
            "hostname": "homeserver1",
            "ipAddress": "192.168.1.8",
            "macAddress": "80:C1:6E:21:F5:CC"
          },
          {
            "hostname": "laptop-wifi",
            "ipAddress": "192.168.1.64",
            "macAddress": "E4:B3:18:D9:44:3C"
          },
          {
            "hostname": "media_kiosk",
            "ipAddress": "192.168.1.96",
            "macAddress": "68:1D:EF:F0:00:0F"
          }
        ]
      }
    '';

    security.sudo.extraRules = [
      {
        users = [ "updater" ];
        commands = [
          { command = "${pkgs.alucard}/bin/alucard"; options = [ "NOPASSWD" "SETENV" ]; }
          { command = "${pkgs.nixos-rebuild}/bin/nixos-rebuild"; options = [ "NOPASSWD" "SETENV" ]; }
        ];
      }
    ];

    systemd.services."updateSelf" =
      let
        flakeUri = config.selfUpdater.flakeUri;
        extraArgs = lib.strings.concatStringsSep " " config.selfUpdater.extraArgs;
      in
      {
        enable = true;
        path = [ pkgs.alucard pkgs.nixos-rebuild pkgs.git ];
        environment = {
          ALUCARD_HOST_CONFIG = "/etc/alucard/host-config.json";
        };
        serviceConfig = {
          Type = "oneshot";
          User = "updater";

          ExecStart = "/run/wrappers/bin/sudo -E alucard deploy host --flake ${flakeUri} --sudo-path '/run/wrappers/bin/sudo' localhost";

          PrivateTmp = true;
          WorkingDirectory = /tmp;
        };
      };
  };
}
