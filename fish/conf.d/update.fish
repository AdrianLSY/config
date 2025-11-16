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
