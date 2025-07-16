#!/bin/bash
set -e

flatpak install -y flathub com.spotify.Client || exit 1
