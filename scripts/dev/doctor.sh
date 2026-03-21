#!/usr/bin/env bash
set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"

rbt::require_cmd git
rbt::require_cmd swift
rbt::require_cmd xcodebuild

rbt::cd_repo_root

echo "==> Repository"
echo "root: ${RBT_REPO_ROOT}"
echo "branch: $(git branch --show-current)"

echo "==> Toolchain"
xcodebuild -version
swift --version

echo "==> Project wiring"
if ! xcodebuild -list -project "${RBT_PROJECT}" | grep -q "${RBT_SCHEME_UNIVERSAL}"; then
  echo "error: expected scheme '${RBT_SCHEME_UNIVERSAL}' not found in ${RBT_PROJECT}" >&2
  exit 1
fi

echo "doctor: ok"
