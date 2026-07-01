function update --description 'Refresh mirrors, update pacman/AUR/flatpak/firmware, then cleanup'
    sudo cachyos-rate-mirrors
    sudo reflector --latest 20 --sort rate --protocol https --save /etc/pacman.d/mirrorlist
    sudo pacman -Sy --noconfirm archlinux-keyring cachyos-keyring
    sudo pacman -Syyu --noconfirm
    PATH=/usr/bin:/bin yay -Sua --noconfirm --answerclean All --answerdiff None --answeredit None
    flatpak update -y
    if command -q fwupdmgr
        sudo fwupdmgr refresh --force; or true
        sudo fwupdmgr update -y; or true
    end
    set -l orphans (pacman -Qtdq 2>/dev/null)
    if test -n "$orphans"
        sudo pacman -Rns --noconfirm $orphans
    end
    sudo rm -rf /var/cache/pacman/pkg/download-*
    sudo paccache -rk2
    sudo paccache -ruk0
    yay -Sc --noconfirm
    flatpak uninstall --unused -y
end
