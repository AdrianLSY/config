#!/bin/bash

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SELF="$(basename "$0")"

echo "Starting system tweaks..."

FAILED=()
SUCCESS=()
SKIPPED=()

for file in "$DIR"/*.sh; do
    BASENAME="$(basename "$file")"

    # Skip hidden files, this script itself, and non-regular files
    if [[ "$BASENAME" == .* ]] || [[ "$BASENAME" == "$SELF" ]] || [[ ! -f "$file" ]]; then
        continue
    fi

    LOGFILE="$DIR/$BASENAME.log"
    echo "Running $BASENAME..."

    bash "$file" >"$LOGFILE" 2>&1
    STATUS=$?

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
if (( ${#SKIPPED[@]} )); then
    echo "⏭️  Skipped:   ${SKIPPED[*]}"
fi

# Exit nonzero if anything failed
(( ${#FAILED[@]} )) && exit 1 || exit 0
