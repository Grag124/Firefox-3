#!/usr/bin/env bash
set -euo pipefail

cat <<'WARN'
WARNING: This script will attempt to uninstall system Firefox packages.
It requires sudo and will modify your OS packages (apt/dnf/pacman).
Only run it if you are sure you want to remove system Firefox.
WARN

if [ "$EUID" -ne 0 ]; then
  echo "Run as root (sudo) if you want to modify system packages. Exiting." >&2
  exit 2
fi

if command -v apt-get >/dev/null 2>&1; then
  echo "Detected apt-get — attempting to remove firefox and firefox-esr"
  apt-get remove --purge -y firefox firefox-esr || true
  apt-get autoremove -y || true
elif command -v dnf >/dev/null 2>&1; then
  echo "Detected dnf — attempting to remove firefox"
  dnf remove -y firefox || true
elif command -v pacman >/dev/null 2>&1; then
  echo "Detected pacman — attempting to remove firefox"
  pacman -Rns --noconfirm firefox || true
else
  echo "Could not detect supported package manager. Manual uninstall required." >&2
  exit 1
fi

echo "System Firefox packages removed (if present)."
