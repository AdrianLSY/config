#!/bin/bash
set -e

# Point zsh to ~/.config/zsh
echo 'export ZDOTDIR="$HOME/.config/zsh"' > "$HOME/.zshenv"

# Overwrite any old ~/.zshrc with a redirect to the new location
rm -f "$HOME/.zshrc" "$HOME/.zshrc.zwc" "$HOME/.zprofile"

# Add Homebrew to zsh profile
if ! grep -q 'brew shellenv' "$HOME/.config/zsh/.zprofile" 2>/dev/null; then
    echo >> "$HOME/.config/zsh/.zprofile"
    echo 'eval "$(/opt/homebrew/bin/brew shellenv zsh)"' >> "$HOME/.config/zsh/.zprofile"
fi

# Install zinit
if [[ ! -d "$HOME/.local/share/zinit" ]]; then
    bash -c "$(curl -fsSL https://raw.githubusercontent.com/zdharma-continuum/zinit/HEAD/scripts/install.sh)"
fi
