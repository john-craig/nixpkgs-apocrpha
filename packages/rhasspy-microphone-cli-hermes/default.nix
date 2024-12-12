{ pkgs, fetchFromGitHub, autoconf, automake }:

with pkgs.python311Packages;
buildPythonPackage {
  name = "rhasspy-microphone-cli-hermes";
  version = "v0.2.0";

  src = fetchFromGitHub {
    owner = "rotdrop";
    repo = "rhasspy-microphone-cli-hermes";
    rev = "d6095823fa9218b1bbc639cfc3e6ce88c3f14dea";
    hash = "sha256-yViO54LncUueRRW/lR/4+RMq04ikOAryY+lwYbNN1ag=";
  };

  # buildPhase = ''
  #   # this line removes a bug where value of $HOME is set to a non-writable /homeless-shelter dir
  #   export HOME=$(pwd)
  #   '';

  patchPhase = ''
    patchShebangs scripts/*.sh
    export HOME=$(pwd)
  '';

  doCheck = false;

  buildInputs = [
    autoconf
    automake
    pip
    virtualenv
  ];

  propagatedBuildInputs = [
    webrtcvad

    setuptools
    dataclasses-json
    audioread
    soundfile

    (buildPythonPackage rec {
      pname = "paho-mqtt";
      version = "1.5.0";
      src = fetchPypi {
        inherit pname version;
        hash = "sha256-49KGGYuq6hlcizvCIZQdJaOrDhUH/Bd5vbdHOAY5S+Q=";
      };
      doCheck = false;
    })

    (buildPythonPackage rec {
      pname = "rhasspy-hermes";
      version = "0.6.2";
      src = fetchPypi {
        inherit pname version;
        hash = "sha256-z+rX2Vui4kU+tC0ybt/Dm0b1FYQkaOz0an6fSxYw/AE=";
      };
      doCheck = false;
    })
    (buildPythonPackage rec {
      pname = "wavchunk";
      version = "1.0.2";
      src = fetchPypi {
        inherit pname version;
        hash = "sha256-f47vCJIzLHQU8F9mYJs1gSgatKrF8NSuCFiUTu5r8xA=";
      };
      doCheck = false;
    })
  ];
}
