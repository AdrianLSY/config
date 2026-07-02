#!/bin/bash
set -e

defaults write com.apple.Finder AppleShowAllFiles true
# Finder may not be running (e.g. bootstrap over SSH) — don't fail the tweak.
killall Finder || true
