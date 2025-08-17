{ lib, fetchFromGitHub, rustPlatform, openssl, pkg-config, stdenv, extraAttrs }:

rustPlatform.buildRustPackage rec {
  pname = "gotify-desktop";
  version = "b3e6b64cc16fba5657bea0475446284df6107869";

  src = fetchFromGitHub {
    owner = "desbma";
    repo = pname;
    rev = version;
    sha256 = "sha256-Z3An7Efia8q+gAD8NpgHpcdEWt1S9urrhKIlknTWyro=";
  };

  cargoHash = "sha256-hCL+vCAplyySHyG1JMJF1LdapzxvEz0UAaaJL66a5CA=";

  nativeBuildInputs = [ pkg-config ];

  buildInputs = [ openssl ];

  meta = with lib; {
    description = "Small Gotify daemon to send messages as desktop notifications";
    homepage = "https://github.com/desbma/gotify-desktop";
    license = licenses.gpl3Plus;
    maintainers = with maintainers; [ bryanasdev000 genofire ];
    broken = stdenv.hostPlatform.isDarwin;
    mainProgram = "gotify-desktop";
  };
}
