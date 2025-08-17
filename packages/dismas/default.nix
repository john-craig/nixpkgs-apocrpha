{ pkgs, lib, fetchFromGitea, fetchFromGitHub, extraAttrs }:

with pkgs.python311Packages;
buildPythonPackage rec {
  name = "dismas";

  src = fetchFromGitea {
    domain = "gitea.chiliahedron.wtf";
    owner = "john-craig";
    repo = "dismas";
    hash = "sha256-fY7/fZYBrFwgp6KAOc+F3gFmkMLMb2gmqF1ZYAQg69E=";
    rev = "e48dadd868568b82dc7bfb08ff21bc8c38b1d16a";
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
        hash = "sha256-6HDfUnE7r3NyNn9VIs66/uml/1CQglBEXtYGIL0CDlo=";
        rev = "d012402263cc17e3a56122934406ab64003cc287";
      };
      version = "0.1.0";
      propagatedBuildInputs = [
        setuptools
        pytest
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
