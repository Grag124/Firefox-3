#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
FIREFOX_BIN="$ROOT_DIR/Firefox2/firefox/firefox"
PROFILE_DIR="$ROOT_DIR/firefox-profile"

if [ -x "$FIREFOX_BIN" ]; then
  echo "Firefox binary found: $FIREFOX_BIN"
  "$FIREFOX_BIN" --version || true
else
  echo "No firefox binary at $FIREFOX_BIN"
  exit 1
fi

if [ -f "$PROFILE_DIR/user.js" ]; then
  echo "Profile prefs file contents:" 
  sed -n '1,120p' "$PROFILE_DIR/user.js" || true
else
  echo "No user.js found in $PROFILE_DIR — teardown or not set up yet"
fi

echo "Check 'about:support' or open Firefox and go to 'About Firefox' to confirm the GUI version and that WebRender is enabled."
