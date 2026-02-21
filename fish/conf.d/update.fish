function update --description 'Unattended update pacman, yay, flatpak; then cleanup'
    sudo pacman -Syyu --noconfirm
    yay -Syyu --noconfirm --answerclean All --answerdiff None --answeredit None
    flatpak update -y
    sudo pacman -Sc --noconfirm
    yay -Sc --noconfirm
    flatpak uninstall --unused -y
end
