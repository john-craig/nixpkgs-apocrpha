{ pkgs, lib, fetchFromGitHub, fetchFromGitea, rustPlatform, pkg-config } :
let
  fenix = pkgs.callPackage
    (fetchFromGitHub {
      owner = "nix-community";
      repo = "fenix";
      rev = "07a730bc80e8a4106df5b2341aa5602a240ee112";
      hash = "sha256-CkcCb2hGSL1owuZpjuNB6UQzlyaXgvuRXmjY6jLqjPc";
    })
    { };
in
rustPlatform.buildRustPackage rec {
  name = "totp-port-knockd-rs";

  src = fetchFromGitea {
    domain = "gitea.chiliahedron.wtf";
    owner  = "john-craig";
    repo   = "totp-port-knockd-rs";
    hash = "sha256-YKk9UzG/F/ZY/CWsbQ/EyLMWr2gD89Ut8B2YttNyDp0=";
    rev = "242c8df66f3b90c8fe3fca525693539f706c0138";
  };

  nativeBuildInputs = [
    # Note: to use stable, just replace `default` with `stable`
    fenix.default.toolchain

    # Example Build-time Additional Dependencies
    pkg-config
  ];

  useFetchCargoVendor = true;
  cargoHash = "sha256-KSj5YRy0GIuACKYDR9uh1LSQ4gbOvM7ik0yPbfqZvYg=";
}