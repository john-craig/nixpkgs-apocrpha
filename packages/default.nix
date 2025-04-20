{ nixpkgs, flake-utils }: let
  # Path to the directory containing package subdirectories (adjust as necessary)
  packageDir = ./.;

  # Get a list of directories in packageDir
  packageNames = builtins.filter (x: x != "." && x != "..") (nixpkgs.lib.attrsets.mapAttrsToList (name: value: name) (builtins.readDir packageDir));

  callPackageFor = name: system:
    let
      pkgs = import nixpkgs { inherit system; config.allowUnfree = true; };
    in
    pkgs.callPackage ./${name} { };

  createOverlay = name: system: packages: packages.${system}.${name};
in (flake-utils.lib.eachDefaultSystem (system: rec {
    packages = builtins.listToAttrs (map
      (name: {
        name = name;
        value = callPackageFor name system;
      })
      packageNames);

    overlays = final: prev: builtins.listToAttrs (map
      (name: {
        name = name;
        value = createOverlay name system packages;
      })
      packageNames);
  }))