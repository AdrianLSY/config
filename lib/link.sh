# shellcheck shell=bash
# lib/link.sh — symlink-deploy helper for the dotfiles repo.
#
# SOURCEABLE library: it only defines functions and has NO run-side-effects, so
# `source lib/link.sh` is safe. Deliberately no shebang (the shellcheck shell
# directive above sets the dialect so `shellcheck lib/link.sh` still lints
# cleanly) and no top-level code beyond function definitions.
#
# Deploys one OS tier (macos/ or linux/) into ~/.config by per-app SYMLINK:
#   ~/.config/<app>  ->  <repo>/<tier>/<app>
# so editing through the symlink is a repo edit. The reserved `setup/` dir is
# bootstrap tooling and is NEVER symlinked. Everything is non-destructive: a
# pre-existing real target is moved to <dst>.bak.<timestamp> before we relink,
# and unmanaged ~/.config entries are never touched.
#
# Portability: works on macOS bash 3.2 (no `readlink -f`, no associative
# arrays) and Linux bash 5. All expansions quoted; names with spaces handled.

# _link_backup_path <dst>
# Echo a non-colliding backup path for <dst>. Base is "<dst>.bak.<timestamp>";
# if that already exists, append ".1", ".2", … until a free name is found.
_link_backup_path() {
    local dst ts base candidate n
    dst="$1"
    ts="$(date +%Y%m%d%H%M%S)"
    base="${dst}.bak.${ts}"
    candidate="$base"
    n=1
    # -e is false for a broken symlink, so also guard with -L (symlink test).
    while [ -e "$candidate" ] || [ -L "$candidate" ]; do
        candidate="${base}.${n}"
        n=$((n + 1))
    done
    printf '%s\n' "$candidate"
}

# deploy_tier <tier_dir> <target_dir>
# Symlink every direct child of <tier_dir> (except `setup`) into <target_dir>.
# Idempotent: a second run over an already-linked tier makes zero changes and
# creates zero new .bak files. Does not `exit` (safe to source).
deploy_tier() {
    local _dt_tier_dir _dt_target_dir _dt_linked _dt_backed _dt_ok
    local src name dst backup
    _dt_tier_dir="$1"
    _dt_target_dir="$2"

    if [ -z "$_dt_tier_dir" ] || [ -z "$_dt_target_dir" ]; then
        echo "🔴 deploy_tier: need <tier_dir> and <target_dir>" >&2
        return 1
    fi
    if [ ! -d "$_dt_tier_dir" ]; then
        echo "🔴 deploy_tier: tier dir not found: $_dt_tier_dir" >&2
        return 1
    fi

    mkdir -p "$_dt_target_dir"

    _dt_linked=0
    _dt_backed=0
    _dt_ok=0

    # Enumerate ONLY direct children of the tier dir. The trailing `/*` glob is
    # unquoted so it expands; if it matches nothing bash leaves the literal, so
    # we guard each entry with an existence test below.
    for src in "$_dt_tier_dir"/*; do
        # Skip the literal glob (empty tier) and anything that vanished.
        [ -e "$src" ] || [ -L "$src" ] || continue

        name="$(basename "$src")"

        # Reserved bootstrap tooling — never deployed.
        [ "$name" = "setup" ] && continue

        dst="$_dt_target_dir/$name"

        # Already correctly linked -> no-op. `-ef` is true only when both paths
        # resolve to the same inode (false for a broken/foreign symlink, which
        # is exactly the "needs relink" case). A literal readlink comparison
        # covers the case where -ef is unavailable/quirky. NOTE: a same-inode
        # link reached via a different literal path (e.g. a relative
        # `../<tier>/<app>`) is intentionally accepted as-is and NOT rewritten
        # to the absolute src — same target, no destructive churn.
        if [ -L "$dst" ] && { [ "$dst" -ef "$src" ] || [ "$(readlink "$dst")" = "$src" ]; }; then
            echo "ok   $name"
            _dt_ok=$((_dt_ok + 1))
            continue
        fi

        # Anything else present (real dir, real file, foreign symlink, or a
        # broken symlink) must be moved aside before we relink. NEVER rm -rf.
        if [ -e "$dst" ] || [ -L "$dst" ]; then
            backup="$(_link_backup_path "$dst")"
            if ! mv "$dst" "$backup"; then
                echo "🔴 failed to back up $dst -> $backup" >&2
                return 1
            fi
            echo "bak  $name -> $(basename "$backup")"
            _dt_backed=$((_dt_backed + 1))
        fi

        # Create the symlink with the ABSOLUTE source path.
        if ! ln -s "$src" "$dst"; then
            echo "🔴 failed to link $dst -> $src" >&2
            return 1
        fi
        echo "link $name"
        _dt_linked=$((_dt_linked + 1))
    done

    echo "🔗 deploy: ${_dt_linked} linked, ${_dt_backed} backed up, ${_dt_ok} already ok"
    return 0
}

# Guard: if this file is executed rather than sourced, say so. The BASH_SOURCE
# idiom is true exactly when the file is run directly (bash 3.2 and 5) and never
# fires when sourced. Non-load-bearing — setup.sh always sources this.
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    echo "link.sh is a sourceable library; source it, don't run it." >&2
fi
