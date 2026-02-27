#!/usr/bin/env bash
set -euo pipefail

swift format --in-place --recursive Sources Tests 2>/dev/null || true
swift test
