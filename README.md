# Firefox (project-local) — installer & performance tweaks for Linux

This project contains scripts that download the latest Firefox release (linux64) into the repository and configure a tuned profile to maximize performance (WebRender, higher content processes, fewer disk I/O). The installer is local (no sudo) and intended for user installs or to run inside containers such as GitHub Codespaces.

Quick commands
- Install latest release (default):
  ```bash
  bash scripts/install-firefox.sh
  ```

- Install beta channel (faster, less stable):
  ```bash
  bash scripts/install-firefox.sh beta
  ```

- Install nightly channel (bleeding edge, fastest; use with caution):
  ```bash
  bash scripts/install-firefox.sh nightly
  ```
- Create a tuned profile and apply prefs:
  ```bash
  bash scripts/apply-prefs.sh firefox-profile
  ```
- Launch Firefox (with local profile):
  ```bash
  bash Firefox2/start-gui.sh
  ```
 - Verify the install and the prefs file:
  ```bash
  bash scripts/verify-install.sh
  ```

 - Headless verification (uses geckodriver + selenium to load about:support):
  ```bash
  bash scripts/headless-verify.sh
  ```

About the preferences we apply
- network.http.max-persistent-connections-per-server = 8
- gfx.webrender.all = true
- dom.ipc.processCount = 4
- browser.cache.disk.enable = false

Notes & safety
- The local install avoids touching system packages — no sudo required.
- Nightly builds are the most recent and can provide the newest rendering and WebRender improvements, but they're less stable. Use `nightly` only if you want the absolute latest optimizations.
- If you *do* want to replace a system install (apt/dnf), see `scripts/uninstall-old.sh` — be careful, it requires sudo and will remove OS packages.

Codespaces / local development

- This repository includes a Codespaces devcontainer (`.devcontainer/Dockerfile` and `.devcontainer/devcontainer.json`) that installs the system packages required for the noVNC + Firefox GUI flow (Xvfb, x11vnc, websockify, noVNC, fluxbox, imagemagick). Open this repository in GitHub Codespaces and the container will install them for you.

Troubleshooting & Codespace rebuild
----------------------------------

If you open the repo in GitHub Codespaces but see failures such as missing shared libraries (libgtk-3.so.0) or missing X/VNC tools (Xvfb, x11vnc, websockify), please rebuild the devcontainer so the container image installs the required system packages.

In the Codespaces UI choose "Codespaces -> Rebuild Container" or run the command palette: "Remote-Containers: Rebuild Container". After a rebuild run the one-shot setup again:

```bash
# Rebuild devcontainer via the UI, then re-run the one-shot setup
bash scripts/codespace-run.sh release
```

If you are not using Codespaces and are running locally, you can try the provided fix helper (needs sudo):

```bash
sudo bash scripts/fix-env.sh
```


- After the devcontainer finishes building (or after you install dependencies locally), run these commands in the Codespace shell to start the GUI:

```bash
# make scripts and start script executable
chmod +x scripts/*.sh Firefox2/start-gui.sh

# ensure tuned profile is in place
bash scripts/apply-prefs.sh firefox-profile

# optionally set your VNC password
export VNC_PASSWORD='choose-a-strong-password'

# start the noVNC-backed Firefox GUI (for Codespaces the forwarded ports 6080 and 5900 are exposed)
bash Firefox2/start-gui.sh
```

- After start, view the noVNC page at http://localhost:6080/vnc.html (in Codespaces use the forwarded port to your browser) or connect with a VNC client to port 5900. Logs are written to `./logs/` for inspection (xvfb.log, x11vnc.log, websockify.log, firefox.log, start-gui.log).

One-shot setup and run (Codespaces)
 - To run everything in one command inside Codespaces (install, apply prefs, geckodriver, start GUI):

```bash
# runs install-firefox (nightly by default), apply-prefs, installs geckodriver, and launches noVNC
bash scripts/codespace-run.sh
# or use release/beta channel: bash scripts/codespace-run.sh release
```

If you're running locally and want a one-line fix (requires sudo) run:

```bash
sudo bash scripts/fix-env.sh
```

After installing packages (either by rebuilding the Codespaces devcontainer or locally via the above), re-run the GUI start:

```bash
bash Firefox2/start-gui.sh
```

VNC password
 - For safety the noVNC flow now creates a VNC password automatically on first run and writes it to `logs/.vncpass`. You can set the password explicitly by setting the `VNC_PASSWORD` environment variable before starting `start-gui.sh`, for example:
  ```bash
  export VNC_PASSWORD='my-secret'
  bash Firefox2/start-gui.sh
  ```
 - If you don't set `VNC_PASSWORD`, a random 12 character password will be generated and written to `logs/.vncpass` (permission 600). Use that when connecting with a VNC client.
```

CI
- The GitHub Actions workflow `verify-firefox.yml` now starts a noVNC-backed X display in CI (Xvfb + x11vnc + websockify) and launches Firefox to verify the install. Logs and artifacts are uploaded so you can inspect execution from the Actions UI.

CI / automated runs (GitHub Actions)
 - This repository includes an automated workflow at `.github/workflows/verify-firefox.yml` that runs on push to `main` or by manual trigger.
 - The workflow will install a chosen Firefox channel (the workflow currently installs Nightly), apply the tuned prefs, attempt an optimized headless launch via Xvfb, and run the headless verification (geckodriver + Selenium).
 - To run it manually from your machine you can use the GitHub CLI:
   ```bash
   gh workflow run verify-firefox.yml --repo <owner>/<repo> --ref main
   ```
 - After the workflow runs you can download logs/artifacts from the workflow run in the Actions UI.
