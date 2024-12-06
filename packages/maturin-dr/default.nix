{ pkgs, lib, buildGoModule, fetchFromGitea } :
buildGoModule rec {
  name = "maturin-dr";

  vendorHash = "sha256-hSDkmKfcpkJxUNKlE8gy41TsdaU7yrp1npusl08L46s=";

  src = fetchFromGitea {
    domain = "gitea.chiliahedron.wtf";
    owner  = "john-craig";
    repo   = "maturin-dr";
    hash = "sha256-Kml96oANb2gbMU4R+xsf+ixAA4LEEA39Kh2NgOrUy40=";
    rev = "fb53499d421fc852df0784534d9cc0cbb2c58cf3";
  };
}