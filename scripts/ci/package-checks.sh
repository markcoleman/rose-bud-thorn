#!/usr/bin/env bash
set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

"${SCRIPT_DIR}/../dev/package-build.sh"
"${SCRIPT_DIR}/../dev/package-test.sh"
