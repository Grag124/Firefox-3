#!/usr/bin/env bash
set -euo pipefail

# Downloads latest geckodriver linux64 binary into scripts/geckodriver
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DEST_DIR="$ROOT_DIR/scripts/bin"
mkdir -p "$DEST_DIR"

TMPDIR=$(mktemp -d)
pushd "$TMPDIR" >/dev/null
echo "Resolving latest geckodriver release from GitHub API"
# Try GitHub API first (more reliable) to find linux64 asset
API_JSON=$(curl -sSf "https://api.github.com/repos/mozilla/geckodriver/releases/latest") || API_JSON=""
ASSET_URL=""
if [ -n "$API_JSON" ]; then
	ASSET_URL=$(echo "$API_JSON" | grep -Eo 'https://[^" ]+linux64\.tar\.gz' | head -n1 || true)
fi

if [ -z "$ASSET_URL" ]; then
	# Fallback to common release candidate names (try a generic redirect if available)
	CANDIDATES=("geckodriver-linux64.tar.gz" "geckodriver-v0.40.0-linux64.tar.gz" "geckodriver-v0.39.0-linux64.tar.gz")
	for name in "${CANDIDATES[@]}"; do
		tryurl="https://github.com/mozilla/geckodriver/releases/latest/download/$name"
		if curl -sSf -I "$tryurl" >/dev/null 2>&1; then
			ASSET_URL="$tryurl"
			break
		fi
	done
fi

if [ -z "$ASSET_URL" ]; then
	echo "Failed to determine geckodriver download URL from GitHub. Aborting." >&2
	popd >/dev/null
	rm -rf "$TMPDIR"
	exit 22
fi

echo "Downloading geckodriver from $ASSET_URL"
# retry a few times
RETRY=0
until [ $RETRY -ge 3 ]
do
	if curl -L --fail -o geckodriver.tar.gz "$ASSET_URL"; then
		break
	fi
	RETRY=$((RETRY+1))
	echo "geckodriver download failed (attempt $RETRY) — retrying in 2s..."
	sleep 2
done
if [ $RETRY -ge 3 ]; then
	echo "Failed to download geckodriver after multiple attempts (url: $ASSET_URL)" >&2
	popd >/dev/null
	rm -rf "$TMPDIR"
	exit 22
fi
tar -xzf geckodriver.tar.gz
if [ ! -x geckodriver ]; then
	echo "geckodriver binary not found in archive" >&2
	popd >/dev/null
	rm -rf "$TMPDIR"
	exit 23
fi
chmod +x geckodriver
mv geckodriver "$DEST_DIR/"
popd >/dev/null
rm -rf "$TMPDIR"

echo "Installed geckodriver to $DEST_DIR/geckodriver"
