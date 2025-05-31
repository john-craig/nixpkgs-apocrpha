{ pkgs, lib, fetchFromGitea, fetchFromGitHub }:

with pkgs.python311Packages;
buildPythonPackage rec {
  name = "dismas";

  src = fetchFromGitea {
    domain = "gitea.chiliahedron.wtf";
    owner = "john-craig";
    repo = "dismas";
    hash = "sha256-O2H1dZOUk2GEeGz7b8MWsNfNPjni7kKxHKsb/C/7Wm0=";
    rev = "491e0ce607043f7229adac10062dccf4046d207a";
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
