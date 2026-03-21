#!/usr/bin/env bash
set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"

rbt::require_cmd swift
rbt::cd_repo_root
rbt::run swift build "${RBT_SWIFT_STRICT_FLAGS[@]}"
