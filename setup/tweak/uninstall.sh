#!/bin/bash
set -e

pacman -Q alacritty &>/dev/null && sudo pacman -Rns --noconfirm alacritty || true
pacman -Q nano-syntax-highlighting &>/dev/null && sudo pacman -Rns --noconfirm nano-syntax-highlighting || true
pacman -Q nano &>/dev/null && sudo pacman -Rns --noconfirm nano || true
