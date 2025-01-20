{ pkgs, lib, fetchFromGitea }:

with pkgs.python311Packages;
buildPythonPackage rec {
  name = "alucard";

  src = fetchFromGitea {
    domain = "gitea.chiliahedron.wtf";
    owner = "john-craig";
    repo = "alucard";
    hash = "sha256-q2c/l0DYlp2698i5zlFESD2PmB6rbSYIJPD2SliPxGE=";
    rev = "087c04136e62c31511235f8687a2eccd9edd3c78";
  };

  format = "pyproject";

  propagatedBuildInputs = [
    # ...
    setuptools
    click
    jinja2
  ];
}
