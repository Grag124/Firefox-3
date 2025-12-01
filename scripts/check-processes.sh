#!/usr/bin/env bash
set -euo pipefail

echo "Listing processes that might consume resources (sorted by memory)"
ps aux --sort=-%mem | head -n 20

echo "---
If you see non-essential services consuming lots of RAM/CPU you can disable them for better Firefox performance in the environment where you control services. In Codespaces or other containers, minimize background tasks and other heavy build tools while running the browser."
