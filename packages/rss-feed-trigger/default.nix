{ pkgs, lib, fetchFromGitea } :

with pkgs.python311Packages;
buildPythonPackage rec {
  name = "rss-feed-trigger";

  src = fetchFromGitea {
    domain = "gitea.chiliahedron.wtf";
    owner  = "john-craig";
    repo   = "rss-feed-trigger";
    hash = "sha256-iF/pXuD1b2lovYVgcoMpYpT8aZx4kthQRuVIUCbufUo=";
    rev = "ea8d2de9e6bc87a5e14863bf3901adafb0876577";
  };

  format = "other";
  
  propagatedBuildInputs = [
    feedparser
  ];

  installPhase = "install -Dm755 ./watcher.py $out/bin/rss-feed-trigger";
}