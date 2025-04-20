{ pkgs, lib, fetchFromGitea, rustPlatform } :

rustPlatform.buildRustPackage rec {
  pname = "totp-port-knockd-rs";

  src = fetchFromGitea {
    domain = "gitea.chiliahedron.wtf";
    owner  = "john-craig";
    repo   = "totp-port-knockd-rs";
    hash = lib.fakeHash;
    rev = "23d7c4e6a5c98dfac4179437989ab210f1d30fa5";
  };

  cargoSha256 = lib.fakeHash;
}