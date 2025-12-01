# Firefox (project-local) — installer & performance tweaks for Linux

This project contains scripts that download the latest Firefox release (linux64) into the repository and configure a tuned profile to maximize performance (WebRender, higher content processes, fewer disk I/O). The installer is local (no sudo) and intended for sandboxed environments such as Replit or local user installs.

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

Replit-specific suggestions
- Keep background processes to a minimum and avoid unnecessary build tasks while running the browser.
- Use the `check-processes.sh` helper if you want to inspect resource usage.

CI / manual run notes
 - To run the GitHub Actions workflow manually you must provide your repository path to the CLI if you use `gh`.
   Example (replace with your repo):
   ```bash
   # run the workflow on the main branch for owner 'Grag124' and repo 'Firefox-3'
   gh workflow run verify-firefox.yml --repo Grag124/Firefox-3 --ref main
   ```
 - If you see exit code 1 or other errors when running `gh workflow run`, check that the `--repo` parameter is set to your actual GitHub repository (owner/repo), and that you have `gh` authenticated with `gh auth login`.

noVNC / GUI (Replit)
- This project includes a noVNC-backed GUI flow. When you Run the project in Replit the workflow starts `Firefox2/start-gui.sh` which will bootstrap a visible display (Xvfb + fluxbox + x11vnc + websockify/noVNC) and launch Firefox.
- Replit exposes the noVNC web UI on port 6080. If x11vnc started successfully, the RFB endpoint will be available on port 5900 as well — so both are available depending on what you need:

  - noVNC web view (preferred): http://<your-repl-url>:6080
  - RFB/VNC client (direct): connect to <your-repl-host>:5900 with a VNC client (if allowed by your environment)

Make sure `.replit` includes the ports mapping for 6080 and 5900 (this repo already has them configured). If you still see a blank screen in noVNC, check these logs in the repository's `logs/` directory via the Replit shell:

- logs/xvfb.log
- logs/fluxbox.log
- logs/x11vnc.log
- logs/websockify.log
- logs/firefox.log
- logs/start-gui.log

If any required binary is missing (websockify, x11vnc, fluxbox, Xvfb), add it to the `nix.packages` list in `.replit` and re-run the project.

Example `.replit` snippet to ensure noVNC works (add the missing packages to the `packages` array):

packages = ["curl", "fluxbox", "novnc", "x11vnc", "websockify", "imagemagick", "xterm", "xorg.xorgserver", "xvfb-run"]

If you're running locally and want a one-line fix (requires sudo) run:

```bash
sudo bash scripts/fix-env.sh
```

After installing packages (either on Replit by rebuilding the environment or locally via the above), re-run the GUI start:

```bash
bash Firefox2/start-gui.sh
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
