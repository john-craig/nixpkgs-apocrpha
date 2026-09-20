# This file describes your repository contents.
# It should return a set of nix derivations
# and optionally the special attributes `lib`, `overlays`,
# `nixosModules`, `homeModules`, `darwinModules` and `flakeModules`.
# It should NOT import <nixpkgs>. Instead, you should take pkgs as an argument.
# Having pkgs default to <nixpkgs> is fine though, and it lets you use short
# commands such as:
#     nix-build -A mypackage

{ pkgs ? import <nixpkgs> { } }:

let
  opencodeAgent = pkgs.callPackage ./pkgs/opencode-agent { };
  unavailable = name: pkgs.writeShellApplication {
    inherit name;
    text = ''
      printf '%s\n' '${name} is unavailable in this package set; use the flake package or provide an override.' >&2
      exit 127
    '';
  };
in

{
  # The `lib`, `overlays`, `nixosModules`, `homeModules`,
  # `darwinModules` and `flakeModules` names are special
  lib = import ./lib { inherit pkgs; }; # functions
  nixosModules = import ./nixos-modules; # NixOS modules
  homeModules = import ./home-modules; # Home Manager modules
  # darwinModules = { }; # nix-darwin modules
  # flakeModules = { }; # flake-parts modules
  overlays = import ./overlays; # nixpkgs overlays

  lshell = pkgs.callPackage ./pkgs/lshell { };
  receipt-scanner = pkgs.callPackage ./pkgs/receipt-scanner { };
  opencode-agent = opencodeAgent;
  openspec-implementor = pkgs.callPackage ./pkgs/openspec-implementor {
    opencodeAgentPackage = opencodeAgent;
    openspecPackage = if builtins.hasAttr "openspec" pkgs then pkgs.openspec else unavailable "openspec";
    opencodePackage = if builtins.hasAttr "opencode" pkgs then pkgs.opencode else unavailable "opencode";
  };
  sceptre = pkgs.callPackage ./pkgs/sceptre { };
}
