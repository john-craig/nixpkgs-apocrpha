{ pkgs, lib, fetchFromGitea, fetchFromGitHub, extraAttrs }:

with pkgs.python311Packages;
buildPythonPackage {
  name = "timeflip-tracker";

  src = fetchFromGitea {
    domain = "gitea.chiliahedron.wtf";
    owner = "john-craig";
    repo = "timeflip-tracker";
    hash = "sha256-XpnyAWBQ0KTALMrnqANa4NkuvOav1q8t1jYJ5h09foA=";
    rev = "9648b48c8d5884911c38614711413d20bd4612ac";
  };

  doCheck = false;

  format = "pyproject";

  propagatedBuildInputs = [
    # ...
    setuptools
    aiooui
    autopep8
    bleak
    bluetooth-adapters
    certifi
    charset-normalizer
    colour
    dbus-fast
    dbus-next
    flake8
    # flake8-quotes
    idna
    mariadb
    mccabe
    packaging
    prometheus_client
    pycodestyle
    pyflakes
    python-dotenv
    (buildPythonPackage rec {
      pname = "pytimefliplib";
      version = "aaf01843c4eb3e147fac0c92bfb45d43567306c6";
      src = fetchFromGitHub {
        owner = "pierre-24";
        repo = "pytimefliplib";
        rev = "${version}";
        hash = "sha256-/+W2fFvkMSbLY/tzrv0d44R2n6v2taQ8jVhfOvDHEzg="; # TODO
      };

      format = "pyproject";

      propagatedBuildInputs = [
        # ...
        setuptools
        bleak
      ];
    })
    requests
    ruamel_yaml
    ruamel_yaml_clib
    toml
    typing-extensions
    urllib3
    usb-devices
  ];
}
