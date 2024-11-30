{ pkgs, lib, fetchFromGitea } :

with pkgs.python311Packages;
buildPythonPackage rec {
  name = "alucard";

  src = fetchFromGitea {
    domain = "gitea.chiliahedron.wtf";
    owner  = "john-craig";
    repo   = "alucard";
    hash = "sha256-w4G1mqBuGh2NqDK2uEh9sr01CEM3INjzr68tJPiqn2I=";
    rev = "a5bd5714865619f7cac89637dfb844e17a2f2670";
  };

  format = "pyproject";
  
  propagatedBuildInputs = [
    # ...
    setuptools
    click
    jinja2
  ];
}