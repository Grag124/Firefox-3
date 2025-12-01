#!/usr/bin/env bash
set -euo pipefail

# Headless verify orchestration: ensures geckodriver & selenium are present then runs verify_about_support.py
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
GECKO="$ROOT_DIR/scripts/bin/geckodriver"
export PATH="$ROOT_DIR/scripts/bin:$PATH"

if [ ! -x "$GECKO" ]; then
  echo "geckodriver not found — installing into scripts/bin"
  bash "$ROOT_DIR/scripts/install-geckodriver.sh"
fi

PY="$(command -v python3 || command -v python)"
if [ -z "$PY" ]; then
  echo "Python not found in PATH" >&2
  exit 2
fi

if ! "$PY" -c "import selenium" >/dev/null 2>&1; then
  echo "Selenium not found — installing selenium"
  # Install system-wide in the step environment so python3 can import it reliably in CI runs
  "$PY" -m pip install --upgrade pip setuptools wheel
  "$PY" -m pip install selenium
fi

echo "Running headless verification..."
"$PY" "$ROOT_DIR/scripts/verify_about_support.py"
