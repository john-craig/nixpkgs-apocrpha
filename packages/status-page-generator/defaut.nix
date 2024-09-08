{ pkgs, lib, fetchFromGitea } :

with pkgs.python311Packages;
buildPythonPackage rec {
  name = "status-page-generator";

  src = fetchFromGitea {
    domain = "gitea.chiliahedron.wtf";
    owner  = "john-craig";
    repo   = "status-page";
    hash = lib.fakeHash;
    rev = "b0deb59f3ef1f4a4c452010f652bd84833c9d27e";
  };

  format = "pyproject";
  
  propagatedBuildInputs = [
    Jinja2
    (buildPythonPackage rec {
      pname = "obsidian-utils";
      src = fetchFromGitea {
        domain = "gitea.chiliahedron.wtf";
        owner  = "john-craig";
        repo   = "obsidian-utils";
        hash = lib.fakeHash;
        rev = "6e6c13b156758e844b37070ca77d02e0c2bbcb7b";
      };

      format = "pyproject";
    })
  ];
}