#!/bin/bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

sudo install -Dm644 "$DIR/keyd/default.conf" /etc/keyd/default.conf

sudo systemctl enable --now keyd
sudo systemctl restart keyd
