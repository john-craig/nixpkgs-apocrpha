{ pkgs, lib, fetchFromGitea } :

with pkgs.python311Packages;
buildPythonPackage rec {
  name = "rss-feed-trigger";

  src = fetchFromGitea {
    domain = "gitea.chiliahedron.wtf";
    owner  = "john-craig";
    repo   = "rss-feed-trigger";
    hash = "sha256-bVMsX2PRj5MRCu21EotFKowFkDw60vimQ+2TbAuFioQ=";
    rev = "6d2acadfa3daf7eeff99df2804fd8c95e30fea14";
  };

  format = "other";
  
  propagatedBuildInputs = [
    feedparser
  ];

  installPhase = "install -Dm755 ./watcher.py $out/bin/rss-feed-trigger";
}