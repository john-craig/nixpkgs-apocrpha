#!/usr/bin/env bash
set -euo pipefail

SCANNER_DEVICE="${SCANNER_DEVICE:-}"
PAPERLESS_URL="${PAPERLESS_URL:-}"
API_TOKEN_PATH="${API_TOKEN_PATH:-}"
OUTPUT_DIR="${OUTPUT_DIR:-${TMPDIR:-/tmp}}"
DOCUMENT_TITLE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --device) SCANNER_DEVICE="${2:?missing value for --device}"; shift 2 ;;
    --paperless-url) PAPERLESS_URL="${2:?missing value for --paperless-url}"; shift 2 ;;
    --token-file) API_TOKEN_PATH="${2:?missing value for --token-file}"; shift 2 ;;
    --output-dir) OUTPUT_DIR="${2:?missing value for --output-dir}"; shift 2 ;;
    --) shift; DOCUMENT_TITLE="$*"; break ;;
    -*) echo "unknown option: $1" >&2; exit 2 ;;
    *) DOCUMENT_TITLE="${DOCUMENT_TITLE:+$DOCUMENT_TITLE }$1"; shift ;;
  esac
done

if [[ -z "$DOCUMENT_TITLE" || -z "$SCANNER_DEVICE" || -z "$PAPERLESS_URL" || -z "$API_TOKEN_PATH" ]]; then
  echo "Usage: scan-document --device DEVICE --paperless-url URL --token-file FILE --output-dir DIR TITLE" >&2
  exit 2
fi

[[ "$SCANNER_DEVICE" != *" "* && "$SCANNER_DEVICE" != *$'\n'* ]] || {
  echo "scanner device contains whitespace" >&2
  exit 2
}
[[ -r "$API_TOKEN_PATH" ]] || { echo "Paperless token is unreadable: $API_TOKEN_PATH" >&2; exit 1; }
if [[ -e "$OUTPUT_DIR" && ! -d "$OUTPUT_DIR" ]]; then
  echo "Output path is not a directory: $OUTPUT_DIR" >&2
  exit 1
fi
install -d -m 0750 "$OUTPUT_DIR"

TITLE_SLUG="$(printf '%s' "$DOCUMENT_TITLE" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+|-+$//g')"
TITLE_SLUG="${TITLE_SLUG:-document}"
DOC_PATH="$OUTPUT_DIR/scanned-${TITLE_SLUG}-$(date +%s)-$$.jpeg"
LAST_SCAN_PATH="$OUTPUT_DIR/last-scan.jpeg"
uploaded=0
SCAN_LOG=""

cleanup() {
  [[ -z "$SCAN_LOG" ]] || rm -f -- "$SCAN_LOG"
  if [[ "$uploaded" == 1 ]]; then rm -f -- "$DOC_PATH"; fi
}
trap cleanup EXIT

echo "Scanning document using device: $SCANNER_DEVICE"
SCAN_LOG="$(mktemp)"
scan_status=0
scanimage -d "$SCANNER_DEVICE" --mode Grayscale --format=jpeg --output-file "$DOC_PATH" 2>"$SCAN_LOG" || scan_status=$?
cat "$SCAN_LOG" >&2
if [[ ! -s "$DOC_PATH" ]]; then
  echo "Scanner produced no usable output (exit status: $scan_status; output: $DOC_PATH)" >&2
  exit 1
fi

scan_mime="$(file --brief --mime-type "$DOC_PATH")"
paper_empty_diagnostic="$(grep -Ein 'paper empty' "$SCAN_LOG" || true)"
scan_diagnostics="$(grep -Ein 'document feeder out|error during device i/o|sane_start:' "$SCAN_LOG" || true)"
if [[ -n "$paper_empty_diagnostic" ]]; then
  printf 'Scanner backend warning (scan data was produced):\n%s\n' "$paper_empty_diagnostic" >&2
fi
if [[ -n "$scan_diagnostics" ]]; then
  printf 'Scanner backend diagnostics:\n%s\n' "$scan_diagnostics" >&2
  echo "Scanner reported a feeder or I/O error (exit status: $scan_status; output: $DOC_PATH)" >&2
  exit 1
fi
if [[ "$scan_mime" != image/jpeg ]]; then
  echo "Scanner produced an unexpected output type (MIME: $scan_mime; exit status: $scan_status; output: $DOC_PATH)" >&2
  exit 1
fi
(( scan_status == 0 )) || echo "Scanner returned status $scan_status after producing a valid JPEG; continuing" >&2

ENDPOINT_URL="${PAPERLESS_URL%/}/api/documents/post_document/"
echo "Submitting scanned document to Paperless instance at $PAPERLESS_URL with title: $DOCUMENT_TITLE"
{ echo -n 'Authorization: Token '; tr -d '\n' < "$API_TOKEN_PATH"; } | \
  curl --silent --show-error --fail -X POST "$ENDPOINT_URL" \
    -F "document=@$DOC_PATH" \
    -F "title=$DOCUMENT_TITLE" \
    -H @-

if ! cp -- "$DOC_PATH" "$LAST_SCAN_PATH"; then
  echo "Warning: uploaded scan could not be preserved at $LAST_SCAN_PATH" >&2
else
  echo "Preserved uploaded scan at: $LAST_SCAN_PATH"
fi
uploaded=1
