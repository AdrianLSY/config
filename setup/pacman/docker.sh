#!/bin/bash
set -e

sudo pacman -S --noconfirm docker
sudo usermod -aG docker "${SUDO_USER:-$USER}"
