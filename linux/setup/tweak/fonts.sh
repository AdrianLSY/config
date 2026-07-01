#!/bin/bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FONT_DIR="$HOME/.local/share/fonts"

if [[ -d "$FONT_DIR" ]]; then
	cp -rf $DIR/fonts/* "$FONT_DIR"
else
	mkdir -p "$FONT_DIR"
	cp -rf $DIR/fonts/* "$FONT_DIR"
fi

# Rebuild font cache
fc-cache
