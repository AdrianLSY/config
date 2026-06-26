#!/bin/bash
set -e

# timescale/tap is Timescale's third-party tap (not mine, unlike adrianlsy/tap).
# Homebrew treats every non-official tap as "untrusted" and won't load its cask,
# so trust it to install on a fresh machine. Trusting it means trusting
# Timescale's tap contents — fine for their official CLI. Idempotent.
brew tap timescale/tap
brew trust --tap timescale/tap

brew install --cask timescale/tap/tiger-cli
