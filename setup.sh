#!/bin/bash

set -e

# Auto-elevate if not run as root
if [[ $EUID -ne 0 ]]; then
  exec sudo "$0" "$@"
fi

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOGFILE="$DIR/.setup.sh.log"
SETUP_SH="setup/.setup.sh"

echo "🔧 Preparing environment..."

# Ensure all files are user-executable
find . -type f -exec chmod 700 {} +

echo "🚀 Running $SETUP_SH..."
if bash "$SETUP_SH" >"$LOGFILE" 2>&1; then
    echo "🟢 $SETUP_SH completed successfully."
    rm -f "$LOGFILE"
else
    echo "🔴 $SETUP_SH failed!"
    cat "$LOGFILE"
    exit 1
fi

# Post setup: Move configs to ~/.config and update permissions
if [[ "$PWD" != "$HOME/.config" ]]; then
    echo "📁 Copying configs to ~/.config..."
    for config in */; do
        if [[ -d "$config" ]]; then
            rm -rf "$HOME/.config/$config"
            cp -r "$config" "$HOME/.config/"
        fi
    done
    # Copy meta files if they exist
    [[ -d .git ]] && cp -r .git "$HOME/.config/"
    [[ -f .gitignore ]] && cp .gitignore "$HOME/.config/"
    [[ -f README.md ]] && cp README.md "$HOME/.config/"
    [[ -d setup ]] && cp -r setup "$HOME/.config/"

    find "$HOME/.config" -type f -exec chmod 700 {} +

    echo "🟢 All configs copied and permissions set."
fi

echo "✅ All done!"

read -p "🔄 Do you want to reboot now? [y/N] " confirm
if [[ $confirm =~ ^[Yy]$ ]]; then
    sudo reboot
else
    echo "⏭️  Reboot skipped. You should reboot manually later."
fi
