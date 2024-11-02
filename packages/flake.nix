{
  description = "Apocryphal Packages";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, utils }: 
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; config.allowUnfree = true; };
    in {
      packages."x86_64-linux".chrome-controller = pkgs.callPackage ./chrome-controller {};
      packages."x86_64-linux".dismas = pkgs.callPackage ./dismas {};
      packages."x86_64-linux".dev-journal-builder = pkgs.callPackage ./dev-journal-builder {};
      packages."x86_64-linux".faustroll = pkgs.callPackage ./faustroll {};
      packages."x86_64-linux".rhasspy-microphone-cli-hermes = pkgs.callPackage ./rhasspy-microphone-cli-hermes {};
      packages."x86_64-linux".rhasspy-speakers-cli-hermes = pkgs.callPackage ./rhasspy-speakers-cli-hermes {};
      packages."x86_64-linux".obsidian-link-archiver = pkgs.callPackage ./obsidian-link-archiver {};
      packages."x86_64-linux".panmuphle = pkgs.callPackage ./panmuphle {};
      packages."x86_64-linux".rss-feed-trigger = pkgs.callPackage ./rss-feed-trigger {};
      packages."x86_64-linux".smartctl-ssacli-exporter = pkgs.callPackage ./smartctl-ssacli-exporter {};
      packages."x86_64-linux".hpssacli = pkgs.callPackage ./hpssacli {};
      packages."x86_64-linux".self-updater = pkgs.callPackage ./self-updater {};
      packages."x86_64-linux".status-page-generator = pkgs.callPackage ./status-page-generator {};

      # Create overlay
      overlays.default = final: prev: {
        chrome-controller = self.packages."x86_64-linux".chrome-controller;
        dismas = self.packages."x86_64-linux".dismas;
        dev-journal-builder = self.packages."x86_64-linux".dev-journal-builder;
        faustroll = self.packages."x86_64-linux".faustroll;
        rhasspy-microphone-cli-hermes = self.packages."x86_64-linux".rhasspy-microphone-cli-hermes;
        rhasspy-speakers-cli-hermes = self.packages."x86_64-linux".rhasspy-speakers-cli-hermes;
        obsidian-link-archiver = self.packages."x86_64-linux".obsidian-link-archiver;
        panmuphle = self.packages."x86_64-linux".panmuphle;
        rss-feed-trigger = self.packages."x86_64-linux".rss-feed-trigger;
        smartctl-ssacli-exporter = self.packages."x86_64-linux".smartctl-ssacli-exporter;
        hpssacli = self.packages."x86_64-linux".hpssacli;
        self-updater = self.packages."x86_64-linux".self-updater;
        status-page-generator = self.packages."x86_64-linux".status-page-generator;
      };
  };
}
