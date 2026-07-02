#!/bin/bash
set -e

# Covers both macos/setup/brew/docker-desktop.sh AND docker.sh: on Windows the
# docker CLI has no standalone package — Docker Desktop bundles it.
winget install --id "Docker.DockerDesktop" -e --accept-package-agreements --accept-source-agreements
