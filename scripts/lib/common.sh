#!/usr/bin/env bash
set -euo pipefail

if [[ "${RBT_COMMON_SH_LOADED:-0}" == "1" ]]; then
  return
fi
readonly RBT_COMMON_SH_LOADED=1

readonly RBT_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly RBT_REPO_ROOT="$(cd "${RBT_LIB_DIR}/../.." && pwd)"

readonly RBT_PROJECT="RoseBudThorn.xcodeproj"
readonly RBT_SCHEME_UNIVERSAL="RoseBudThorn Universal"
readonly RBT_DEST_IOS_SIMULATOR="generic/platform=iOS Simulator"
readonly RBT_DEST_MAC_CATALYST="platform=macOS,variant=Mac Catalyst"
readonly RBT_DEST_UI_SMOKE="platform=iOS Simulator,name=iPhone 17"
readonly RBT_UI_SMOKE_TEST_ID="RoseBudThornUITests/RoseBudThornUITests/testFirstLaunchShowsOnboardingThenSkipOpensToday"

readonly RBT_CACHE_ROOT="${RBT_CACHE_ROOT:-${TMPDIR:-/tmp}/rosebudthorn-dev-cache}"
readonly RBT_MODULE_CACHE_PATH="${RBT_MODULE_CACHE_PATH:-${RBT_CACHE_ROOT}/ModuleCache}"
readonly RBT_SWIFTPM_CACHE_PATH="${RBT_SWIFTPM_CACHE_PATH:-${RBT_CACHE_ROOT}/SwiftPM}"

mkdir -p "${RBT_MODULE_CACHE_PATH}" "${RBT_SWIFTPM_CACHE_PATH}"

export CLANG_MODULE_CACHE_PATH="${CLANG_MODULE_CACHE_PATH:-${RBT_MODULE_CACHE_PATH}}"
export SWIFTPM_MODULECACHE_OVERRIDE="${SWIFTPM_MODULECACHE_OVERRIDE:-${RBT_MODULE_CACHE_PATH}}"
export SWIFTPM_PACKAGECACHE_PATH="${SWIFTPM_PACKAGECACHE_PATH:-${RBT_SWIFTPM_CACHE_PATH}}"

RBT_SWIFT_STRICT_FLAGS=(
  -Xswiftc -strict-concurrency=complete
  -Xswiftc -warnings-as-errors
)

rbt::repo_root() {
  printf "%s\n" "${RBT_REPO_ROOT}"
}

rbt::cd_repo_root() {
  cd "${RBT_REPO_ROOT}"
}

rbt::require_cmd() {
  local cmd="$1"
  if ! command -v "${cmd}" >/dev/null 2>&1; then
    echo "error: missing required command '${cmd}'" >&2
    exit 1
  fi
}

rbt::run() {
  echo "==> $*"
  "$@"
}
