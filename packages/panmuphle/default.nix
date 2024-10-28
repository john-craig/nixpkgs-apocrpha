{ pkgs, lib, fetchFromGitea } :

with pkgs.python311Packages;
buildPythonPackage rec {
  name = "panmuphle";

  src = fetchFromGitea {
    domain = "gitea.chiliahedron.wtf";
    owner  = "john-craig";
    repo   = "panmuphle";
    hash = "sha256-kcXbQDvBUY1CfrlQX4F6P40FW+h0pyPeJBSrbQ/CuBs=";
    rev = "0c1a19219efcc5d5c0c51a6fe76293c4eb70ee37";
  };

  format = "pyproject";
  
  propagatedBuildInputs = [
    # ...
    setuptools
    psutil
    watchdog
  ];
}