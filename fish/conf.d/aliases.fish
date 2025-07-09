if status is-interactive
    alias ff='fastfetch'
    alias bios='sudo systemctl reboot --firmware-setup'
    alias uefi='sudo systemctl reboot --firmware-setup'
    alias w11='sudo bootctl set-oneshot auto-windows && sudo reboot'
end
