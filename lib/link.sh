# shellcheck shell=bash
# lib/link.sh — symlink-deploy helper for the dotfiles repo.
#
# SOURCEABLE library: it only defines functions and has NO run-side-effects, so
# `source lib/link.sh` is safe. Deliberately no shebang (the shellcheck shell
# directive above sets the dialect so `shellcheck lib/link.sh` still lints
# cleanly) and no top-level code beyond function definitions.
#
# Two deploy modes share ONE backup-then-link primitive (`_link_one`):
#   - deploy_tier <tier_dir> <target_dir>   (macOS/Linux): enumerate the tier's
#     direct children and link each into a single target dir (~/.config/<app>).
#   - deploy_manifest <tier_dir> <manifest> (Windows): read a `<app>\t<dest>`
#     manifest and link each app to its own (heterogeneous) destination, since
#     Windows has no single ~/.config. Env references in <dest> are expanded by
#     _expand_dest (leading $HOME/.config, $HOME, $APPDATA, $LOCALAPPDATA,
#     $USERPROFILE only — no eval, no globbing).
#
# In both modes: editing through the resulting symlink is a repo edit. The
# reserved `setup/` dir is bootstrap tooling and is NEVER deployed. Everything is
# non-destructive: a pre-existing real target is moved to <dst>.bak.<timestamp>
# before we relink, and unmanaged entries are never touched.
#
# Portability: works on macOS bash 3.2 (no `readlink -f`, no associative
# arrays) and Linux bash 5, and under Git Bash/MSYS on Windows. All expansions
# quoted; names with spaces handled.

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

# _link_one <src> <dst> [label]
# Backup-then-link ONE pair, non-destructively and idempotently. Shared by
# deploy_tier and deploy_manifest. Prints a per-entry status line using [label]
# (defaults to basename <dst>). Communicates what it did to the caller via two
# globals so callers can keep their own counters:
#   _LINK_ACTION = "ok"   -> already the correct symlink (no-op, no backup)
#                  "link" -> a new symlink was created
#   _LINK_BACKED = 1      -> an existing target was moved to <dst>.bak.<ts> first
#                  0      -> nothing was backed up
# Returns non-zero on a hard failure (mkdir/mv/ln). Does not `exit` (safe to source).
_link_one() {
    local src dst label backup
    src="$1"
    dst="$2"
    label="${3:-$(basename "$dst")}"
    _LINK_ACTION=""
    _LINK_BACKED=0

    # Already correctly linked -> no-op. `-ef` is true only when both paths
    # resolve to the same inode (false for a broken/foreign symlink, which is
    # exactly the "needs relink" case). A literal readlink comparison covers the
    # case where -ef is unavailable/quirky. NOTE: a same-inode link reached via a
    # different literal path (e.g. a relative one) is intentionally accepted
    # as-is and NOT rewritten to the absolute src — same target, no churn.
    if [ -L "$dst" ] && { [ "$dst" -ef "$src" ] || [ "$(readlink "$dst")" = "$src" ]; }; then
        echo "ok   $label"
        _LINK_ACTION="ok"
        return 0
    fi

    # Ensure the destination's PARENT exists before linking. Windows destinations
    # are nested (e.g. $APPDATA/Code/User); for the flat ~/.config/<app> case the
    # parent (~/.config) already exists, so this is a harmless idempotent no-op.
    if ! mkdir -p "$(dirname "$dst")"; then
        echo "🔴 failed to create parent dir for $dst" >&2
        return 1
    fi

    # Anything else present (real dir, real file, foreign symlink, or a broken
    # symlink) must be moved aside before we relink. NEVER rm -rf.
    if [ -e "$dst" ] || [ -L "$dst" ]; then
        backup="$(_link_backup_path "$dst")"
        if ! mv "$dst" "$backup"; then
            echo "🔴 failed to back up $dst -> $backup" >&2
            return 1
        fi
        echo "bak  $label -> $(basename "$backup")"
        _LINK_BACKED=1
    fi

    # Create the symlink with the ABSOLUTE source path.
    if ! ln -s "$src" "$dst"; then
        echo "🔴 failed to link $dst -> $src" >&2
        return 1
    fi
    echo "link $label"
    _LINK_ACTION="link"
    return 0
}

# _expand_dest <dest>
# Expand a LEADING recognized environment reference in a manifest destination and
# echo the result. Only these references are honored, and only as a prefix:
#   $HOME/.config, $HOME, $APPDATA, $LOCALAPPDATA, $USERPROFILE
# Nothing else is expanded — no `eval`, no command substitution, no globbing — so
# a destination is safe to feed even if it contains $, spaces, or backticks. The
# remainder of the path (including any spaces) is preserved verbatim. If a matched
# reference's variable is unset/empty (would silently yield a root-relative path
# like `/Code/User`), it FAILS with a clear message and returns non-zero instead.
# The `${VAR:-}` guards keep this safe under `set -u`.
_expand_dest() {
    local d
    d="$1"
    # The single-quoted case patterns match the LITERAL text `$HOME` etc. in the
    # manifest destination — non-expansion is intentional (SC2016 is a false
    # positive here).
    # shellcheck disable=SC2016
    case "$d" in
        '$HOME/.config'*) [ -n "${HOME:-}" ]         || { echo "🔴 _expand_dest: \$HOME is unset (needed by: $d)" >&2; return 1; }
                          printf '%s' "${HOME}/.config${d#\$HOME/.config}" ;;
        '$HOME'*)         [ -n "${HOME:-}" ]         || { echo "🔴 _expand_dest: \$HOME is unset (needed by: $d)" >&2; return 1; }
                          printf '%s' "${HOME}${d#\$HOME}" ;;
        '$APPDATA'*)      [ -n "${APPDATA:-}" ]      || { echo "🔴 _expand_dest: \$APPDATA is unset (needed by: $d)" >&2; return 1; }
                          printf '%s' "${APPDATA}${d#\$APPDATA}" ;;
        '$LOCALAPPDATA'*) [ -n "${LOCALAPPDATA:-}" ] || { echo "🔴 _expand_dest: \$LOCALAPPDATA is unset (needed by: $d)" >&2; return 1; }
                          printf '%s' "${LOCALAPPDATA}${d#\$LOCALAPPDATA}" ;;
        '$USERPROFILE'*)  [ -n "${USERPROFILE:-}" ]  || { echo "🔴 _expand_dest: \$USERPROFILE is unset (needed by: $d)" >&2; return 1; }
                          printf '%s' "${USERPROFILE}${d#\$USERPROFILE}" ;;
        *)                printf '%s' "$d" ;;
    esac
}

