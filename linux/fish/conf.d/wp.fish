function wp --description 'Restart hyprpaper detached'
    pkill hyprpaper 2>/dev/null
    nohup hyprpaper -c ~/.config/hypr/hypaper.conf >/dev/null 2>&1 &
end
