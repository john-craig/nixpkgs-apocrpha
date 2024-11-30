{ pkgs, lib, fetchFromGitea } :

with pkgs.python311Packages;
buildPythonPackage rec {
  name = "dismas";

  src = fetchFromGitea {
    domain = "gitea.chiliahedron.wtf";
    owner  = "john-craig";
    repo   = "dismas";
    hash = "sha256-vs64BsoTv/ZgESkXi24WDRobhNTNLeDaDPgkxFCrzWQ=";
    rev = "ae9add293c480ab66be625b39a861b835901e089";
  };

  format = "pyproject";
  
  propagatedBuildInputs = [
    # ...
    setuptools
    click
    jinja2
    (buildPythonPackage rec {
      pname = "obsidian-utils";
      src = fetchFromGitea {
        domain = "gitea.chiliahedron.wtf";
        owner  = "john-craig";
        repo   = "obsidian-utils";
        hash = "sha256-ZfujMlWs/IVITmVHvUJeazwPx43OxuVn1FXQ694RtiM=";
        rev = "96ed4b9f0aea319046a832f766d457b88a63ceef";
      };
      version = "0.1.0";
      propagatedBuildInputs = [
        setuptools
      ];

      format = "pyproject";
    })
  ];
}