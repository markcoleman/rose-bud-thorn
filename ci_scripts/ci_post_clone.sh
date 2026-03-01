#!/bin/sh
set -euo pipefail

if [ -n "${CI_WORKSPACE:-}" ]; then
  cd "${CI_WORKSPACE}"
fi

if [ "${CI_XCODE_CLOUD:-}" != "TRUE" ]; then
  echo "Skipping ci_post_clone.sh outside Xcode Cloud."
  exit 0
fi

CI_CACHE_ROOT="${TMPDIR:-/tmp}/rosebudthorn-ci-cache"
mkdir -p "${CI_CACHE_ROOT}/ModuleCache"
export CLANG_MODULE_CACHE_PATH="${CI_CACHE_ROOT}/ModuleCache"
export SWIFTPM_MODULECACHE_OVERRIDE="${CI_CACHE_ROOT}/ModuleCache"

echo "==> Toolchain"
xcodebuild -version
swift --version

echo "==> Resolving Swift package dependencies"
swift package resolve --disable-sandbox
