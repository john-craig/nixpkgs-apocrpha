{ pkgs, lib, fetchFromGitea } :

with pkgs.python311Packages;
buildPythonPackage rec {
  name = "chrome-controller";

  src = fetchFromGitea {
    domain = "gitea.chiliahedron.wtf";
    owner  = "john-craig";
    repo   = "smarthome-chrome-controller";
    hash = "sha256-9uLEixfJjn0RbTzvwToNozkH05KXm9vKuxGhaswwyOY=";
    rev = "50e3077b8718d62da867b0fa5c0df7f967c43a25";
  };

  format = "pyproject";
  
  propagatedBuildInputs = [
    # ...
    setuptools
    click
    ruamel-yaml
    ruamel-yaml-clib
    (buildPythonPackage rec {
      pname = "PyChromeDevTools";
      version = "1.0.3";
      src = fetchPypi {
        inherit pname version;
        hash = "sha256-pCmWi7GNNDItpO0bcnmA01+9gQTU52T20YULT/xuVjs=";
      };
      doCheck = false;
    })
  ];

  # installPhase = "install -Dm755 ./obsidian-link-archiver.py $out/bin/obsidian-link-archiver";
}