{
  description = "Apocrypha is a set of packages not available to the mainstream";

  inputs = {
    # nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    nixpkgs.url = "github:nixos/nixpkgs?ref=release-25.05";

    flake-utils = {
      url = "github:numtide/flake-utils";
    };
  };

  outputs = { self, nixpkgs, flake-utils }:
    let
      apocryphalNixosModules = import ./nixosModules;
      apocryphalPackages = import ./packages { inherit nixpkgs flake-utils; };
      apocryphalUtilities = import ./utilities;
    in
    {
      nixosModules = apocryphalNixosModules.nixosModules;
      packages = apocryphalPackages.packages;
      overlays = apocryphalPackages.overlays;
      utilities = apocryphalUtilities.utilities;
    };
}

