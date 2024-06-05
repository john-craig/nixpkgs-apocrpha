{
  description = "Apocryphal Modules";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = { self, nixpkgs }@inputs: {

    nixosModules = {
      selfhosting = {
        imports = [ ./selfhosting ];
      };

      rss-triggers = {
        imports = [ ./rss-triggers ];
      };

      smartctl-ssacli-exporter = {
        imports = [ ./smartctl-ssacli-exporter ];
      };
    };
    
  };
}
