{ pkgs, lib, fetchFromGitea } :

with pkgs.python311Packages;
buildPythonPackage rec {
  name = "chrome-controller";

  src = fetchFromGitea {
    domain = "gitea.chiliahedron.wtf";
    owner  = "john-craig";
    repo   = "smarthome-chrome-controller";
    hash = "sha256-AW/XLL0vhgDj/UiVqMjEQDxgrglNPlGhAy+VPPcqC9w=";
    rev = "f8ea90017f54acac87b10abcb9b9e671cc1382ce";
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