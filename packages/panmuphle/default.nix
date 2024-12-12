{ pkgs, lib, fetchFromGitea }:

with pkgs.python311Packages;
buildPythonPackage rec {
  name = "panmuphle";

  src = fetchFromGitea {
    domain = "gitea.chiliahedron.wtf";
    owner = "john-craig";
    repo = "panmuphle";
    hash = "sha256-QCrTMA53unmp477MjwcG9CAqK5dFalyl3CrFY8ZE20c=";
    rev = "e557a9d11a318f786451314f87db7cf1b72eb619";
  };

  format = "pyproject";

  propagatedBuildInputs = [
    # ...
    setuptools
    psutil
    watchdog
  ];
}
