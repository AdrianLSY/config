alias ff='fastfetch'
alias bios='sudo systemctl reboot --firmware-setup'
alias uefi='sudo systemctl reboot --firmware-setup'

# Function to restart hyprpaper detached
functions -e wp
function wp --description 'Restart hyprpaper detached'
    pkill hyprpaper 2>/dev/null
    nohup hyprpaper -c ~/.config/hypr/hypaper.conf >/dev/null 2>&1 &
end
