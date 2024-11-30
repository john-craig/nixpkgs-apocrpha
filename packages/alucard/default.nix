{ pkgs, lib, fetchFromGitea } :

with pkgs.python311Packages;
buildPythonPackage rec {
  name = "alucard";

  src = fetchFromGitea {
    domain = "gitea.chiliahedron.wtf";
    owner  = "john-craig";
    repo   = "alucard";
    hash = "sha256-CQBNH3iIVoxcbiM+J5rCSeMcfW8esfXxOZUDt1IiYK0=";
    rev = "e5f478a670e4ec3bfcc5768da3725496dc260d0f";
  };

  format = "pyproject";
  
  propagatedBuildInputs = [
    # ...
    setuptools
    click
    jinja2
  ];
}