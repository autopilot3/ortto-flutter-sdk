#!/usr/bin/env bash
# Runs flutter analyze for one package. If the agent has no flutter on PATH,
# downloads a pinned Flutter SDK into the agent's cache first (needs curl,
# git, unzip; xz on Linux). Invoke from the repo root:
#   .buildkite/steps/test-package.sh <package-dir>
set -euo pipefail

package="${1:?usage: test-package.sh <package-dir>}"

FLUTTER_VERSION="${FLUTTER_VERSION:-3.44.0}"
CACHE_ROOT="${FLUTTER_CACHE_DIR:-$HOME/.cache}"
FLUTTER_HOME="$CACHE_ROOT/flutter-$FLUTTER_VERSION"

install_flutter() {
  local archive url tmp
  case "$(uname -s)-$(uname -m)" in
    Linux-x86_64)  archive="flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" ; url="linux/${archive}" ;;
    Darwin-arm64)  archive="flutter_macos_arm64_${FLUTTER_VERSION}-stable.zip" ; url="macos/${archive}" ;;
    Darwin-x86_64) archive="flutter_macos_${FLUTTER_VERSION}-stable.zip" ; url="macos/${archive}" ;;
    *) echo "no Flutter artifact for $(uname -s)/$(uname -m)" >&2; exit 1 ;;
  esac

  echo "--- :inbox_tray: Installing Flutter ${FLUTTER_VERSION} ($(uname -s)/$(uname -m))"
  tmp="$(mktemp -d)"
  curl -fsSL "https://storage.googleapis.com/flutter_infra_release/releases/stable/${url}" -o "$tmp/$archive"
  case "$archive" in
    *.tar.xz) tar -xf "$tmp/$archive" -C "$tmp" --no-same-owner ;;
    *.zip)    unzip -q "$tmp/$archive" -d "$tmp" ;;
  esac
  mkdir -p "$CACHE_ROOT"
  # Atomic move; if a concurrent matrix step won the race, keep its install.
  if ! mv "$tmp/flutter" "$FLUTTER_HOME" 2>/dev/null; then
    [ -x "$FLUTTER_HOME/bin/flutter" ] || { echo "flutter install failed" >&2; exit 1; }
  fi
  rm -rf "$tmp"
}

if ! command -v flutter >/dev/null 2>&1; then
  [ -x "$FLUTTER_HOME/bin/flutter" ] || install_flutter
  export PATH="$FLUTTER_HOME/bin:$PATH"
  # The SDK is a git repo; if a prior extraction left it owned by another
  # uid (tar as root), git refuses with "dubious ownership". Env-only
  # exception — nothing persisted on the agent.
  export GIT_CONFIG_COUNT=1
  export GIT_CONFIG_KEY_0="safe.directory"
  export GIT_CONFIG_VALUE_0="$FLUTTER_HOME"
fi

echo "--- :dart: ${package}: analyze"
cd "$package"
flutter --version
flutter pub get
flutter analyze

# TODO(#23): re-enable once the package test suites land — lint-only until then.
# flutter test --reporter expanded
echo "^^^ +++"
echo ":warning: flutter test is DISABLED pending #23 — this build verifies analyze only"
