#!/bin/bash
set -e

# Add Homebrew to zsh profile
if ! grep -q 'brew shellenv' "$HOME/.zprofile" 2>/dev/null; then
    echo >> "$HOME/.zprofile"
    echo 'eval "$(/opt/homebrew/bin/brew shellenv zsh)"' >> "$HOME/.zprofile"
fi

# Install zinit
if [[ ! -d "$HOME/.local/share/zinit" ]]; then
    bash -c "$(curl -fsSL https://raw.githubusercontent.com/zdharma-continuum/zinit/HEAD/scripts/install.sh)"
fi
