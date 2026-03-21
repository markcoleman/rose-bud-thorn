#!/usr/bin/env bash
set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"

rbt::require_cmd xcodebuild
rbt::cd_repo_root

readonly RESULT_BUNDLE_PATH="${RBT_UI_FULL_RESULT_BUNDLE_PATH:-/tmp/RoseBudThorn-ui-nightly.xcresult}"

if [[ -e "${RESULT_BUNDLE_PATH}" ]]; then
  case "${RESULT_BUNDLE_PATH}" in
    *.xcresult)
      rbt::run rm -rf "${RESULT_BUNDLE_PATH}"
      ;;
    *)
      echo "error: refusing to remove non-xcresult path: ${RESULT_BUNDLE_PATH}" >&2
      exit 1
      ;;
  esac
fi

rbt::run xcodebuild \
  -project "${RBT_PROJECT}" \
  -scheme "${RBT_SCHEME_UNIVERSAL}" \
  -destination "${RBT_DEST_UI_SMOKE}" \
  -parallel-testing-enabled NO \
  -resultBundlePath "${RESULT_BUNDLE_PATH}" \
  test
