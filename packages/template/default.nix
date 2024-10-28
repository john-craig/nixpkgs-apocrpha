{ pkgs, lib, fetchFromGitea } :

with pkgs.python311Packages;
buildPythonPackage rec {
  name = "example";

  src = fetchFromGitea {
    domain = "gitea.chiliahedron.wtf";
    owner  = "";
    repo   = "";
    hash = lib.fakeHash;
    rev = "";
  };

  format = "pyproject";
  
  propagatedBuildInputs = [
    # ...
    setuptools
  ];
}