#!/bin/bash
set -e

flatpak install -y flathub com.spotify.Client.sh || exit 1
