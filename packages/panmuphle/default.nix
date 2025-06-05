{ pkgs, lib, fetchFromGitea }:

with pkgs.python311Packages;
buildPythonPackage rec {
  name = "panmuphle";

  src = fetchFromGitea {
    domain = "gitea.chiliahedron.wtf";
    owner = "john-craig";
    repo = "panmuphle";
    hash = "sha256-Gq4Kkud9FU1M7l5TTQjQqIYHdSTE7R+7TOgvim1r5k0=";
    rev = "f40f4ae4b6df534fd342dde91c54b0d259c16bf6";
  };

  format = "pyproject";

  propagatedBuildInputs = [
    # ...
    setuptools
    psutil
    watchdog
  ];
}
