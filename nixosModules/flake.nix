{
  description = "Apocryphal Modules";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    services-library.url = "git+https://gitea.chiliahedron.wtf/chiliahedron/services-library";
  };

  outputs = { self, services-library, nixpkgs }@inputs: {

    nixosModules = {
      selfhosting = (import ./selfhosting inputs);

      rss-triggers = {
        imports = [ ./rss-triggers ];
      };

      smartctl-ssacli-exporter = {
        imports = [ ./smartctl-ssacli-exporter ];
      };
    };
    
  };
}
