#!/usr/bin/env bash
set -euo pipefail

# check-deps.sh
# Verifies common system shared libs required for Firefox headless/GUI in Linux
# and prints helpful package names to install if missing.

MISSING=()

check_lib() {
  local lib="$1" pkg_hint="$2"
  if ldconfig -p 2>/dev/null | grep -q "$lib"; then
    return 0
  fi
  MISSING+=("$lib ($pkg_hint)")
}

echo "Checking shared libraries required by Firefox..."
check_lib libgtk-3.so.0 "libgtk-3-0"
check_lib libdbus-glib-1.so.2 "libdbus-glib-1-2"
check_lib libx11-xcb.so.1 "libx11-xcb1"
check_lib libasound.so.2 "libasound2"
check_lib libXcomposite.so.1 "libxcomposite1"
check_lib libXdamage.so.1 "libxdamage1"
check_lib libXrandr.so.2 "libxrandr2"
check_lib libxcb.so.1 "libxcb1"

if [ ${#MISSING[@]} -eq 0 ]; then
  echo "All required shared libraries are present."
  exit 0
fi

echo "Missing libraries detected:"
for m in "${MISSING[@]}"; do
  echo "  - $m"
done

echo
echo "Suggested apt packages to install (Ubuntu/Debian):"
echo "  sudo apt-get update && sudo apt-get install -y libgtk-3-0 libdbus-glib-1-2 libx11-xcb1 libasound2 libxcomposite1 libxdamage1 libxrandr2 libxcb1"

exit 3
