{ pkgs, lib, buildGoModule, fetchFromGitea } :

with buildGoModule rec {
  name = "atlas";

  src = fetchFromGitea {
    domain = "gitea.chiliahedron.wtf";
    owner  = "john-craig";
    repo   = "atlas";
    hash = "sha256-MeFKdjgBrr98Ci7UGQwh2nK0A7awBnxobcBA5BZoL/w=";
    rev = 6d9c329e1c2c3fefe958834cb8e376765f8f25b9;
  };
}