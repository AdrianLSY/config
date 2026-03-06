#!/bin/bash
set -e

sudo pacman -S --noconfirm docker

sudo usermod -aG docker "${SUDO_USER:-$USER}"
sudo systemctl start docker
sudo systemctl enable --now docker
