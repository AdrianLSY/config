#!/bin/bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FONT_DIR="$HOME/.local/share/fonts"

mkdir -p "$FONT_DIR"
cp -rf "$DIR"/fonts/* "$FONT_DIR"

# Rebuild font cache
fc-cache
