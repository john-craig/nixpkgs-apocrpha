{ pkgs, lib, fetchFromGitea, extraAttrs }:

with pkgs.python311Packages;
buildPythonPackage {
  pname = "pytimefliplib";
  src = fetchFromGitea {
    domain = "gitea.chiliahedron.wtf";
    owner = "john-craig";
    repo = "pytimefliplib";
    hash = "sha256-iN/fHidqphyhXDYNMmWONuTPcW8MeErI59kdLC2imPE=";
    rev = "e111b91e2b2fc17f6b3190232c229e7264b354ab";
  };

  propagatedBuildInputs = [
    setuptools
    bleak
  ];

  version = "1.0.0";

  format = "pyproject";
};
