{ pkgs, lib, fetchFromGitea } :

with pkgs.python311Packages;
buildPythonPackage rec {
  name = "alucard";

  src = fetchFromGitea {
    domain = "gitea.chiliahedron.wtf";
    owner  = "john-craig";
    repo   = "alucard";
    hash = "sha256-KmKBrQPfSAaex8BnanokD0ii5DuYeGfazLtODeKRQJs=";
    rev = "1018774ea9a162e3c3dd15f9ed62c06cf7238866";
  };

  format = "pyproject";
  
  propagatedBuildInputs = [
    # ...
    setuptools
    click
    jinja2
  ];
}