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
