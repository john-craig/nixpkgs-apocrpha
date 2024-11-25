{ pkgs, lib, fetchFromGitea } :

with pkgs.python311Packages;
buildPythonPackage rec {
  name = "dismas";

  src = fetchFromGitea {
    domain = "gitea.chiliahedron.wtf";
    owner  = "john-craig";
    repo   = "dismas";
    hash = "sha256-r6JqRb7K0Icm3mYja8rG8YZK7JuQLzAGfLZgv3bd9/M=";
    rev = "48edd0e0703ef3e26e84d48f6f11297e841c9698";
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