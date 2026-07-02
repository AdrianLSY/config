#!/bin/bash
set -e

CFG=/usr/share/cachyos-fish-config/cachyos-config.fish

# Only exists on CachyOS — skip cleanly elsewhere (and note the file is
# package-owned, so a cachyos-fish-config update restores the alias until
# the next bootstrap removes it again).
if [ ! -f "$CFG" ]; then
    echo "update: $CFG not found — skipping"
    exit 0
fi

sudo sed -i "/alias update='sudo pacman -Syu'/d" "$CFG"
