{ pkgs, lib, fetchFromGitea, fetchFromGitHub, extraAttrs }:

with pkgs.python311Packages;
buildPythonPackage rec {
  name = "nocodb_writing_tracker";

  src = fetchFromGitea {
    domain = "gitea.chiliahedron.wtf";
    owner = "john-craig";
    repo = "nocodb_writing_tracker";
    hash = "sha256-rrjO1/LzeA6qqZXgEnGG6xLo4t0Vnkrcs+1O8JINaiA=";
    rev = "3a3439a6c2944fb2a420a32c1bab96d40d327ce3";
  };

  format = "pyproject";

  propagatedBuildInputs = [
    # ...
    setuptools
    click
    python-docx
    (buildPythonPackage rec {
      pname = "nocodb-api";
      src = fetchFromGitHub {
        owner = "infeeeee";
        repo = "nocodb-api";
        hash = "sha256-wJ4jEveDBNI1/JWjC5MERA1l0dtcTuTgn20nT2bmLyk=";
        rev = "e261f4df3c32d48bb33ac18ce2c0f07d41092c15";
      };
      version = "0.0.4";
      format = "pyproject";
      propagatedBuildInputs = [
        setuptools
        requests
      ];
    })
  ];
}
