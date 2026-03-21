#!/usr/bin/env bash
set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"

rbt::require_cmd xcodebuild
rbt::cd_repo_root
rbt::run xcodebuild \
  -project "${RBT_PROJECT}" \
  -scheme "${RBT_SCHEME_UNIVERSAL}" \
  -destination "${RBT_DEST_IOS_SIMULATOR}" \
  -configuration Debug \
  CODE_SIGNING_ALLOWED=NO \
  build
