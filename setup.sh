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
# Git Bash/MSYS/Cygwin report a `*_NT-…` uname (e.g. MINGW64_NT-10.0) → the
# native-Windows `windows` tier. NOTE: WSL reports `Linux`, so it correctly
# selects the `linux` tier — the `windows` tier is for native Windows reached
# through Git Bash/MSYS, not WSL.
case "$(uname -s)" in
    Darwin)              TIER="macos" ;;
    Linux)               TIER="linux" ;;
    MINGW*|MSYS*|CYGWIN*) TIER="windows" ;;
    *)
        echo "🔴 Unsupported OS: $(uname -s). Only macOS (Darwin), Linux, and Windows (Git Bash/MSYS) are supported." >&2
        exit 1
        ;;
esac
TIER_DIR="$DIR/$TIER"

if [ ! -d "$TIER_DIR" ]; then
    echo "🔴 Tier directory not found: $TIER_DIR" >&2
    exit 1
fi

echo "🔧 Bootstrapping tier: $TIER"

# --- Windows: preflight BEFORE any mutation --------------------------------
# On the Windows (Git Bash/MSYS) tier, fail fast — before the chmod pass, any
# backup, any symlink, or any install — if prerequisites are missing: winget
# must be on PATH, and the shell must be able to create a NATIVE symlink
# (Developer Mode on, or an elevated shell). The symlink probe is self-contained
# and removes its test artifact regardless of outcome. No-op off Windows.
preflight_windows() {
    [ "$TIER" = "windows" ] || return 0

    if ! command -v winget >/dev/null 2>&1; then
        echo "🔴 winget not found on PATH. Install the App Installer (Windows Package Manager) and re-run." >&2
        exit 1
    fi

    local probe target link
    probe="$(mktemp -d 2>/dev/null || echo "${TMPDIR:-${TMP:-/tmp}}/dotfiles-preflight.$$")"
    mkdir -p "$probe" 2>/dev/null || true
    target="$probe/target"
    link="$probe/link"
    if [ ! -d "$probe" ] || ! : > "$target" 2>/dev/null; then
        rm -rf "$probe" 2>/dev/null || true
        echo "🔴 Windows preflight: could not create a temp dir to test symlink capability." >&2
        exit 1
    fi
    MSYS=winsymlinks:nativestrict ln -s "$target" "$link" 2>/dev/null || true
    if [ ! -L "$link" ]; then
        rm -rf "$probe" 2>/dev/null || true
        echo "🔴 Cannot create a native symlink. Enable Developer Mode (Settings → Privacy & security → For developers) or run from an elevated shell, then re-run." >&2
        exit 1
    fi
    rm -rf "$probe" 2>/dev/null || true
    echo "🟢 Windows preflight passed (winget present, native symlinks OK)."
}
preflight_windows

# --- Repo-scoped permissions -----------------------------------------------
# Make repo files user-read/writable WITHOUT touching the executable bit git
# tracks: `u+rwX` (capital X) adds execute only to files that are already
# executable, so tracked-as-644 files stay 644 and a bootstrap never dirties
# `git status` with mode-only diffs (chmod 700 here used to flip every 644
# file to 755). SCOPED TO THE REPO ONLY (never ~/.config, never .git
# internals). The -prune drops the whole .git subtree.
# (On Windows/NTFS chmod is a harmless no-op; left in place unconditionally.)
find "$DIR" -path "$DIR/.git" -prune -o -type f -exec chmod u+rwX {} +

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

# macOS/Linux link every tier app dir into the single ~/.config target. Windows
# has no single target (config scatters across %APPDATA%, %LOCALAPPDATA%, …), so
# it deploys from an explicit windows/.links manifest to per-app destinations,
# with MSYS=winsymlinks:nativestrict exported so `ln -s` creates native symlinks.
if [ "$TIER" = "windows" ]; then
    export MSYS=winsymlinks:nativestrict
    echo "🔗 Deploying $TIER config from $TIER_DIR/.links ..."
    if ! deploy_manifest "$TIER_DIR" "$TIER_DIR/.links"; then
        echo "🔴 Symlink deployment failed." >&2
        exit 1
    fi
else
    echo "🔗 Deploying $TIER config into $HOME/.config ..."
    if ! deploy_tier "$TIER_DIR" "$HOME/.config"; then
        echo "🔴 Symlink deployment failed." >&2
        exit 1
    fi
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
