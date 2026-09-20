{ pkgs ? import <nixpkgs> { } }:

pkgs.runCommand "apocrypha-receipt-scanner-static-checks" {
  nativeBuildInputs = [ pkgs.gnugrep ];
} ''
  set -euo pipefail
  module=${../nixos-modules/receipt-scanner.nix}
  scanner=${../pkgs/receipt-scanner/scan-document.bash}
  grep -q 'ES2_BUTTON_NUM' "$module"
  grep -q 'ES2_CARD_SCANNING' "$module"
  grep -q 'coalesced receipt event' "$module"
  grep -q 'pending' "$module"
  grep -q 'listener-control' "$module"
  grep -q 'CREDENTIALS_DIRECTORY' "$module"
  grep -q 'CREDENTIALS_DIRECTORY/paperless_token' "$module"
  grep -q 'LoadCredential' "$module"
  grep -q 'ProtectSystem = "strict"' "$module"
  grep -q 'PrivateTmp = true' "$module"
  grep -q 'flock -n 9' "$module"
  grep -q 'KillSignal = "SIGINT"' "$module"
  grep -q 'StartLimitBurst = 3' "$module"
  grep -q 'paper empty' "$scanner"
  grep -q 'document feeder out' "$scanner"
  grep -q 'image/jpeg' "$scanner"
  grep -q 'post_document' "$scanner"
  ! grep -q 'chiliahedron' "$module" "$scanner"
  ! grep -Eq 'Bearer [A-Za-z0-9._-]{20,}' "$module" "$scanner"
  touch "$out"
''
