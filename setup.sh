#!/bin/bash

set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOGFILE="$DIR/.setup.sh.log"
SETUP_SH="setup/.setup.sh"

echo "🔧 Preparing environment..."

# Ensure all files are user-executable (skip .git internals)
find . -path ./.git -prune -o -type f -exec chmod 700 {} +

echo "🚀 Running $SETUP_SH..."
# Capture the runner's real status through the tee pipe (PIPESTATUS[0]), not
# tee's always-zero exit. Configs are still copied below on partial failure so
# a single flaky package never blocks dotfile installation — but we exit with
# the true status at the end.
bash "$SETUP_SH" 2>&1 | tee "$LOGFILE"
STATUS=${PIPESTATUS[0]}
if [[ $STATUS -eq 0 ]]; then
    echo "🟢 $SETUP_SH completed successfully."
    rm -f "$LOGFILE"
else
    echo "🔴 $SETUP_SH failed — see $LOGFILE"
fi

# Post setup: Move configs to ~/.config and update permissions. Runs regardless
# of $STATUS; chmod is scoped to the paths we copy (never .git internals).
if [[ "$PWD" != "$HOME/.config" ]]; then
    echo "📁 Copying configs to ~/.config..."
    for config in */; do
        config="${config%/}"   # strip trailing slash so cp creates ~/.config/<dir>, not splatting its contents
        if [[ -d "$config" ]]; then
            rm -rf "$HOME/.config/$config"
            cp -r "$config" "$HOME/.config/"
            find "$HOME/.config/$config" -type f -exec chmod 700 {} +
        fi
    done
    # Copy meta files if they exist
    [[ -d .git ]] && { rm -rf "$HOME/.config/.git"; cp -r .git "$HOME/.config/"; }
    [[ -d setup ]] && { rm -rf "$HOME/.config/setup"; cp -r setup "$HOME/.config/"; find "$HOME/.config/setup" -type f -exec chmod 700 {} +; }
    [[ -f setup.sh ]] && { cp -f setup.sh "$HOME/.config/"; chmod 700 "$HOME/.config/setup.sh"; }
    [[ -f README.md ]] && { cp -f README.md "$HOME/.config/"; chmod 700 "$HOME/.config/README.md"; }
    [[ -f .gitignore ]] && { cp -f .gitignore "$HOME/.config/"; chmod 700 "$HOME/.config/.gitignore"; }

    echo "🟢 All configs copied and permissions set."
fi

if [[ $STATUS -ne 0 ]]; then
    echo "❌ Setup finished with errors (exit $STATUS)."
    exit "$STATUS"
fi

echo "✅ All done!"
