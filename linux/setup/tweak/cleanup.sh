#!/bin/bash
set -e

sudo pacman -Rns --noconfirm $(pacman -Qtdq) > /dev/null || true
sudo pacman -Sc --noconfirm
yay -Yc --noconfirm
yay -Sc --noconfirm
flatpak uninstall --unused -y
