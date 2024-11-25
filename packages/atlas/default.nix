{ pkgs, lib, buildGoModule, fetchFromGitea } :
buildGoModule rec {
  name = "atlas";

  vendorHash = "sha256-WXQ7jNZMz98bXfjUguQgPyWhiwXk6vkTZIhFjtRI9JE=";

  src = fetchFromGitea {
    domain = "gitea.chiliahedron.wtf";
    owner  = "john-craig";
    repo   = "atlas";
    hash = "sha256-nbVzLd6vQE13+2GVWEB9nxhCziKgWnXAR/4QffsLxiA=";
    rev = "400b98439372d6db994c45b8c245f9e31219bb20";
  };
}