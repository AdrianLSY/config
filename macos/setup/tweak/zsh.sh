#!/bin/bash
set -e

# Point zsh to ~/.config/zsh
echo 'export ZDOTDIR="$HOME/.config/zsh"' > "$HOME/.zshenv"

# Overwrite any old ~/.zshrc with a redirect to the new location
rm -f "$HOME/.zshrc" "$HOME/.zshrc.zwc" "$HOME/.zprofile"

# Homebrew's shellenv is already sourced by the tracked zsh/.zprofile, so there
# is nothing to append here. (The old append also ran before configs were copied
# into ~/.config, so it failed when ~/.config/zsh did not yet exist.)

# Install zinit
if [[ ! -d "$HOME/.local/share/zinit" ]]; then
    bash -c "$(curl -fsSL https://raw.githubusercontent.com/zdharma-continuum/zinit/HEAD/scripts/install.sh)"
fi
