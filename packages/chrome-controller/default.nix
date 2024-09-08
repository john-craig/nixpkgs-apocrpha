{ pkgs, lib, fetchFromGitea } :

with pkgs.python311Packages;
buildPythonPackage rec {
  name = "chrome-controller";

  src = fetchFromGitea {
    domain = "gitea.chiliahedron.wtf";
    owner  = "john-craig";
    repo   = "smarthome-chrome-controller";
    hash = "sha256-fcOKPRshwo68YEni7M6bmPo7QccDrw52506yXEpcacw=";
    rev = "d72bde25eadd870ecc18d99abe0d38637a86e713";
  };

  format = "pyproject";
  
  propagatedBuildInputs = [
    # ...
    setuptools
    click
    (buildPythonPackage rec {
      pname = "PyChromeDevTools";
      version = "1.0.3";
      src = fetchPypi {
        inherit pname version;
        hash = "sha256-pCmWi7GNNDItpO0bcnmA01+9gQTU52T20YULT/xuVjs=";
      };
      propagatedBuildInputs = [
        requests
        websocket-client
      ];
      doCheck = false;
    })
  ];
}