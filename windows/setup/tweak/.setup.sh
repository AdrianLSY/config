#!/bin/bash

set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SELF="$(basename "$0")"

echo "Starting system tweaks..."

FAILED=()
SUCCESS=()

for file in "$DIR"/*.sh; do
    BASENAME="$(basename "$file")"

    # Skip hidden files, this script itself, and non-regular files
    if [[ "$BASENAME" == .* ]] || [[ "$BASENAME" == "$SELF" ]] || [[ ! -f "$file" ]]; then
        continue
    fi

    LOGFILE="$DIR/$BASENAME.log"
    echo "Running $BASENAME..."

    # No skip-check: tweaks run every bootstrap, so each MUST be idempotent
    # (e.g. `reg add`, `New-ItemProperty`, `winget configure` invoked from Git Bash).
    bash "$file" 2>&1 | tee "$LOGFILE"
    STATUS=${PIPESTATUS[0]}

    if [[ $STATUS -eq 0 ]]; then
        echo "🟢 $BASENAME ran successfully."
        rm -f "$LOGFILE"
        SUCCESS+=("$BASENAME")
    else
        echo "🔴 $BASENAME failed."
        cat "$LOGFILE"
        FAILED+=("$BASENAME")
    fi
done

echo "System tweaks complete!"

# Summary
if (( ${#FAILED[@]} )); then
    echo "❌ Failed:   ${FAILED[*]}"
fi
if (( ${#SUCCESS[@]} )); then
    echo "✅ Ran:      ${SUCCESS[*]}"
fi

# Exit nonzero if anything failed
(( ${#FAILED[@]} )) && exit 1 || exit 0
