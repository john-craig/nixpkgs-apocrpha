
{ pkgs, lib, fetchFromGitea } :

with pkgs.python311Packages;
buildPythonPackage rec {
  name = "self-updater";

  src = fetchFromGitea {
    domain = "gitea.chiliahedron.wtf";
    owner  = "john-craig";
    repo   = "nixos-self-updater";
    hash = "sha256-SQWEA/SdGcUQKd1deqyK6UwHQnE7yjvtAYE0rNvfX4I=";
    rev = "7ddea0472cc1be8c0b97f2636d9317589872524d";
  };

  format = "pyproject";
  
  propagatedBuildInputs = [
    setuptools
  ];
}