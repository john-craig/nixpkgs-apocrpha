{ pkgs, lib, fetchFromGitea }:

with pkgs.python311Packages;
buildPythonPackage rec {
  name = "faustroll";

  src = fetchFromGitea {
    domain = "gitea.chiliahedron.wtf";
    owner = "john-craig";
    repo = "faustroll";
    hash = "sha256-yJT9F77wtJ3RsomGFmv1kNxNj5/Qovvw4r0X1ZDcrXc=";
    rev = "0a71590868f6a53bbe732daa85dc51dd77549d4a";
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
