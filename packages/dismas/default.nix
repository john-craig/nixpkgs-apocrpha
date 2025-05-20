{ pkgs, lib, fetchFromGitea, fetchFromGitHub }:

with pkgs.python311Packages;
buildPythonPackage rec {
  name = "dismas";

  src = fetchFromGitea {
    domain = "gitea.chiliahedron.wtf";
    owner = "john-craig";
    repo = "dismas";
    hash = "sha256-SORqEI6iy3h9civRBohAzYT7gBmqZy5Y8cre0KaeHVI=";
    rev = "d43edbdd1a77c3a47a6da448aa6b2aa31aca0da0";
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
        owner = "john-craig";
        repo = "obsidian-utils";
        hash = "sha256-ZfujMlWs/IVITmVHvUJeazwPx43OxuVn1FXQ694RtiM=";
        rev = "96ed4b9f0aea319046a832f766d457b88a63ceef";
      };
      version = "0.1.0";
      propagatedBuildInputs = [
        setuptools
      ];

      format = "pyproject";
    })
    (buildPythonPackage rec {
      pname = "python-deepcompare";
      src = fetchFromGitHub {
        owner = "anexia";
        repo = "python-deepcompare";
        hash = "sha256-SZLedPKb6WghIymT5VQH4CnkJ225TNiqfUtxZmtJ3OM=";
        rev = "6021801b1673eff763c53c4c243936911ae25891";
      };
      version = "2.1.0";
      propagatedBuildInputs = [
        setuptools
      ];

      format = "pyproject";
    })
  ];
}
