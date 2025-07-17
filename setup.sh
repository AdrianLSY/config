#!/bin/bash

set -e

if [[ -n "$SUDO_USER" ]]; then
  USER_HOME=$(eval echo "~$SUDO_USER")
else
  USER_HOME="$HOME"
fi

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOGFILE="$DIR/.setup.sh.log"
SETUP_SH="setup/.setup.sh"

echo "🔧 Preparing environment..."

# Ensure all files are user-executable
find . -type f -exec chmod 700 {} +

echo "🚀 Running $SETUP_SH..."
if bash "$SETUP_SH" 2>&1 | tee "$LOGFILE"; then
    echo "🟢 $SETUP_SH completed successfully."
    rm -f "$LOGFILE"
else
    echo "🔴 $SETUP_SH failed!"
    cat "$LOGFILE"
    exit 1
fi

# Post setup: Move configs to ~/.config and update permissions
if [[ "$PWD" != "$USER_HOME/.config" ]]; then
    echo "📁 Copying configs to ~/.config..."
    for config in */; do
        if [[ -d "$config" ]]; then
            rm -rf "$HOME/.config/$config"
            cp -r "$config" "$HOME/.config/"
        fi
    done
    # Copy meta files if they exist
    [[ -d .git ]] && cp -r .git "$HOME/.config/"
    [[ -d setup ]] && cp -r setup "$HOME/.config/"
    [[ -f setup.sh ]] && cp setup.sh "$HOME/.config/"
    [[ -f README.md ]] && cp README.md "$HOME/.config/"
    [[ -f .gitignore ]] && cp .gitignore "$HOME/.config/"
    [[ -f .mimeapps.list ]] && cp .mimeapps.list "$HOME/.config/"

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
