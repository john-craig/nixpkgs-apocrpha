{ pkgs, lib, fetchFromGitea }:

with pkgs.python311Packages;
buildPythonPackage rec {
  name = "panmuphle";

  src = fetchFromGitea {
    domain = "gitea.chiliahedron.wtf";
    owner = "john-craig";
    repo = "panmuphle";
    hash = "sha256-BC6Um0CPICpFC3d74ajBDvRphLM9d45sN27ZsOxNdCI=";
    rev = "049630ff411df20cdbbf5ea25a8592435f2dcc10";
  };

  format = "pyproject";

  propagatedBuildInputs = [
    # ...
    setuptools
    psutil
    watchdog
  ];
}
