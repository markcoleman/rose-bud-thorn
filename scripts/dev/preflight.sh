#!/usr/bin/env bash
set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"

show_usage() {
  cat <<'EOF'
Usage: scripts/dev/preflight.sh [--package-only] [--help]

Options:
  --package-only   Run package checks only.
  --help           Print this help text.
EOF
}

package_only=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --package-only)
      package_only=1
      ;;
    --help|-h)
      show_usage
      exit 0
      ;;
    *)
      echo "error: unknown option '$1'" >&2
      show_usage >&2
      exit 1
      ;;
  esac
  shift
done

"${SCRIPT_DIR}/package-build.sh"
"${SCRIPT_DIR}/package-test.sh"

if [[ "${package_only}" == "1" ]]; then
  echo "preflight: package checks complete"
  exit 0
fi

"${SCRIPT_DIR}/app-build-ios.sh"
"${SCRIPT_DIR}/app-build-maccatalyst.sh"

echo "preflight: package and app checks complete"
