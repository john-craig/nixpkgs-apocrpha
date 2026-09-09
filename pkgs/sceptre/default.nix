{ lib, fetchFromGitHub, git, rustPlatform }:

rustPlatform.buildRustPackage rec {
  pname = "sceptre";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "john-craig";
    repo = "sceptre";
    rev = "93694d94313b3658644055414a5bded2c55a9e89";
    hash = "sha256-7ICBOhMNIYYF/Z80Ln6K4cfWM4trx+JJGssenT5BsP4=";
  };

  nativeBuildInputs = [ git ];

  cargoLock = {
    lockFile = "${src}/Cargo.lock";
    extraRegistries = {
      "https://github.com/rust-lang/crates.io-index" = "https://static.crates.io/crates";
    };
  };

  preBuild = ''
    sed -i '/\[source."https:\/\/github.com\/rust-lang\/crates.io-index"\]/,/^$/d' "$NIX_BUILD_TOP/.cargo/config.toml"
  '';

  preCheck = ''
    export GIT_CONFIG_COUNT=2
    export GIT_CONFIG_KEY_0=user.email
    export GIT_CONFIG_VALUE_0=build@example.invalid
    export GIT_CONFIG_KEY_1=user.name
    export GIT_CONFIG_VALUE_1=sceptre-build
  '';

  postInstall = ''
    mv "$out/bin/rust-template" "$out/bin/sceptre"
  '';

  meta = with lib; {
    description = "Rust CLI for Grimoire development workflows";
    homepage = "https://github.com/john-craig/sceptre";
    license = licenses.mit;
    mainProgram = "sceptre";
    platforms = platforms.unix;
  };
}
