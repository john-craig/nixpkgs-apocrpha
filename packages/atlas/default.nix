{ pkgs, lib, buildGoModule, fetchFromGitea } :
buildGoModule rec {
  name = "atlas";

  vendorHash = "sha256-WXQ7jNZMz98bXfjUguQgPyWhiwXk6vkTZIhFjtRI9JE=";

  src = fetchFromGitea {
    domain = "gitea.chiliahedron.wtf";
    owner  = "john-craig";
    repo   = "atlas";
    hash = "sha256-BpRokrbEYC4G4ZoXOKFQFxAI+V6F0Y/uBjGmVkawz+4=";
    rev = "32b85533117190d2c027d9e4d8366256e33aa2d9";
  };
}