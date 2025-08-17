{ pkgs, fetchFromGitHub, autoconf, automake, extraAttrs }:

with pkgs.python311Packages;
buildPythonPackage {
  name = "rhasspy-speakers-cli-hermes";
  version = "v0.2.0";

  src = fetchFromGitHub {
    owner = "rotdrop";
    repo = "rhasspy-speakers-cli-hermes";
    rev = "8abd3a60e42119f1a509e27bb20d6bd136188e78";
    hash = "sha256-VYoklRVGeyQpTH5MummwUNkvrsc9yNGBLvqIzp5lbv0=";
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
