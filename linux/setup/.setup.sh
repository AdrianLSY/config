#!/bin/bash

set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SELF="$(basename "$0")"

echo "Starting setup for all modules..."

ORDER=(
    pacman
    yay
    flatpak
    app
    asdf
    tweak
)

FAILED=()
SUCCESS=()

for BASENAME in "${ORDER[@]}"; do
    SUBDIR="$DIR/$BASENAME"
    SETUP_SH="$SUBDIR/.setup.sh"

    if [[ ! -d "$SUBDIR" ]]; then
        echo "⏭️  $BASENAME: Directory not found. Skipping."
        continue
    fi

    if [[ -x "$SETUP_SH" ]]; then
        echo "Running $SETUP_SH..."
        LOGFILE="$SUBDIR/.setup.sh.log"
        "$SETUP_SH" 2>&1 | tee "$LOGFILE"
        STATUS=${PIPESTATUS[0]}
        if [[ $STATUS -eq 0 ]]; then
            echo "🟢 $BASENAME setup completed successfully."
            rm -f "$LOGFILE"
            SUCCESS+=("$BASENAME")
        else
            echo "🔴 $BASENAME setup failed."
            cat "$LOGFILE"
            FAILED+=("$BASENAME")
        fi
    elif [[ -f "$SETUP_SH" ]]; then
        echo "⏭️  $BASENAME: .setup.sh is not executable. Skipping."
        SKIPPED+=("$BASENAME")
    else
        echo "⏭️  $BASENAME: No .setup.sh found. Skipping."
        SKIPPED+=("$BASENAME")
    fi
done

echo "All module setups complete!"

# Summary
if (( ${#FAILED[@]} )); then
    echo "❌ Failed:   ${FAILED[*]}"
fi
if (( ${#SUCCESS[@]} )); then
    echo "✅ Installed: ${SUCCESS[*]}"
fi

(( ${#FAILED[@]} )) && exit 1 || exit 0
