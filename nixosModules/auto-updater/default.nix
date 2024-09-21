{ pkgs, lib, config, ... }: {
  options.services.auto-updater = {
    enable = lib.mkEnableOption "Automatic Configuration Updates";
  };

  config = lib.mkIf config.services.auto-updater.enable {
    environment.systemPackages = with pkgs; [
      git
      gnupg
      pinentry
      self-updater
      nixos-rebuild
    ];

    # Required for GnuPG
    programs.gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };

    services.rss-triggers = let
      updater-exec = pkgs.writeShellScript "updater-exec" ''
        # Set commit URL
        COMMIT_URL=$1
        REPO_URL="https://gitea.chiliahedron.wtf/chiliahedron/homelab-configurations"

        if [[ $COMMIT_URL == $REPO_URL* ]]; then
          :
        else
          echo "Invalid commit URL: $COMMIT_URL"
          exit 0
        fi

        # Add some utilities to the path
        export PATH=$PATH:${pkgs.git}/bin:${pkgs.gnupg}/bin:${pkgs.nettools}/bin:${pkgs.nixos-rebuild}/bin:${pkgs.nix}:/bin

        # Extract commit hash
        COMMIT_HASH=$(echo $COMMIT_URL | cut -d '/' -f 7)    

        # Set GnuPG directory
        export GNUPGHOME=/sec/gnupg/$HOSTNAME/service/.gnupg

        # Invoke updater
        ${pkgs.self-updater}/bin/self-updater --commit $COMMIT_HASH $REPO_URL
      '';
    in {
      enable = true;
      triggers = [
        {
          name = "homelab-configuration";
          feed = "https://gitea.chiliahedron.wtf/chiliahedron/homelab-configurations.rss";
          age  = "1h";
          fields = [ "link" ];
          exec = "${updater-exec}";
          calender = "hourly";
        }
      ];
    };

  };
}