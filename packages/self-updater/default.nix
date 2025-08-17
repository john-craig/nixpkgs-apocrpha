{ pkgs, lib, fetchFromGitea, extraAttrs }:

with pkgs.python311Packages;
buildPythonPackage rec {
  name = "self-updater";

  src = fetchFromGitea {
    domain = "gitea.chiliahedron.wtf";
    owner = "john-craig";
    repo = "nixos-self-updater";
    hash = "sha256-eKg/F3xlThYUydz/gvd6hhD5wrHPA12VM8HcVs+lw6o=";
    rev = "3a739412987cd5d9a5f5ce9913536dfc20209391";
  };

  format = "pyproject";

  propagatedBuildInputs = [
    setuptools
  ];
}
