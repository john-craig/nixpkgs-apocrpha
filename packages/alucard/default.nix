{ pkgs, lib, fetchFromGitea }:

with pkgs.python311Packages;
buildPythonPackage rec {
  name = "alucard";

  src = fetchFromGitea {
    domain = "gitea.chiliahedron.wtf";
    owner = "john-craig";
    repo = "alucard";
    hash = "sha256-6jUqCOBt1omGGvT0hUqDY7RNH1tWoyYKYA0JWf8faDY=";
    rev = "f1d7aef20aa5e14bb472c70f5b512f04a0d624b2";
  };

  format = "pyproject";

  propagatedBuildInputs = [
    # ...
    setuptools
    click
    jinja2
  ];
}
