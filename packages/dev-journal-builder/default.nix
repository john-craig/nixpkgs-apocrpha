{ pkgs, lib, fetchFromGitea } :

with pkgs.python311Packages;
buildPythonPackage rec {
  name = "dev-journal-builder";

  src = fetchFromGitea {
    domain = "gitea.chiliahedron.wtf";
    owner  = "john-craig";
    repo   = "dev-journal-builder";
    hash = "sha256-ykTRD7hqXd0OKiCwDYiU++697YR3e4CGbRc/a8U61fQ=";
    rev = "5c65f18df19476c118304601426e4513ab1608ea";
  };

  format = "pyproject";
  
  propagatedBuildInputs = [
    setuptools
    detect-secrets
    (buildPythonPackage rec {
      pname = "obsidian-utils";
      src = fetchFromGitea {
        domain = "gitea.chiliahedron.wtf";
        owner  = "john-craig";
        repo   = "obsidian-utils";
        hash = "sha256-bbc15bXYPzePNHahoHMEHq0vYBnb+Nx779jiyRrGdqA=";
        rev = "51dcf23dcb1f76f8765da2c20a8c9d2e197c0f95";
      };
      version = "0.1.0";
      propagatedBuildInputs = [
        setuptools
      ];

      format = "pyproject";
    })
    (buildPythonPackage rec {
      pname = "archivebox-utils";
      src = fetchFromGitea {
        domain = "gitea.chiliahedron.wtf";
        owner  = "john-craig";
        repo   = "archivebox-utils";
        hash = "sha256-Qraol4XJqm8g5ZUZcHUSS300/kkI4K63sKBRU2ut2wM=";
        rev = "5f29e19d4bd73fc521ce7ef56883678d4e3e01de";
      };
      version = "0.1.0";
      propagatedBuildInputs = [
        setuptools
        beautifulsoup4
      ];

      format = "pyproject";
    })
  ];
}