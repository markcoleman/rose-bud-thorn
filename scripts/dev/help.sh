#!/usr/bin/env bash
set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"

cat <<'EOF'
RoseBudThorn developer commands

Core checks:
  scripts/dev/package-build.sh        Build Swift package with strict concurrency warnings as errors.
  scripts/dev/package-test.sh         Run Swift package tests in parallel with strict flags.
  scripts/dev/app-build-ios.sh        Build universal app for iOS simulator.
  scripts/dev/app-build-maccatalyst.sh Build universal app for Mac Catalyst.

Workflow helpers:
  scripts/dev/bootstrap.sh            Resolve package dependencies.
  scripts/dev/doctor.sh               Validate local toolchain and project wiring.
  scripts/dev/preflight.sh            Run package checks and app builds.

Usage examples:
  scripts/dev/doctor.sh
  scripts/dev/bootstrap.sh
  scripts/dev/preflight.sh --package-only
EOF
