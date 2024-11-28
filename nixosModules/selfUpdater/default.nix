{ pkgs, lib, config, ... }: {
  options.selfUpdater = {
    enable = lib.mkEnableOption "Self Updater";
  };

  config = lib.mkIf config.selfUpdater.enable {
    environment.systemPackages = [
      pkgs.nixos-rebuild
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
      updateSelfScript = pkgs.writeShellScript "updateSelfScript" ''
        HOMELAB_CONFIGURATIONS=https://gitea.chiliahedron.wtf/chiliahedron/homelab-configurations
        TARGET_HOST=$(hostname)

        sudo nixos-rebuild switch --flake "$HOMELAB_CONFIGURATIONS#$TARGET_HOST"
      '';
    in {
      enable = true;
      script = "${updateSelfScript}";
      path = [ pkgs.curl pkgs.nixos-rebuild ];

      serviceConfig = {
        Type = "oneshot";
        User = "updater";
      };
    };
  };
}