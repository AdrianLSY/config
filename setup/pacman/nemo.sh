#!/bin/bash
set -e

sudo pacman -S --noconfirm nemo

gsettings set org.nemo.desktop show-desktop-icons true
xdg-mime default nemo.desktop inode/directory application/x-gnome-saved-search
