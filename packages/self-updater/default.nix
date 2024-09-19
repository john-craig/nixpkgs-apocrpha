
{ pkgs, lib, fetchFromGitea } :

with pkgs.python311Packages;
buildPythonPackage rec {
  name = "self-updater";

  src = fetchFromGitea {
    domain = "gitea.chiliahedron.wtf";
    owner  = "john-craig";
    repo   = "nixos-self-updater";
    hash = "sha256-NXVXowpLJECweATBJH/QFKFZc0JkdAlyp9GdhpN5LhA=";
    rev = "7c6e2137220bf05db8427c3b430c63e40bab4746";
  };

  format = "pyproject";
  
  propagatedBuildInputs = [
    setuptools
  ];
}