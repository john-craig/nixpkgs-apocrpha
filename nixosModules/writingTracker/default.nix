{ pkgs, lib, config, ... }: {
  options.writingTracker = {
    enable = lib.mkEnableOption "Writing Tracker";

    tokenPath = lib.mkOption {
      type = lib.types.str;
      description = "Path to the NocoDB API token.";
    };

    documentPath = lib.mkOption {
      type = lib.types.str;
      description = "Path to the documents to count.";
    };
  };

  config = lib.mkIf config.writingTracker.enable {
    environment.systemPackages = with pkgs; [
      nocodb_writing_tracker
    ];

    # System Daemon Timers
    systemd.timers."track-writing" = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "*-*-* 00:00:00";
        Unit = "track-writing.service";
      };
    };

    systemd.services."track-writing" = {
      enable = true;
      script = ''
        # Perform the archive
        TOKEN=$(cat ${config.writingTracker.tokenPath})
        ${pkgs.nocodb_writing_tracker}/bin/nocodb-writing-tracker --path ${config.writingTracker.documentPath} --token $TOKEN
      '';
      serviceConfig = {
        Type = "oneshot";
        User = "service";
      };
    };

  };
}
