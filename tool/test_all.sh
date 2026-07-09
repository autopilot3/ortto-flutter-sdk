#!/usr/bin/env bash

set -euo pipefail

root_directory="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
packages=(
  ortto_flutter_sdk_platform_interface
  ortto_flutter_sdk_ios
  ortto_flutter_sdk_android
  ortto_flutter_sdk
)

if ! command -v flutter >/dev/null 2>&1; then
  echo "error: flutter is not available on PATH" >&2
  exit 127
fi

for package in "${packages[@]}"; do
  echo
  echo "===== Testing ${package} ====="
  (
    cd "${root_directory}/${package}"
    flutter pub get
    flutter test --reporter expanded "$@"
  )
done

echo
echo "All Flutter package tests passed."
