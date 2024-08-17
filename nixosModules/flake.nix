{
  description = "Apocryphal Modules";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = { self, services-library, nixpkgs }@inputs: {

    nixosModules = {

      rss-triggers = {
        imports = [ ./rss-triggers ];
      };

      smartctl-ssacli-exporter = {
        imports = [ ./smartctl-ssacli-exporter ];
      };
    };
    
  };
}
