{ pkgs, lib, fetchFromGitea }:

with pkgs.python311Packages;
buildPythonPackage rec {
  name = "faustroll";

  src = fetchFromGitea {
    domain = "gitea.chiliahedron.wtf";
    owner = "john-craig";
    repo = "faustroll";
    hash = "sha256-LesCvBsHhcWwWnDLKI8Dp8dWUfpIg/sxU0UBNL5LXcA=";
    rev = "247c7524d592e7edb040f6ffb333be85c27d75f7";
  };

  format = "pyproject";

  propagatedBuildInputs = [
    # ...
    setuptools
    (buildPythonPackage rec {
      pname = "obsidian-utils";
      src = fetchFromGitea {
        domain = "gitea.chiliahedron.wtf";
        owner = "john-craig";
        repo = "obsidian-utils";
        hash = "sha256-bbc15bXYPzePNHahoHMEHq0vYBnb+Nx779jiyRrGdqA=";
        rev = "51dcf23dcb1f76f8765da2c20a8c9d2e197c0f95";
      };
      version = "0.1.0";
      propagatedBuildInputs = [
        setuptools
      ];

      format = "pyproject";
    })
  ];
}
