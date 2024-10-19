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
        hash = "sha256-wDoRVrCSIBV0/uZ8NRfjtU7i2wY+ml8XVcx+DijwqS8=";
        rev = "94e45f4608fb279090432effd78777db59ea9f4e";
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