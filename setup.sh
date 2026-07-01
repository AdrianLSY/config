#!/bin/bash

set -e

# Refuse to run as root: sudo would leave root-owned files under ~/.config and
# write user-domain `defaults` into root's domain. Fires before any mutation.
if [ "$(id -u)" -eq 0 ]; then
    echo "❌ Do not run this as root/sudo — run it as your normal user." >&2
    exit 1
fi

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOGFILE="$DIR/.setup.sh.log"
SETUP_SH="setup/.setup.sh"

echo "🔧 Preparing environment..."

# Ensure all files are user-executable (skip .git internals)
find . -path ./.git -prune -o -type f -exec chmod 700 {} +

# Ensure Apple Command Line Tools (git, clang) exist before the brew module — a
# bare macOS machine has neither and Homebrew needs them. No-op off macOS and
# when already present; otherwise triggers the installer and waits (bounded).
ensure_clt() {
    [ "$(uname -s)" = "Darwin" ] || return 0
    if xcode-select -p &>/dev/null && git --version &>/dev/null; then
        return 0
    fi
    echo "🛠  Command Line Tools not found — triggering install (accept the dialog)..."
    xcode-select --install 2>/dev/null || true
    local waited=0
    until git --version &>/dev/null; do
        if (( waited >= 1800 )); then
            echo "❌ Command Line Tools still unavailable after 30 min. Install them, then re-run." >&2
            exit 1
        fi
        echo "   …waiting for Command Line Tools (${waited}s)"
        sleep 30
        waited=$((waited + 30))
    done
    echo "🟢 Command Line Tools ready."
}
ensure_clt

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
    [[ -f CLAUDE.md ]] && { cp -f CLAUDE.md "$HOME/.config/"; chmod 700 "$HOME/.config/CLAUDE.md"; }
    [[ -f starship.toml ]] && { cp -f starship.toml "$HOME/.config/"; chmod 700 "$HOME/.config/starship.toml"; }
    [[ -f .pre-commit-config.yaml ]] && { cp -f .pre-commit-config.yaml "$HOME/.config/"; chmod 700 "$HOME/.config/.pre-commit-config.yaml"; }

    echo "🟢 All configs copied and permissions set."
fi

if [[ $STATUS -ne 0 ]]; then
    echo "❌ Setup finished with errors (exit $STATUS)."
    exit "$STATUS"
fi

# Some macOS tweaks (defaults writes) only fully apply after a re-login.
if [ "$(uname -s)" = "Darwin" ]; then
    echo "ℹ️  Some macOS settings need a logout or restart to fully take effect."
fi

echo "✅ All done!"
