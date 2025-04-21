{ pkgs, lib, fetchFromGitea }:

with pkgs.python311Packages;
buildPythonPackage rec {
  name = "status-page-generator";

  src = fetchFromGitea {
    domain = "gitea.chiliahedron.wtf";
    owner = "john-craig";
    repo = "status-generator";
    hash = "sha256-5v1wlgHOKTeSZ83HZ9MTAfMalcbEOKTMXjO7hT6lkYo=";
    rev = "22c134135df904163c9ead8341dea427a6f3d2c0";
  };

  format = "pyproject";

  propagatedBuildInputs = [
    setuptools
    jinja2
    (buildPythonPackage rec {
      pname = "obsidian-utils";
      src = fetchFromGitea {
        domain = "gitea.chiliahedron.wtf";
        owner = "john-craig";
        repo = "obsidian-utils";
        hash = "sha256-hg/I5DS+4Wf+nDa8hFNQMmoesxyBHe+aOUMpNZRQQIs=";
        rev = "6e6c13b156758e844b37070ca77d02e0c2bbcb7b";
      };
      version = "0.1.0";
      propagatedBuildInputs = [
        setuptools
      ];

      format = "pyproject";
    })
  ];
}
