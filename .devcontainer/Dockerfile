ARG VARIANT="22.04"
FROM mcr.microsoft.com/devcontainers/base:ubuntu-${VARIANT}

ENV DEBIAN_FRONTEND=noninteractive

# Install required packages for Firefox GUI, Xvfb, x11vnc, noVNC and helpers
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    wget curl ca-certificates gnupg2 git build-essential \
    xvfb x11vnc websockify novnc fluxbox imagemagick x11-utils xauth \
    python3 python3-pip python3-venv \
    libgtk-3-0 libdbus-glib-1-2 libx11-xcb1 libasound2 libxcomposite1 libxdamage1 libxrandr2 libxss1 libxcb1 \
    libnss3 libgconf-2-4 libatk1.0-0 libatk-bridge2.0-0 libgdk-pixbuf2.0-0 libxtst6 fonts-liberation \
    bzip2 tar unzip \
  && pip3 install --no-cache-dir selenium \
  && apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/*

# Create logs dir and repo will mount workspace at /workspace
RUN mkdir -p /workspace/logs

WORKDIR /workspace
