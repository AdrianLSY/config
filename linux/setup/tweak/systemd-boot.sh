#!/bin/bash
set -e

# Skips systemd-boot os selector
LOADER=/boot/loader/loader.conf

# Not every machine boots via systemd-boot — skip cleanly when absent.
if [ ! -f "$LOADER" ]; then
    echo "systemd-boot: $LOADER not found — skipping"
    exit 0
fi

sudo sed -i '/^timeout /d' "$LOADER" && echo 'timeout 0' | sudo tee -a "$LOADER" > /dev/null
