#!/bin/bash
set -e

# Counterpart of macos/setup/brew/github.sh — the brew cask "github" IS GitHub Desktop.
winget install --id "GitHub.GitHubDesktop" -e --accept-package-agreements --accept-source-agreements
