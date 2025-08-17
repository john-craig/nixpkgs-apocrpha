{ pkgs, lib, fetchFromGitea, extraAttrs }:

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
        hash = "sha256-l9kopSXQhX86EwO1BwgeLANP8E8Dp+WQEeJNRFRfel4=";
        rev = "d9d6aaa31e908e01df355abb9b487391098a7dd0";
      };
      version = "0.1.0";
      propagatedBuildInputs = [
        setuptools
        pytest
      ];

      format = "pyproject";
    })
  ];
}