# deploy_tier <tier_dir> <target_dir>
# Symlink every direct child of <tier_dir> (except `setup`) into <target_dir>.
# Idempotent: a second run over an already-linked tier makes zero changes and
# creates zero new .bak files. Does not `exit` (safe to source).
deploy_tier() {
    local _dt_tier_dir _dt_target_dir _dt_linked _dt_backed _dt_ok
    local src name dst
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

        if ! _link_one "$src" "$dst" "$name"; then
            return 1
        fi
        case "$_LINK_ACTION" in
            ok)   _dt_ok=$((_dt_ok + 1)) ;;
            link) _dt_linked=$((_dt_linked + 1)) ;;
        esac
        [ "$_LINK_BACKED" = "1" ] && _dt_backed=$((_dt_backed + 1))
    done

    echo "🔗 deploy: ${_dt_linked} linked, ${_dt_backed} backed up, ${_dt_ok} already ok"
    return 0
}

# deploy_manifest <tier_dir> <manifest>
# Windows deploy: link each app named in <manifest> to its own destination via
# _link_one. Manifest lines are TAB-separated "<app>\t<destination>"; blank lines
# and lines beginning with `#` are skipped; leading/trailing whitespace in each
# field is stripped; the destination's LEADING env reference is expanded by
# _expand_dest. The manifest file itself and the reserved `setup/` dir are never
# deployed (deploy is manifest-line-driven, not child-enumeration). A line whose
# <app> source is missing (or which has no destination) is reported and skipped —
# it does NOT abort the remaining lines — and makes the function return non-zero
# so the caller surfaces the manifest error. Does not `exit` (safe to source).
deploy_manifest() {
    local _dm_tier_dir _dm_manifest _dm_linked _dm_backed _dm_ok _dm_err
    local app dest src
    _dm_tier_dir="$1"
    _dm_manifest="$2"

    if [ -z "$_dm_tier_dir" ] || [ -z "$_dm_manifest" ]; then
        echo "🔴 deploy_manifest: need <tier_dir> and <manifest>" >&2
        return 1
    fi
    if [ ! -f "$_dm_manifest" ]; then
        echo "🔴 deploy_manifest: manifest not found: $_dm_manifest" >&2
        return 1
    fi

    _dm_linked=0
    _dm_backed=0
    _dm_ok=0
    _dm_err=0

    # IFS=tab splits each line into <app> and <dest> on the field separator; the
    # `|| [ -n "$app" ]` tail processes a final line lacking a trailing newline.
    while IFS=$'\t' read -r app dest || [ -n "$app" ]; do
        # Strip CR (a .links saved with CRLF endings on Windows leaves a trailing
        # \r on the last field; GNU sed's [[:space:]] does NOT match \r, so a
        # stray CR would silently corrupt the symlink target) then trim
        # surrounding whitespace from both fields.
        app="$(printf '%s' "$app" | tr -d '\r' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
        dest="$(printf '%s' "$dest" | tr -d '\r' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"

        # Skip blank lines and comments.
        [ -z "$app" ] && continue
        case "$app" in \#*) continue ;; esac

        if [ -z "$dest" ]; then
            echo "🔴 manifest: no destination for '$app' (expected a TAB then a path)" >&2
            _dm_err=$((_dm_err + 1))
            continue
        fi

        # Expand a leading env reference; a reference to an unset var fails here.
        if ! dest="$(_expand_dest "$dest")"; then
            _dm_err=$((_dm_err + 1))
            continue
        fi
        src="$_dm_tier_dir/$app"

        if [ ! -e "$src" ] && [ ! -L "$src" ]; then
            echo "🔴 manifest: source not found, skipping: $src" >&2
            _dm_err=$((_dm_err + 1))
            continue
        fi

        if ! _link_one "$src" "$dest" "$app"; then
            _dm_err=$((_dm_err + 1))
            continue
        fi
        case "$_LINK_ACTION" in
            ok)   _dm_ok=$((_dm_ok + 1)) ;;
            link) _dm_linked=$((_dm_linked + 1)) ;;
        esac
        [ "$_LINK_BACKED" = "1" ] && _dm_backed=$((_dm_backed + 1))
    done < "$_dm_manifest"

    echo "🔗 manifest deploy: ${_dm_linked} linked, ${_dm_backed} backed up, ${_dm_ok} already ok, ${_dm_err} error(s)"
    [ "$_dm_err" -eq 0 ]
}

# Guard: if this file is executed rather than sourced, say so. The BASH_SOURCE
# idiom is true exactly when the file is run directly (bash 3.2 and 5) and never
# fires when sourced. Non-load-bearing — setup.sh always sources this.
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    echo "link.sh is a sourceable library; source it, don't run it." >&2
fi
