source /usr/share/cachyos-fish-config/cachyos-config.fish
set -x BROWSER zen-browser

function fish_greeting
    # Disable fastfetch
    # fastfetch
end

alias ff='fastfetch'
alias bios='sudo systemctl reboot --firmware-setup'
alias uefi='sudo systemctl reboot --firmware-setup'

functions -e update 2>/dev/null
function update --description 'Unattended update pacman, yay, flatpak; then cleanup'
    # Create pre-update snapshot with Snapper; abort on failure
    if not command -qs snapper
        echo "update: snapper not found; aborting to avoid unprotected update."
        return 1
    end

    set -l snapper_args
    if sudo snapper --config root list >/dev/null 2>&1
        set snapper_args --config root
        echo "update: using snapper config 'root'."
    else
        echo "update: no Snapper 'root' config found. Aborting update."
        return 1
    end

    set -l timestamp (date "+%Y-%m-%dT%H:%M:%S%z")
    echo "update: creating pre-update snapshot..."
    if not sudo snapper $snapper_args create --type single --description "pre-update $timestamp"
        echo "update: failed to create pre-update snapshot; aborting."
        return 1
    end
    echo "update: snapshot created. Proceeding with package updates..."

    sudo pacman -Syyu --noconfirm
    yay -Syyu --noconfirm --answerclean All --answerdiff None --answeredit None
    flatpak update -y
    sudo pacman -Sc --noconfirm
    yay -Sc --noconfirm
    flatpak uninstall --unused -y
end

functions -e rollback 2>/dev/null
function rollback --description 'Rollback to the latest Snapper single snapshot and delete it afterward'
    if not command -qs snapper
        echo "rollback: snapper not found."
        return 1
    end

    set -l snapper_args
    if sudo snapper --config root list >/dev/null 2>&1
        set snapper_args --config root
        echo "rollback: using snapper config 'root'."
    else
        echo "rollback: no Snapper 'root' config found. Cannot rollback."
        return 1
    end

    echo "rollback: locating latest 'single' snapshot id..."
    set -l last_id (sudo snapper $snapper_args list --type single --columns number | grep -E '^[[:space:]]*[0-9]+[[:space:]]*$' | tail -n 1 | tr -d '[:space:]')
    if test -z "$last_id"
        echo "rollback: no 'single' snapshots found."
        return 1
    end

    echo "rollback: rolling back to snapshot ID $last_id ..."
    if not sudo snapper $snapper_args rollback $last_id
        echo "rollback: rollback failed."
        return 1
    end

    echo "rollback: deleting snapshot ID $last_id ..."
    if not sudo snapper $snapper_args delete $last_id
        echo "rollback: failed to delete snapshot ID $last_id (please remove manually)."
        return 1
    end

    echo "rollback: complete. Reboot to switch to the rolled-back system state."
end

functions -e wp 2>/dev/null
function wp --description 'Restart hyprpaper detached'
    pkill hyprpaper 2>/dev/null
    nohup hyprpaper -c ~/.config/hypr/hypaper.conf >/dev/null 2>&1 &
end

function run_tmux
    command -qs tmux; or return
    if set -q TMUX
        tmux switch-client -t 1
        return
    end
    exec tmux new -A -s 1 -f ~/.config/tmux/tmux.conf
end

# Only on pure TTY login shells
if status is-interactive; and status is-login; and not set -q DISPLAY; and not set -q WAYLAND_DISPLAY; and string match -q -r '^/dev/tty[1-6]$' (tty)
    run_tmux
end
