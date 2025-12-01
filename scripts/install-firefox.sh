#!/usr/bin/env bash
set -euo pipefail

# install-firefox.sh
# Downloads Firefox (linux64) and installs it into the project Firefox2/firefox directory.
# Usage: install-firefox.sh [channel]
# channel: release (default) | beta | nightly

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TARGET_DIR="$ROOT_DIR/Firefox2/firefox"
TMPDIR="$(mktemp -d)"

echo "Installing Firefox into $TARGET_DIR"

CHANNEL="${1:-release}"
case "$CHANNEL" in
  release)
    PRODUCT="firefox-latest"
    ;;
  beta)
    PRODUCT="firefox-beta-latest"
    ;;
  nightly)
    PRODUCT="firefox-nightly-latest"
    ;;
  *)
    echo "Unknown channel '$CHANNEL' — use release|beta|nightly" >&2
    exit 2
    ;;
esac

DOWNLOAD_URL="https://download.mozilla.org/?product=${PRODUCT}&os=linux64&lang=en-US"

pushd "$TMPDIR" >/dev/null
echo "Downloading latest Firefox from $DOWNLOAD_URL"
# retry up to 3 times for network hiccups
RETRY=0
until [ $RETRY -ge 3 ]
do
  if curl -L --fail -o firefox.tar "${DOWNLOAD_URL}"; then
    break
  fi
  RETRY=$((RETRY+1))
  echo "Download failed (attempt $RETRY) — retrying in 2s..."
  sleep 2
done
if [ $RETRY -ge 3 ]; then
  echo "Failed to download Firefox after multiple attempts (url: $DOWNLOAD_URL)" >&2
  exit 22
fi

echo "Trying to extract archive (auto-detecting format)..."
# Try common compression formats until one works
if tar -xJf firefox.tar -C . 2>/dev/null; then
  EXTRACT_OK=1
elif tar -xjf firefox.tar -C . 2>/dev/null; then
  EXTRACT_OK=1
elif tar -xzf firefox.tar -C . 2>/dev/null; then
  EXTRACT_OK=1
else
  echo "Failed to extract firefox archive — unknown compression format" >&2
  exit 1
fi

EXTRACTED_DIR=$(find . -maxdepth 1 -type d -name 'firefox*' -printf '%P' | head -n1)
if [ -z "$EXTRACTED_DIR" ]; then
  echo "Failed to find extracted Firefox directory" >&2
  exit 1
fi

rm -rf "$TARGET_DIR" && mkdir -p "$TARGET_DIR"
cp -r "$EXTRACTED_DIR"/* "$TARGET_DIR/"
chmod +x "$TARGET_DIR/firefox"

popd >/dev/null
rm -rf "$TMPDIR"

echo "Installed Firefox to $TARGET_DIR"
echo "Run: $TARGET_DIR/firefox --version to verify"
