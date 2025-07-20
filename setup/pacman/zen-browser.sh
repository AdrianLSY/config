#!/bin/bash
set -e

sudo pacman -S --noconfirm zen-browser

xdg-mime default zen-browser.desktop x-scheme-handler/http
xdg-mime default zen-browser.desktop x-scheme-handler/https
