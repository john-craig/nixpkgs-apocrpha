{ pkgs, lib, fetchFromGitea } :

with pkgs.python311Packages;
buildPythonPackage rec {
  name = "panmuphle";

  src = fetchFromGitea {
    domain = "gitea.chiliahedron.wtf";
    owner  = "john-craig";
    repo   = "panmuphle";
    hash = "sha256-vwByBT5OtbbNiI1e+BrffGPRlErUPvKBYDGFrm2eDq4=";
    rev = "00a14b40c85a97de416d83b93980123690054c04";
  };

  format = "pyproject";
  
  propagatedBuildInputs = [
    # ...
    setuptools
    psutil
    watchdog
  ];
}