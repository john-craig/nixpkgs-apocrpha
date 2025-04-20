{
  nixosModules = {

    rss-triggers = {
      imports = [ ./rss-triggers ];
    };

    smartctl-ssacli-exporter = {
      imports = [ ./smartctl-ssacli-exporter ];
    };

    auto-updater = {
      imports = [ ./auto-updater ];
    };

    selfUpdater = {
      imports = [ ./selfUpdater ];
    };

    notifiedServices = {
      imports = [ ./notifiedServices ];
    };

    timeTracker = {
      imports = [ ./timeTracker ];
    };

    writingTracker = {
      imports = [ ./writingTracker ];
    };
  };
}
