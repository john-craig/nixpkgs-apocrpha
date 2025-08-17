{ pkgs, lib, fetchFromGitea, extraAttrs }:

with pkgs.python311Packages;
buildPythonPackage rec {
  name = "dev-journal-builder";

  src = fetchFromGitea {
    domain = "gitea.chiliahedron.wtf";
    owner = "john-craig";
    repo = "dev-journal-builder";
    hash = "sha256-ePPf02VhI8kdGNtux1muuY/OCGGW3hZlLAEobQAB6+I=";
    rev = "20c4e02a0094278ebb5e678e89f6d866826fcdfa";
  };

  format = "pyproject";

  propagatedBuildInputs = [
    setuptools
    detect-secrets
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
    (buildPythonPackage rec {
      pname = "archivebox-utils";
      src = fetchFromGitea {
        domain = "gitea.chiliahedron.wtf";
        owner = "john-craig";
        repo = "archivebox-utils";
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
