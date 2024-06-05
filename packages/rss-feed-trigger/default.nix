{ pkgs, lib, fetchFromGitea } :

with pkgs.python311Packages;
buildPythonPackage rec {
  name = "rss-feed-trigger";

  src = fetchFromGitea {
    domain = "gitea.chiliahedron.wtf";
    owner  = "john-craig";
    repo   = "rss-feed-trigger";
    hash = "sha256-5YBVOzefKg4/BZcuoTjxLgylgONlIlERdxGX4TYbzM4=";
    rev = "44aeb6e45c639b78cc82876aec3c7af7c45553e3";
  };

  format = "other";
  
  propagatedBuildInputs = [
    feedparser
  ];

  installPhase = "install -Dm755 ./watcher.py $out/bin/rss-feed-trigger";
}