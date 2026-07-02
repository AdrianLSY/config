#!/bin/bash

set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SELF="$(basename "$0")"

# Modules run as SIBLING processes, so the shellenv the brew module evals
# internally never reaches the tweak module. On a fresh machine (stock
# terminal, .zprofile not yet in effect) tweaks that call brew-installed CLIs
# (duti, uv, pre-commit → the gitleaks hook) would fail or silently skip.
# Re-checked before every module so the run right after brew's first install
# picks it up. Probes both prefixes (Apple Silicon / Intel).
ensure_brew_path() {
    command -v brew &>/dev/null && return 0
    if [ -x /opt/homebrew/bin/brew ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [ -x /usr/local/bin/brew ]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi
}

echo "Starting setup for all modules..."

ORDER=(
    brew
    tweak
)

FAILED=()
SUCCESS=()
SKIPPED=()

for BASENAME in "${ORDER[@]}"; do
    ensure_brew_path
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
