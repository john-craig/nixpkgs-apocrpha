{
  description = "Apocrypha is a set of packages not available to the mainstream";

  inputs = {
    apocryphalPackages.url = "./packages";
    apocryphalNixosModules.url = "./nixosModules";
  };

  outputs = { self, apocryphalPackages, apocryphalNixosModules }: {

    nixosModules = apocryphalNixosModules.nixosModules;
    packages = apocryphalPackages.packages;
    overlays = apocryphalPackages.overlays;
  };
}

