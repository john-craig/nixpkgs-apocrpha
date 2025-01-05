{ pkgs, lib, fetchFromGitea }:

with pkgs.python311Packages;
buildPythonPackage rec {
  name = "alucard";

  src = fetchFromGitea {
    domain = "gitea.chiliahedron.wtf";
    owner = "john-craig";
    repo = "alucard";
    hash = "sha256-rsJ1KeSAHRwkyk/NyNm4KC2Mb4fKjR7rN03jeD5b2bk=";
    rev = "9437413f6b5af3b45dbf52058476819c1d038502";
  };

  format = "pyproject";

  propagatedBuildInputs = [
    # ...
    setuptools
    click
    jinja2
  ];
}
