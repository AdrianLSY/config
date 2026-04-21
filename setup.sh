#!/bin/bash

set -e

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
if [[ "$PWD" != "$HOME/.config" ]]; then
    echo "📁 Copying configs to ~/.config..."
    for config in */; do
        if [[ -d "$config" ]]; then
            rm -rf "$HOME/.config/$config"
            cp -r "$config" "$HOME/.config/"
        fi
    done
    # Copy meta files if they exist
    [[ -d .git ]] && { rm -rf "$HOME/.config/.git"; cp -r .git "$HOME/.config/"; }
    [[ -d setup ]] && { rm -rf "$HOME/.config/setup"; cp -r setup "$HOME/.config/"; }
    [[ -f setup.sh ]] && cp -f setup.sh "$HOME/.config/"
    [[ -f README.md ]] && cp -f README.md "$HOME/.config/"
    [[ -f .gitignore ]] && cp -f .gitignore "$HOME/.config/"

    find "$HOME/.config" -type f -exec chmod 700 {} +

    echo "🟢 All configs copied and permissions set."
fi

echo "✅ All done!"
