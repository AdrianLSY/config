#!/bin/bash
set -e

sudo sed -i "/alias update='sudo pacman -Syu'/d" /usr/share/cachyos-fish-config/cachyos-config.fish
