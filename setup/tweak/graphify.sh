#!/bin/bash
set -e

# Install graphify, the knowledge-graph CLI used by the .claude/ skill + hooks.
#
# graphify isn't a Homebrew package, so it can't live in setup/brew/. It's a
# uv-managed tool, and uv is installed by setup/brew/uv.sh — which runs before
# this tweak (ORDER=brew then tweak), so uv is already on PATH here.
#
# Quirk: the PyPI package is `graphifyy` (double-y); the CLI it installs is
# `graphify` (single-y), alongside graphify-mcp, into ~/.local/bin.
#
# `uv tool install` is idempotent, but skip cleanly when already present to keep
# bootstrap logs quiet and avoid a needless resolve on every run.
if uv tool list 2>/dev/null | grep -q '^graphifyy'; then
    echo "graphify already installed (graphifyy). Skipping."
else
    uv tool install graphifyy
fi
