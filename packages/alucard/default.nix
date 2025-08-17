{ pkgs, lib, fetchFromGitea, extraAttrs }:

with pkgs.python311Packages;
buildPythonPackage rec {
  name = "alucard";

  src = fetchFromGitea {
    domain = "gitea.chiliahedron.wtf";
    owner = "john-craig";
    repo = "alucard";
    hash = "sha256-rUeyAkZtYV6TIN946i9KuFdP+LiQw1cSNDXuKXAdrWs=";
    rev = "516088383044ed6bf140b0233e557fa5a53cfeb2";
  };

  format = "pyproject";

  propagatedBuildInputs = [
    # ...
    setuptools
    click
    jinja2
  ];
}
