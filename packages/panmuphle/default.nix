{ pkgs, lib, fetchFromGitea }:

with pkgs.python311Packages;
buildPythonPackage rec {
  name = "panmuphle";

  src = fetchFromGitea {
    domain = "gitea.chiliahedron.wtf";
    owner = "john-craig";
    repo = "panmuphle";
    hash = "sha256-OEnAOD6ytXIc4K828okAo7sEhn8hIctCLFodqVrBMcM=";
    rev = "54693158d10b1ff6afb3bf5bae30f47bce1bb627";
  };

  format = "pyproject";

  propagatedBuildInputs = [
    # ...
    setuptools
    psutil
    watchdog
  ];
}
