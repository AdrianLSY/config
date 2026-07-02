#!/bin/bash

set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SELF="$(basename "$0")"

# winget (Windows Package Manager) is required. The top-level setup.sh preflight
# already verified its presence; this guard keeps the module runnable standalone.
if ! command -v winget &>/dev/null; then
    echo "🔴 winget not found on PATH."
    exit 1
fi

echo "Starting winget installs..."

FAILED=()
SUCCESS=()

for file in "$DIR"/*.sh; do
    BASENAME="$(basename "$file")"

    # Skip hidden files, this script itself, and non-regular files
    if [[ "$BASENAME" == .* ]] || [[ "$BASENAME" == "$SELF" ]] || [[ ! -f "$file" ]]; then
        continue
    fi

    # The filename minus .sh MUST equal the full winget id (e.g. Mozilla.Firefox.sh),
    # so the exact-match skip-check below recognizes an already-installed package.
    # `winget list --id "$PKG" -e` exits 0 when the exact id is installed, non-zero
    # otherwise.
    PKG="${BASENAME%.sh}"

    if winget list --id "$PKG" -e &>/dev/null; then
        echo "⏭️ $PKG is already installed."
        continue
    fi

    LOGFILE="$DIR/$BASENAME.log"
    bash "$file" 2>&1 | tee "$LOGFILE"
    STATUS=${PIPESTATUS[0]}
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

echo "winget installs complete!"

# Summary
if (( ${#FAILED[@]} )); then
    echo "❌ Failed:   ${FAILED[*]}"
fi
if (( ${#SUCCESS[@]} )); then
    echo "✅ Installed: ${SUCCESS[*]}"
fi

# Exit nonzero if anything failed
(( ${#FAILED[@]} )) && exit 1 || exit 0
