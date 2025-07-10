#!/bin/bash
set -e

sudo pacman -Rns $(pacman -Qtdq) 2>/dev/null
sudo pacman -Sc --noconfirm
yay -Yc --noconfirm
yay -Sc --noconfirm
flatpak uninstall --unused -y
