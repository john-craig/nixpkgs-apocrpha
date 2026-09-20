#!/usr/bin/env bash
set -euo pipefail

exec scan-document "$@" -- "receipt-$(date +%s)"
