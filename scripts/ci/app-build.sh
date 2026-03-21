#!/usr/bin/env bash
set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ $# -ne 1 ]]; then
  echo "usage: scripts/ci/app-build.sh <ios|maccatalyst>" >&2
  exit 1
fi

case "$1" in
  ios|iOS)
    "${SCRIPT_DIR}/../dev/app-build-ios.sh"
    ;;
  maccatalyst|"mac-catalyst"|"Mac Catalyst")
    "${SCRIPT_DIR}/../dev/app-build-maccatalyst.sh"
    ;;
  *)
    echo "error: unsupported lane '$1'" >&2
    echo "supported lanes: ios, maccatalyst" >&2
    exit 1
    ;;
esac
