{ pkgs, lib, buildGoModule, fetchFromGitea } :

with buildGoModule rec {
  name = "atlas";

  src = fetchFromGitea {
    domain = "gitea.chiliahedron.wtf";
    owner  = "john-craig";
    repo   = "atlas";
    hash = "sha256-wzE+NcyeNSpe+SnyrFmZvNn80BgPWAvSHTVuQttnqwQ=";
    rev = "dc6f8521386f2892aee6fa813b6d49d84372d0d5";
  };
}