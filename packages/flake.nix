{
  description = "Apocryphal Packages";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, utils }: 
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; config.allowUnfree = true; };
        # Path to the directory containing package subdirectories (adjust as necessary)
        packageDir = ./.;

        # Get a list of directories in packageDir
        packageNames = builtins.filter (x: x != "." && x != "..") (nixpkgs.lib.attrsets.mapAttrsToList (name: value: name) (builtins.readDir packageDir));

        
        callPackageFor = name: pkgs.callPackage ./${name} {};
        createOverlay = name: self.packages."x86_64-linux".${name};
    in {
      packages."x86_64-linux" = builtins.listToAttrs (map (name: {
        name = name;
        value = callPackageFor name;
      }) packageNames);

      overlays.default = final: prev: builtins.listToAttrs (map (name: {
        name = name;
        value = createOverlay name;
      }) packageNames);
  };
}
