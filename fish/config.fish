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
    sudo pacman -Syyu --noconfirm
    yay -Syyu --noconfirm --answerclean All --answerdiff None --answeredit None
    flatpak update -y
    sudo pacman -Sc --noconfirm
    yay -Sc --noconfirm
    flatpak uninstall --unused -y
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
