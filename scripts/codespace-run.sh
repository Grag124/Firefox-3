#!/usr/bin/env bash
set -euo pipefail

# codespace-run.sh
# Convenience script to install the fastest Firefox channel, set prefs, install geckodriver,
# and start the noVNC-backed Firefox GUI inside a Codespace or similar devcontainer.

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

LOG_FILE="$ROOT_DIR/logs/codespace-run.log"
mkdir -p "$ROOT_DIR/logs"
echo "Preparing Codespace environment..." | tee -a "$LOG_FILE"
chmod +x "$ROOT_DIR/scripts"/*.sh "$ROOT_DIR/Firefox2/start-gui.sh" || true

CHANNEL="${1:-nightly}"
echo "Installing Firefox ($CHANNEL) — logs -> $LOG_FILE" | tee -a "$LOG_FILE"
if ! bash "$ROOT_DIR/scripts/install-firefox.sh" "$CHANNEL" >>"$LOG_FILE" 2>&1; then
	echo "ERROR: install-firefox.sh failed — see $LOG_FILE" | tee -a "$LOG_FILE"
	exit 22
fi

echo "Applying tuned preferences to profile: firefox-profile" | tee -a "$LOG_FILE"
if ! bash "$ROOT_DIR/scripts/apply-prefs.sh" "$ROOT_DIR/firefox-profile" >>"$LOG_FILE" 2>&1; then
	echo "WARN: apply-prefs.sh failed (continuing)" | tee -a "$LOG_FILE"
fi

echo "Installing geckodriver for Selenium verification" | tee -a "$LOG_FILE"
if ! bash "$ROOT_DIR/scripts/install-geckodriver.sh" >>"$LOG_FILE" 2>&1; then
	echo "ERROR: install-geckodriver.sh failed — see $LOG_FILE" | tee -a "$LOG_FILE"
	exit 23
fi

echo "Running headless verification (Selenium) to confirm about:support..." | tee -a "$LOG_FILE"
if ! bash "$ROOT_DIR/scripts/headless-verify.sh" >>"$LOG_FILE" 2>&1; then
	echo "WARN: headless verification failed (continuing) — see $LOG_FILE" | tee -a "$LOG_FILE"
fi

echo "Starting noVNC + Firefox GUI (logs -> $LOG_FILE)" | tee -a "$LOG_FILE"
# Ensure required noVNC dependencies are present; try auto-fix if missing
MISSING=()
for cmd in Xvfb x11vnc websockify fluxbox; do
	if ! command -v "$cmd" >/dev/null 2>&1; then
		MISSING+=("$cmd")
	fi
done
if [ ${#MISSING[@]} -ne 0 ]; then
	echo "Missing noVNC dependencies: ${MISSING[*]} — attempting sudo scripts/fix-env.sh to install" | tee -a "$LOG_FILE"
	if command -v sudo >/dev/null 2>&1; then
		if sudo bash "$ROOT_DIR/scripts/fix-env.sh" >>"$LOG_FILE" 2>&1; then
			echo "Auto-install attempted; re-checking dependencies..." | tee -a "$LOG_FILE"
			MISSING=()
			for cmd in Xvfb x11vnc websockify fluxbox; do
				if ! command -v "$cmd" >/dev/null 2>&1; then
					MISSING+=("$cmd")
				fi
			done
		else
			echo "Auto-install failed — please ensure the required packages are installed (see $LOG_FILE)" | tee -a "$LOG_FILE"
		fi
	else
		echo "sudo not found; cannot auto-install missing packages — please install them manually." | tee -a "$LOG_FILE"
	fi
fi

echo "Checking for shared library dependencies (Firefox)" | tee -a "$LOG_FILE"
if ! bash "$ROOT_DIR/scripts/check-deps.sh" >>"$LOG_FILE" 2>&1; then
	echo "Missing shared libs detected. Attempting to auto-install them via sudo scripts/fix-env.sh" | tee -a "$LOG_FILE"
	if command -v sudo >/dev/null 2>&1; then
		if sudo bash "$ROOT_DIR/scripts/fix-env.sh" >>"$LOG_FILE" 2>&1; then
			echo "fix-env.sh completed (check logs). Re-checking shared libs..." | tee -a "$LOG_FILE"
			if ! bash "$ROOT_DIR/scripts/check-deps.sh" >>"$LOG_FILE" 2>&1; then
				echo "Shared libs still missing after auto-install. Aborting and showing logs." | tee -a "$LOG_FILE"
				sed -n '1,240p' "$LOG_FILE" || true
				exit 25
			fi
		else
			echo "Auto-install of shared libs failed; please rebuild the Codespace devcontainer or install packages manually." | tee -a "$LOG_FILE"
			sed -n '1,240p' "$LOG_FILE" || true
			exit 25
		fi
	else
		echo "sudo not available in this environment — cannot auto-install shared libs. Rebuild the Codespace devcontainer or install packages manually." | tee -a "$LOG_FILE"
		sed -n '1,240p' "$LOG_FILE" || true
		exit 25
	fi
fi

if ! bash "$ROOT_DIR/Firefox2/start-gui.sh" >>"$LOG_FILE" 2>&1 & then
	echo "ERROR: start-gui.sh failed — see $LOG_FILE" | tee -a "$LOG_FILE"
	exit 24
fi

echo "Started (background). View the noVNC web UI on forwarded port 6080 or connect with VNC to port 5900." | tee -a "$LOG_FILE"
