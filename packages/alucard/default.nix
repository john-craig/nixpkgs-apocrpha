{ pkgs, lib, fetchFromGitea } :

with pkgs.python311Packages;
buildPythonPackage rec {
  name = "alucard";

  src = fetchFromGitea {
    domain = "gitea.chiliahedron.wtf";
    owner  = "john-craig";
    repo   = "alucard";
    hash = "sha256-zxxvc0JB+6GjNqpAgvlIRI9SmGGIat4pTWzmaZlhlLk=";
    rev = "9835a8de8355ddcc3e151774e3ccd5ba95c9a591";
  };

  format = "pyproject";
  
  propagatedBuildInputs = [
    # ...
    setuptools
    click
    jinja2
  ];
}