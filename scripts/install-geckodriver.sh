#!/usr/bin/env bash
set -euo pipefail

# Downloads latest geckodriver linux64 binary into scripts/geckodriver
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DEST_DIR="$ROOT_DIR/scripts/bin"
mkdir -p "$DEST_DIR"

URL="https://github.com/mozilla/geckodriver/releases/latest/download/geckodriver-v0.37.0-linux64.tar.gz"
TMPDIR=$(mktemp -d)
pushd "$TMPDIR" >/dev/null
echo "Downloading geckodriver from $URL"
curl -L --fail -o geckodriver.tar.gz "$URL"
tar -xzf geckodriver.tar.gz
chmod +x geckodriver
mv geckodriver "$DEST_DIR/"
popd >/dev/null
rm -rf "$TMPDIR"

echo "Installed geckodriver to $DEST_DIR/geckodriver"
