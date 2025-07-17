#!/bin/bash

set -e

if [[ $EUID -eq 0 ]]; then
  echo "Please do not run this script as root."
  exit 1
fi

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SELF="$(basename "$0")"

echo "Updating flatpak remotes..."
flatpak update --appstream -y

echo "Starting Flatpak installs..."

FAILED=()
SUCCESS=()

LOGDIR="$DIR/logs"
mkdir -p "$LOGDIR"

for file in "$DIR"/*.sh; do
    BASENAME="$(basename "$file")"

    # Skip hidden files, this script itself, and non-regular files
    if [[ "$BASENAME" == .* ]] || [[ "$BASENAME" == "$SELF" ]] || [[ ! -f "$file" ]]; then
        continue
    fi

    APP_ID="${BASENAME%.sh}"

    if flatpak info "$APP_ID" &>/dev/null; then
        echo "🟢 $APP_ID is already installed."
        continue
    fi

    LOGFILE="$LOGDIR/$BASENAME.log"
    echo "Installing $APP_ID..."
    bash "$file" 2>&1 | tee "$LOGFILE"
    STATUS=$?
    if [[ $STATUS -eq 0 ]]; then
        echo "🟢 $APP_ID installed successfully."
        rm -f "$LOGFILE"
        SUCCESS+=("$APP_ID")
    else
        echo "🔴 $APP_ID was not installed"
        cat "$LOGFILE"
        FAILED+=("$APP_ID")
    fi
done

echo "Flatpak installs complete!"

# Summary
if (( ${#FAILED[@]} )); then
    printf '❌ Failed:   %s\n' "${FAILED[@]}"
fi
if (( ${#SUCCESS[@]} )); then
    printf '✅ Installed: %s\n' "${SUCCESS[@]}"
fi

# Exit nonzero if anything failed
(( ${#FAILED[@]} )) && exit 1 || exit 0
