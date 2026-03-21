#!/usr/bin/env bash
set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"

rbt::require_cmd git
rbt::cd_repo_root

readonly HOOKS_PATH_REL=".githooks"
readonly HOOKS_PATH_ABS="${RBT_REPO_ROOT}/${HOOKS_PATH_REL}"

if [[ ! -d "${HOOKS_PATH_ABS}" ]]; then
  echo "error: expected hooks directory at ${HOOKS_PATH_ABS}" >&2
  exit 1
fi

git config core.hooksPath "${HOOKS_PATH_REL}"
echo "hooks: installed ${HOOKS_PATH_REL} as core.hooksPath"
echo "hooks: pre-push will run scripts/dev/preflight.sh --package-only"
echo "hooks: set RBT_SKIP_PRE_PUSH=1 to skip once"
