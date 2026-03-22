#!/usr/bin/env bash
set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"

rbt::require_cmd xcodebuild
rbt::require_cmd xcrun
rbt::require_cmd swift

rbt::cd_repo_root

readonly OUTPUT_ROOT="${RBT_APP_STORE_ASSETS_DIR:-$(pwd)/AppStoreAssets}"
readonly RAW_ROOT="${OUTPUT_ROOT}/raw"
readonly FINAL_ROOT="${OUTPUT_ROOT}/final"

readonly IPHONE_RAW="${RAW_ROOT}/iphone-6.9"
readonly IPAD_RAW="${RAW_ROOT}/ipad-13"
readonly IPHONE_FINAL="${FINAL_ROOT}/iphone-6.9-1320x2868"
readonly IPAD_FINAL="${FINAL_ROOT}/ipad-13-2064x2752"

readonly IPHONE_RESULT_BUNDLE="${RBT_APP_STORE_IPHONE_RESULT_BUNDLE_PATH:-/tmp/RoseBudThorn-app-store-iphone.xcresult}"
readonly IPAD_RESULT_BUNDLE="${RBT_APP_STORE_IPAD_RESULT_BUNDLE_PATH:-/tmp/RoseBudThorn-app-store-ipad.xcresult}"
readonly SCREENSHOT_TEST_ID="RoseBudThornUITests/RoseBudThornUITests/testCaptureAppStoreScreenshots"

ensure_clean_result_bundle() {
  local bundle_path="$1"
  if [[ -e "${bundle_path}" ]]; then
    case "${bundle_path}" in
      *.xcresult)
        rbt::run rm -rf "${bundle_path}"
        ;;
      *)
        echo "error: refusing to remove non-xcresult path: ${bundle_path}" >&2
        exit 1
        ;;
    esac
  fi
}

reset_directory() {
  local dir_path="$1"
  if [[ -e "${dir_path}" ]]; then
    case "${dir_path}" in
      "${OUTPUT_ROOT}"/*)
        rbt::run rm -rf "${dir_path}"
        ;;
      *)
        echo "error: refusing to remove directory outside ${OUTPUT_ROOT}: ${dir_path}" >&2
        exit 1
        ;;
    esac
  fi
  rbt::run mkdir -p "${dir_path}"
}

run_capture() {
  local destination="$1"
  local result_bundle="$2"

  ensure_clean_result_bundle "${result_bundle}"
  rbt::run xcodebuild \
    -project "${RBT_PROJECT}" \
    -scheme "${RBT_SCHEME_UNIVERSAL}" \
    -destination "${destination}" \
    -parallel-testing-enabled NO \
    -resultBundlePath "${result_bundle}" \
    -only-testing:"${SCREENSHOT_TEST_ID}" \
    test
}

export_attachments() {
  local result_bundle="$1"
  local output_dir="$2"

  reset_directory "${output_dir}"
  rbt::run xcrun xcresulttool export attachments \
    --path "${result_bundle}" \
    --output-path "${output_dir}"
}

compose_assets() {
  local raw_dir="$1"
  local out_dir="$2"
  local device_kind="$3"

  reset_directory "${out_dir}"
  rbt::run swift scripts/dev/app-store-compose.swift \
    --input-dir "${raw_dir}" \
    --output-dir "${out_dir}" \
    --device "${device_kind}"
}

rbt::run mkdir -p "${OUTPUT_ROOT}"

run_capture "platform=iOS Simulator,name=iPhone 17 Pro Max,OS=26.2" "${IPHONE_RESULT_BUNDLE}"
run_capture "platform=iOS Simulator,name=iPad Pro 13-inch (M5),OS=26.2" "${IPAD_RESULT_BUNDLE}"

export_attachments "${IPHONE_RESULT_BUNDLE}" "${IPHONE_RAW}"
export_attachments "${IPAD_RESULT_BUNDLE}" "${IPAD_RAW}"

compose_assets "${IPHONE_RAW}" "${IPHONE_FINAL}" iphone
compose_assets "${IPAD_RAW}" "${IPAD_FINAL}" ipad

echo
echo "Generated App Store assets:"
echo "  iPhone 6.9\" set: ${IPHONE_FINAL}"
echo "  iPad 13\" set:    ${IPAD_FINAL}"
