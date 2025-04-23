{ pkgs, lib, fetchFromGitea }:

with pkgs.python311Packages;
buildPythonPackage rec {
  name = "alucard";

  src = fetchFromGitea {
    domain = "gitea.chiliahedron.wtf";
    owner = "john-craig";
    repo = "alucard";
    hash = "sha256-2U5U+STatarnzIe3ey46hORhF1pzA2qsIHpEVuZ/oAs=";
    rev = "cfa54755e0ec39a83201ea6e3205af77a3e72f14";
  };

  format = "pyproject";

  propagatedBuildInputs = [
    # ...
    setuptools
    click
    jinja2
  ];
}
