{ pkgs, lib, fetchFromGitea } :

with pkgs.python311Packages;
buildPythonPackage rec {
  name = "alucard";

  src = fetchFromGitea {
    domain = "gitea.chiliahedron.wtf";
    owner  = "john-craig";
    repo   = "alucard";
    hash = "sha256-CQnWLV2U72pDcwXvBpQAnprfeY/yhcG/ZMmsgoiO51s=";
    rev = "4bfa25663af7fd250a8165e3b2a4e15fcc27fc46";
  };

  format = "pyproject";
  
  propagatedBuildInputs = [
    # ...
    setuptools
    click
    jinja2
  ];
}