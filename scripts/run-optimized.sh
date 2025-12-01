#!/usr/bin/env bash
set -euo pipefail

# Launches the local Firefox with environment tuned for best possible GPU/WeRender usage
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
FIREFOX_BIN="$ROOT_DIR/Firefox2/firefox/firefox"
PROFILE_DIR="$ROOT_DIR/firefox-profile"

if [ ! -x "$FIREFOX_BIN" ]; then
  echo "Firefox not found. Run bash scripts/install-firefox.sh first." >&2
  exit 1
fi

mkdir -p "$PROFILE_DIR"

export MOZ_WEBRENDER=1
export MOZ_ENABLE_WAYLAND=1
export MOZ_ACCELERATED=1
export MOZ_USE_X11=0
export MOZ_X11_EGL=1

echo "Starting optimized Firefox (binary: $FIREFOX_BIN)"
exec "$FIREFOX_BIN" -no-remote -profile "$PROFILE_DIR" "$@"
