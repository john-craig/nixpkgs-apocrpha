{ pkgs, lib, fetchFromGitHub, extraAttrs }:

let
  # Create a Zig 0.14 environment with zig2nix
  zig2nix = extraAttrs.zig2nix;
  system = extraAttrs.system;

  env = zig2nix.outputs.zig-env.${system} {
    zig = zig2nix.outputs.packages.${system}.zig-0_14_0;
  };

  pkgs' = env.pkgs;
in
env.package rec {
  pname = "wprintidle";
  version = "unstable";

  src = pkgs'.fetchgit {
    url = "https://codeberg.org/andyscott/wprintidle.git";
    rev = "43a5799148dc0ea033e4370986053cdc497bd8aa";  # or specify a commit hash
    hash = "sha256-xzz44FYt4nysJDhl+/GpeuLSI2KVxt7He7eUi32ZPhs=";
  };

  nativeBuildInputs = with pkgs'; [
    pkg-config
    scdoc
    wayland-protocols
  ];

  buildInputs = with pkgs'; [
    wayland
  ];

  # Wrap runtime libs so zig binaries run correctly
  zigWrapperLibs = buildInputs;

  # Optional: lock file if you generate one with `zig2nix lock`
  # zigBuildZonLock = ./build.zig.zon2json-lock;

  zigBuildFlags = [ "-Doptimize=ReleaseSafe" ];
}