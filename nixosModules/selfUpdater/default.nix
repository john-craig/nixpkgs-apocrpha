{ pkgs, lib, config, ... }: {
  options.selfUpdater = {
    enable = lib.mkEnableOption "Self Updater";

    hostname = lib.mkOption {
      type = lib.types.str;
      default = config.networking.hostName;
      description = "Hostname of the system to build";
    };

    flakeUri = lib.mkOption {
      type = lib.types.str;
      default = "git+https://gitea.chiliahedron.wtf/chiliahedron/homelab-configurations";
      description = "The flake URI to build from";
    };

    extraArgs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Extra arguments to pass to nixos-rebuild";
    };
  };

  config = lib.mkIf config.selfUpdater.enable {
    environment.systemPackages = [
      pkgs.nixos-rebuild
      pkgs.git
    ];

    users.groups."updater" = {};

    users.users."updater" = {
      isSystemUser = true;
      group = "updater";
    };

    security.sudo.extraRules = [
      {
        users = [ "updater" ];
        commands = [ { command = "${pkgs.nixos-rebuild}/bin/nixos-rebuild"; options = [ "NOPASSWD" ]; } ];
      }
    ];

    systemd.services."updateSelf" = let
      hostname = config.selfUpdater.hostname;
      flakeUri = config.selfUpdater.flakeUri;
      extraArgs = lib.strings.concatStringsSep " " config.selfUpdater.extraArgs;

      updateSelfScript = pkgs.writeShellScript "updateSelfScript" ''
        /run/wrappers/bin/sudo nixos-rebuild switch --flake ${flakeUri}#${hostname} ${extraArgs}
      '';
    in {
      enable = true;
      path = [ pkgs.nixos-rebuild pkgs.git ];
      script = "${updateSelfScript}";

      serviceConfig = {
        Type = "oneshot";
        User = "updater";

        PrivateTmp = true;
        WorkingDirectory = /tmp;
      };
    };
  };
}