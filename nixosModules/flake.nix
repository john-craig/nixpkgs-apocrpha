{
  description = "Apocryphal Modules";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = { self, nixpkgs }@inputs: {

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
    };

  };
}
