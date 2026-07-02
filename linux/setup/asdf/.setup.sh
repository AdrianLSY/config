#!/bin/bash
# setup/asdf/.setup.sh

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SELF="$(basename "$0")"

# The scripts below edit ~/.tool-versions with sed -i, which errors if the
# file is missing — and asdf never creates it on install, so a fresh machine
# starts without one. An empty file is valid to asdf.
[ -f "$HOME/.tool-versions" ] || touch "$HOME/.tool-versions"

echo "Starting asdf installs..."

FAILED=()
SUCCESS=()

for file in "$DIR"/*.sh; do
    BASENAME="$(basename "$file")"

    # Skip hidden files, this script itself, and non-regular files
    if [[ "$BASENAME" == .* ]] || [[ "$BASENAME" == "$SELF" ]] || [[ ! -f "$file" ]]; then
        continue
    fi

    PKG="${BASENAME%.sh}"

    # Check if plugin and at least one version are already installed
    if asdf plugin list | grep -qx "$PKG" && asdf list "$PKG" 2>/dev/null | grep -q .; then
        echo "⏭️ $PKG already installed."
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

asdf reshim
echo "asdf installs complete!"

# Summary
if (( ${#FAILED[@]} )); then
    echo "❌ Failed:   ${FAILED[*]}"
fi
if (( ${#SUCCESS[@]} )); then
    echo "✅ Installed: ${SUCCESS[*]}"
fi

# Exit nonzero if anything failed
(( ${#FAILED[@]} )) && exit 1 || exit 0
