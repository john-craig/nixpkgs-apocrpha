{
  description = "Apocrypha is a set of packages not available to the mainstream";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    apocryphalPackages.url = "./packages";
    apocryphalPackages.inputs.nixpkgs.follows = "nixpkgs";

    apocryphalUtilities.url = "./utilities";
    apocryphalUtilities.inputs.nixpkgs.follows = "nixpkgs";

    apocryphalNixosModules.url = "./nixosModules";
  };

  outputs = { self, nixpkgs, apocryphalPackages, apocryphalUtilities, apocryphalNixosModules }: {

    nixosModules = apocryphalNixosModules.nixosModules;
    packages = apocryphalPackages.packages;
    overlays = apocryphalPackages.overlays // apocryphalUtilities.overlays;
  };
}

