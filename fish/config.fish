source /usr/share/cachyos-fish-config/cachyos-config.fish
set -x BROWSER zen-browser

function run_tmux
    if tmux has-session -t 1 2>/dev/null
        if test -n "$TMUX"
            tmux switch-client -t 1
        else
            tmux attach -t 1
        end
    else
        tmux new -s 1 -f ~/.config/tmux/tmux.conf
    end
end

function fish_greeting
    # Disable fastfetch
    # fastfetch
end

# Only run tmux in a pure TTY (no X11/Wayland session)
if test -z "$DISPLAY" -a -z "$WAYLAND_DISPLAY"
    run_tmux
end
