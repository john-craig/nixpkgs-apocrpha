{ pkgs, lib, config, ... }: {
  options.services.rss-triggers = {
    enable = lib.mkEnableOption "RSS Feed Triggers";

    triggers = lib.mkOption {
      type = lib.types.listOf lib.types.attrset;

      # {
      #     name = "my-trigger";
      #     feed = "myfeed";
      #     age = "5h" or "last";
      #     fields = [ "myfield1" "myfield2" ];
      #     exec = "myexecutable";
      #     calender = "mycal";
      # }
    };
  };

  config = lib.mkIf config.services.rss-triggers.enable = {
    environment.systemPackages = [
      pkgs.rss-feed-trigger
    ];

    systemd.services = (builtins.listToAttrs 
      builtins.map (triggerDef: { 
        name = "rss-trigger-${triggerDef.name}";
        value = {
          enable = true;

          script = ''
            ${pkgs.rss-feed-trigger} ${triggerDef.feed} ${triggerDef.age} ${triggerDef.exec} -f ${lib.strings.concatStringsSep " " triggerDef.fields}
          '';

          serviceConfig = {
            Type = "oneshot";
            User = "root";
          };
        };
      }
    ) config.services.rss-triggers.triggers);

    systemd.timers = (builtins.listToAttrs 
      builtins.map (triggerDef: { 
        name = "rss-trigger-${triggerDef.name}";
        value = {
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnCalendar = ${triggerDef.calender};
            Unit = "rss-trigger-${triggerDef.name}";
          };
        };
      }
    ) config.services.rss-triggers.triggers);
  };
}