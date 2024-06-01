{
  description = "Apocrypha is a set of packages not available to the mainstream";

  inputs = {
    myPackages.url = "./packages";
    myNixosModules.url = "./nixosModules";
  };

  outputs = { self, myPackages, myNixosModules }: {

    nixosModules = myNixosModules.nixosModules;
    packages = myPackages.packages;
    overlays = myPackages.overlays;
  };
}

