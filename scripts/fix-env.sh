#!/usr/bin/env bash
set -euo pipefail

cat <<'NOTE'
This helper will attempt to install missing packages required by the noVNC flow
so you can run `bash Firefox2/start-gui.sh` locally. It requires sudo/root.

Supported package managers: apt (Debian/Ubuntu), dnf (Fedora/RHEL), pacman (Arch)

Packages attempted: xvfb x11vnc websockify novnc fluxbox imagemagick

NOTE

if [ "$EUID" -ne 0 ]; then
  echo "This script needs sudo. Re-run as: sudo $0" >&2
  exit 2
fi

if command -v apt-get >/dev/null 2>&1; then
  apt-get update -y
  apt-get install -y xvfb x11vnc websockify novnc fluxbox imagemagick || true
  echo "Installed packages via apt-get (if available)."
  exit 0
fi

if command -v dnf >/dev/null 2>&1; then
  dnf install -y xorg-x11-server-Xvfb x11vnc python3-websockify novnc fluxbox imagemagick || true
  echo "Attempted installation via dnf."
  exit 0
fi

if command -v pacman >/dev/null 2>&1; then
  pacman -Syu --noconfirm xorg-server-xvfb x11vnc websockify noVNC fluxbox imagemagick || true
  echo "Attempted installation via pacman."
  exit 0
fi

echo "No supported package manager found. If you are running on Replit, add these packages to the .replit file's nix.packages array and rebuild the environment: websockify x11vnc novnc fluxbox imagemagick" >&2
exit 3
