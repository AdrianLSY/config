#!/bin/bash

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SELF="$(basename "$0")"

echo "Starting asdf installs..."

FAILED=()
SKIPPED=()
SUCCESS=()

for file in "$DIR"/*.sh; do
    BASENAME="$(basename "$file")"

    # Skip hidden files, this script itself, and non-regular files
    if [[ "$BASENAME" == .* ]] || [[ "$BASENAME" == "$SELF" ]] || [[ ! -f "$file" ]]; then
        continue
    fi

    PKG="${BASENAME%.sh}"

    # Check if plugin already installed
    if asdf plugin list | grep -qx "$PKG"; then
        echo "🟢 $PKG plugin already added."
        SKIPPED+=("$PKG")
        continue
    fi

    LOGFILE="$DIR/$BASENAME.log"
    bash "$file" >"$LOGFILE" 2>&1
    STATUS=$?
    if [[ $STATUS -eq 0 ]]; then
        echo "🟢 $PKG installed successfully."
        rm -f "$LOGFILE"
        SUCCESS+=("$PKG")
    else
        echo "🔴 $PKG was not installed"
        cat "$LOGFILE"
        FAILED+=("$PKG")
    fi
done

asdf reshim
echo "asdf installs complete!"

# Summary
if (( ${#FAILED[@]} )); then
    echo "❌ Failed:   ${FAILED[*]}"
fi
if (( ${#SUCCESS[@]} )); then
    echo "✅ Installed: ${SUCCESS[*]}"
fi
if (( ${#SKIPPED[@]} )); then
    echo "⏭️  Skipped:   ${SKIPPED[*]}"
fi

# Exit nonzero if anything failed
(( ${#FAILED[@]} )) && exit 1 || exit 0
