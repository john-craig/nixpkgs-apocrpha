{ pkgs ? import <nixpkgs> { } }:

pkgs.runCommand "apocrypha-receipt-scanner-script-tests" {
  nativeBuildInputs = [ pkgs.bash pkgs.coreutils pkgs.findutils pkgs.gnugrep pkgs.gnused ];
} ''
  set -euo pipefail
  work="$TMPDIR/work"
  bin="$TMPDIR/bin"
  mkdir -p "$work" "$bin"
  printf 'token\n' > "$work/token"

  cat > "$bin/scanimage" <<'EOF'
  #!/bin/sh
  if [ "''${SCAN_MODE:-valid}" = empty ]; then exit 0; fi
  printf 'fake jpeg data' > "$7"
EOF
  cat > "$bin/file" <<'EOF'
  #!/bin/sh
  if [ "''${SCAN_MODE:-valid}" = invalid ]; then printf '%s\n' text/plain; else printf '%s\n' image/jpeg; fi
EOF
  cat > "$bin/curl" <<'EOF'
  #!/bin/sh
  cat >/dev/null
  printf '%s\n' "$*" >> "$CURL_LOG"
  [ "''${CURL_MODE:-success}" != fail ]
EOF
  chmod +x "$bin"/*
  export PATH="$bin:${pkgs.bash}/bin:${pkgs.coreutils}/bin:${pkgs.findutils}/bin:${pkgs.gnugrep}/bin:${pkgs.gnused}/bin"
  export CURL_LOG="$work/curl.log"
  : > "$CURL_LOG"

  run_scan() {
    bash ${./../pkgs/receipt-scanner/scan-document.bash} \
      --device test-device \
      --paperless-url https://paperless.example.test \
      --token-file "$work/token" \
      --output-dir "$1" \
      test-receipt
  }

  mkdir "$work/empty"
  SCAN_MODE=empty run_scan "$work/empty" && exit 1 || true
  test ! -s "$CURL_LOG"

  mkdir "$work/invalid"
  SCAN_MODE=invalid run_scan "$work/invalid" && exit 1 || true
  test "$(wc -l < "$CURL_LOG")" -eq 0

  mkdir "$work/success"
  SCAN_MODE=valid CURL_MODE=success run_scan "$work/success"
  test -s "$work/success/last-scan.jpeg"
  test "$(find "$work/success" -name 'scanned-*.jpeg' -type f | wc -l)" -eq 0

  mkdir "$work/failure"
  SCAN_MODE=valid CURL_MODE=fail run_scan "$work/failure" && exit 1 || true
  test "$(find "$work/failure" -name 'scanned-*.jpeg' -type f | wc -l)" -eq 1
  test "$(wc -l < "$CURL_LOG")" -eq 2
  touch "$out"
''
