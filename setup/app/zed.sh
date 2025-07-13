#!/bin/bash
set -e

curl -fsSL https://zed.dev/install.sh | sh
fish -c 'fish_add_path -U ~/.local/bin' || true
