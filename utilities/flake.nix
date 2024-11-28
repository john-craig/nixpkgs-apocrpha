{
  description = "Apocryphal Utilities";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = { self, nixpkgs }@inputs: {
    overlays.default = final: prev: {
      lib = prev.lib // {
        # new functions
      };
    };
  };
    
}
