#!/usr/bin/env bash
set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT_DEFAULT="$(cd "${SCRIPT_DIR}/.." && pwd)"
readonly REPO_ROOT="${CI_WORKSPACE:-${REPO_ROOT_DEFAULT}}"

cd "${REPO_ROOT}"

if [[ "${CI_XCODE_CLOUD:-}" != "TRUE" ]]; then
  echo "Skipping ci_pre_xcodebuild.sh outside Xcode Cloud."
  exit 0
fi

echo "==> Xcode Cloud pre-xcodebuild gate"
"${REPO_ROOT}/scripts/dev/package-test.sh"
