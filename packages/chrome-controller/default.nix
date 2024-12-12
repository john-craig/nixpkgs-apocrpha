{ pkgs, lib, fetchFromGitea }:

with pkgs.python311Packages;
buildPythonPackage rec {
  name = "chrome-controller";

  src = fetchFromGitea {
    domain = "gitea.chiliahedron.wtf";
    owner = "john-craig";
    repo = "smarthome-chrome-controller";
    hash = "sha256-yM37x7KG04N9mvQVScRxjqhM/0Ye2iYoJKn5z5fZzac=";
    rev = "3156cc3a86fc7a0088a59532ed10ec9e30edca2f";
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
