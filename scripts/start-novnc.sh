#!/usr/bin/env bash
set -euo pipefail

# start-novnc.sh
# Usage: start-novnc.sh <profile-dir> <firefox-dir> [-- extra firefox args]
# Starts Xvfb, a simple window manager (fluxbox if available), x11vnc, and a websockify/noVNC proxy
# then launches Firefox in the created display. This is intended for use in Replit or similar containers.

PROFILE_DIR="$1"
FIREFOX_DIR="$2"
shift 2 || true

# default display/ports
DISPLAY_NUM=99
DISPLAY=":${DISPLAY_NUM}"
RF_PORT=5900
NOVNC_PORT=6080

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

export DISPLAY
export MOZ_WEBRENDER=1
export MOZ_ENABLE_WAYLAND=1
export MOZ_ACCELERATED=1

LOG_DIR="$ROOT_DIR/logs"
mkdir -p "$LOG_DIR"
XVFB_LOG="$LOG_DIR/xvfb.log"
FLUXBOX_LOG="$LOG_DIR/fluxbox.log"
X11VNC_LOG="$LOG_DIR/x11vnc.log"
WEBSOCKIFY_LOG="$LOG_DIR/websockify.log"
FIREFOX_LOG="$LOG_DIR/firefox.log"

TMP_PIDS=()

cleanup() {
  echo "Shutting down noVNC environment..."
  for p in "${TMP_PIDS[@]}"; do
    if [ -n "$p" ] && ps -p "$p" >/dev/null 2>&1; then
      kill "$p" || true
    fi
  done
  exit 0
}

trap cleanup INT TERM EXIT

echo "Checking for required commands (Xvfb, x11vnc, websockify or python websockify module, fluxbox/openbox)"
MISSING=()
for cmd in Xvfb x11vnc fluxbox websockify python3; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    if [ "$cmd" = "python3" ]; then
      # keep python3 as it may exist but websockify module missing - handled below
      continue
    fi
    MISSING+=("$cmd")
  fi
done

# check python websockify module if websockify binary not present
if ! command -v websockify >/dev/null 2>&1; then
  if ! python3 -c "import websockify" >/dev/null 2>&1; then
    echo "websockify binary not found and python websockify module missing. Attempting to pip install websockify in user space..."
    if python3 -m pip install --user websockify >/dev/null 2>&1; then
      echo "Installed python websockify module in user site-packages. Will try using python -m websockify later."
    else
      MISSING+=("websockify-module-or-binary")
    fi
  fi
fi

if [ ${#MISSING[@]} -ne 0 ]; then
  echo "ERROR: Missing required commands: ${MISSING[*]}" >&2
  echo "If you are running in Replit, add these packages to your .replit nix packages: websockify x11vnc novnc fluxbox imagemagick" >&2
  echo "Example .replit entry: packages = [\"websockify\" \"x11vnc\" \"novnc\" \"fluxbox\" \"imagemagick\"]" >&2
  echo "If you're running locally on Ubuntu/Debian/Fedora/Arch you can try the helper script: sudo bash scripts/fix-env.sh" >&2
  exit 3
fi

echo "Starting virtual X display on $DISPLAY (log: $XVFB_LOG)"
Xvfb "$DISPLAY" -screen 0 1920x1080x24 -nolisten tcp >"$XVFB_LOG" 2>&1 &
TMP_PIDS+=("$!")

sleep 0.5

# Start a lightweight window manager if available
if command -v fluxbox >/dev/null 2>&1; then
  echo "Starting fluxbox"
  fluxbox >"$FLUXBOX_LOG" 2>&1 &
  TMP_PIDS+=("$!")
elif command -v openbox >/dev/null 2>&1; then
  echo "Starting openbox"
  openbox >"$FLUXBOX_LOG" 2>&1 &
  TMP_PIDS+=("$!")
else
  echo "No fluxbox/openbox found, continuing without a window manager"
fi

sleep 0.5

# Start x11vnc (serves the X display on $RF_PORT)
if command -v x11vnc >/dev/null 2>&1; then
  echo "Starting x11vnc on port $RF_PORT"
  # -forever keeps it running, -shared allows multiple clients, -noxdamage might help stability
  x11vnc -display "$DISPLAY" -forever -shared -noxdamage -rfbport "$RF_PORT" -quiet >"$X11VNC_LOG" 2>&1 &
  TMP_PIDS+=("$!")
else
  echo "x11vnc not found — you need x11vnc installed for noVNC access" >&2
fi

sleep 0.5

# Try to start websockify / noVNC proxy so we can view the display in a browser via http://localhost:6080
start_websockify() {
  if command -v websockify >/dev/null 2>&1; then
    echo "Starting websockify (websocket proxy)"
    websockify --web /usr/share/novnc --bind-tcp=0.0.0.0 "$NOVNC_PORT" localhost:"$RF_PORT" >"$WEBSOCKIFY_LOG" 2>&1 &
    TMP_PIDS+=("$!")
    return 0
  fi

  # try python module
  if python3 -c "import websockify" >/dev/null 2>&1; then
    echo "Starting websockify as python module"
    python3 -m websockify --bind-tcp=0.0.0.0 --web /usr/share/novnc "$NOVNC_PORT" localhost:"$RF_PORT" >"$WEBSOCKIFY_LOG" 2>&1 &
    TMP_PIDS+=("$!")
    return 0
  fi

  # try novnc utils proxy (if novnc packaged differently)
  if [ -x "/usr/share/novnc/utils/novnc_proxy" ]; then
    echo "Starting novnc_proxy"
    /usr/share/novnc/utils/novnc_proxy --vnc localhost:"$RF_PORT" --listen "$NOVNC_PORT" --web /usr/share/novnc >"$WEBSOCKIFY_LOG" 2>&1 &
    TMP_PIDS+=("$!")
    return 0
  fi

  echo "websockify/noVNC proxy not found; you can still access the display with an RFB client on port $RF_PORT" >&2
  return 1
}

start_websockify || true

sleep 0.5

echo "Launching Firefox in display $DISPLAY"
"${FIREFOX_DIR}/firefox" -no-remote -profile "$PROFILE_DIR" "${@}" >"$FIREFOX_LOG" 2>&1 &
TMP_PIDS+=("$!")

echo "Started Firefox (PID ${TMP_PIDS[-1]}). noVNC should be available on port $NOVNC_PORT and RFB on $RF_PORT if websockify/x11vnc started successfully."

# Check status: confirm x11vnc and websockify are listening
sleep 0.5
if ss -ltnp 2>/dev/null | grep -E ":${NOVNC_PORT} |:${RF_PORT}" >/dev/null 2>&1; then
  echo "Services listening on ports (checked):"
  ss -ltnp | grep -E ":${NOVNC_PORT} |:${RF_PORT}" || true
else
  echo "Warning: could not detect listeners on $NOVNC_PORT or $RF_PORT (maybe services failed to start). Check logs in $LOG_DIR (x11vnc.log, websockify.log, firefox.log)" >&2
fi

# Keep the script running so background services stay alive; just wait for Firefox to exit
wait ${TMP_PIDS[-1]}
