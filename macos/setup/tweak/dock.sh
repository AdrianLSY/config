#!/bin/bash
set -e

# Remove dock show/hide delay
defaults write com.apple.dock autohide-delay -float 0
defaults write com.apple.dock autohide-time-modifier -float 0.1
# Dock may not be running (e.g. bootstrap over SSH) — don't fail the tweak.
killall Dock || true
