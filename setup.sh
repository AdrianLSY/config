#!/bin/bash
#
# setup.sh — root bootstrap dispatcher for the external dotfiles repo (~/.dotfiles).
#
# Replaces the old copy-model entrypoint. This repo lives OUTSIDE ~/.config and
# deploys config INTO ~/.config by per-app symlink. Flow:
#   1. Refuse root.  2. Detect OS -> tier (macos|linux).  3. Repo-scoped chmod.
#   4. (macOS) ensure Command Line Tools.  5. Symlink-deploy the tier into
#   ~/.config.  6. Run that tier's own setup/ cascade, propagating its true exit.
#
# Clone-from-anywhere: works regardless of CWD; there is no in-place/skip case.

set -euo pipefail

# --- Refuse to run as root -------------------------------------------------
# sudo would leave root-owned symlinks under ~/.config and write user-domain
# `defaults` into root's domain. Fires before any mutation.
if [ "$(id -u)" -eq 0 ]; then
    echo "🔴 Do not run this as root/sudo — run it as your normal user." >&2
    exit 1
fi

# Resolve the repo dir robustly (independent of CWD; no `cd` that would break
# later relative work — everything downstream uses absolute paths off DIR).
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Detect OS / select tier ----------------------------------------------
case "$(uname -s)" in
    Darwin) TIER="macos" ;;
    Linux)  TIER="linux" ;;
    *)
        echo "🔴 Unsupported OS: $(uname -s). Only macOS (Darwin) and Linux are supported." >&2
        exit 1
        ;;
esac
TIER_DIR="$DIR/$TIER"

if [ ! -d "$TIER_DIR" ]; then
    echo "🔴 Tier directory not found: $TIER_DIR" >&2
    exit 1
fi

echo "🔧 Bootstrapping tier: $TIER"

# --- Repo-scoped permissions -----------------------------------------------
# Make repo files user-executable/readable. SCOPED TO THE REPO ONLY (never
# ~/.config, never .git internals). The -prune drops the whole .git subtree.
find "$DIR" -path "$DIR/.git" -prune -o -type f -exec chmod 700 {} +

# --- macOS: ensure Apple Command Line Tools --------------------------------
# A bare macOS machine has neither git nor clang and Homebrew needs them. No-op
# off macOS and when already present; otherwise triggers the installer and
# waits (30s poll, 30-min bound), exiting 1 on timeout.
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
            echo "🔴 Command Line Tools still unavailable after 30 min. Install them, then re-run." >&2
            exit 1
        fi
        echo "   …waiting for Command Line Tools (${waited}s)"
        sleep 30
        waited=$((waited + 30))
    done
    echo "🟢 Command Line Tools ready."
}
ensure_clt

# --- Deploy symlinks BEFORE the tier installers ----------------------------
# Tweaks that touch ~/.config/<app> must find the symlink already present, so
# deploy first. This runs regardless of CWD and even if installers later fail.
# shellcheck source=lib/link.sh
# shellcheck disable=SC1091
. "$DIR/lib/link.sh"

echo "🔗 Deploying $TIER config into $HOME/.config ..."
if ! deploy_tier "$TIER_DIR" "$HOME/.config"; then
    echo "🔴 Symlink deployment failed." >&2
    exit 1
fi

# --- Run the tier's own bootstrap cascade ----------------------------------
# Same reliability pattern as the inner runners: capture the real status
# through the tee pipe via PIPESTATUS[0] (tee always exits 0). We MUST guard the
# pipeline with `if` — a bare `... | tee ; STATUS=${PIPESTATUS[0]}` would let
# `set -euo pipefail` abort the script AT the pipe on failure, before STATUS is
# read and before the reporting/keep-log branch runs (verified empirically).
# The `if`-guard keeps errexit from firing while preserving the real PIPESTATUS.
# Configs are already symlinked, so a partial installer failure still leaves
# configs in place — but the final exit status MUST reflect the true result.
LOGFILE="$DIR/.setup.sh.log"
TIER_SETUP="$TIER_DIR/setup/.setup.sh"

if [ ! -f "$TIER_SETUP" ]; then
    echo "🔴 Tier bootstrap not found: $TIER_SETUP" >&2
    exit 1
fi

echo "🚀 Running $TIER_SETUP ..."
if bash "$TIER_SETUP" 2>&1 | tee "$LOGFILE"; then
    STATUS=0
else
    STATUS=${PIPESTATUS[0]}
fi

if [ "$STATUS" -eq 0 ]; then
    echo "🟢 $TIER setup completed successfully."
    rm -f "$LOGFILE"
else
    echo "🔴 $TIER setup failed — see $LOGFILE" >&2
    echo "🔴 Setup finished with errors (exit $STATUS)." >&2
    exit "$STATUS"
fi

# Some macOS tweaks (defaults writes) only fully apply after a re-login.
if [ "$(uname -s)" = "Darwin" ]; then
    echo "ℹ️  Some macOS settings need a logout or restart to fully take effect."
fi

echo "✅ All done!"
