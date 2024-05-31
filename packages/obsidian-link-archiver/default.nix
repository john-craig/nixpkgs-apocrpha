{ pkgs, lib, fetchFromGitea } :

with pkgs.python311Packages;
buildPythonPackage rec {
  name = "obsidian-link-archiver";

  src = fetchFromGitea {
    domain = "gitea.chiliahedron.wtf";
    owner  = "john-craig";
    repo   = "obsidian-link-archiver";
    hash = "sha256-HlQKpKHh1ChjxPyce4Xr0uxazbx0BhOnCuvGsGDkxKc=";
    rev = "443f4776fa3ec7f1b181a832df43c5f749d296ad";
  };

  format = "other";
  
  propagatedBuildInputs = [
    beautifulsoup4
    requests
    urllib3
  ];

  installPhase = "install -Dm755 ./obsidian-link-archiver.py $out/bin/obsidian-link-archiver";
}