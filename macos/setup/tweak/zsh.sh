#!/bin/bash
set -e

# Point zsh to ~/.config/zsh. Desired ~/.zshenv content (single line).
# shellcheck disable=SC2016  # literal $HOME is intentional — expands at shell startup
ZSHENV_LINE='export ZDOTDIR="$HOME/.config/zsh"'

# Pre-existing user shell config that would shadow the repo's zsh setup is
# BACKED UP, never deleted — same .bak.<timestamp> convention as lib/link.sh.
# (Compiled *.zwc artifacts are regenerable, so plain removal is fine there.)
for f in "$HOME/.zshrc" "$HOME/.zprofile"; do
    if [ -e "$f" ] || [ -L "$f" ]; then
        bak="$f.bak.$(date +%Y%m%d%H%M%S)"
        n=1
        while [ -e "$bak" ] || [ -L "$bak" ]; do
            bak="$f.bak.$(date +%Y%m%d%H%M%S).$n"
            n=$((n + 1))
        done
        mv "$f" "$bak"
        echo "zsh: backed up $f -> $bak"
    fi
done
rm -f "$HOME/.zshrc.zwc"

# Only rewrite ~/.zshenv when its content differs, so a re-run is a no-op.
if [ ! -f "$HOME/.zshenv" ] || [ "$(cat "$HOME/.zshenv")" != "$ZSHENV_LINE" ]; then
    printf '%s\n' "$ZSHENV_LINE" > "$HOME/.zshenv"
fi

# Homebrew's shellenv is already sourced by the tracked zsh/.zprofile, so there
# is nothing to append here. (The old append also ran before configs were copied
# into ~/.config, so it failed when ~/.config/zsh did not yet exist.)

# Install zinit
if [[ ! -d "$HOME/.local/share/zinit" ]]; then
    bash -c "$(curl -fsSL https://raw.githubusercontent.com/zdharma-continuum/zinit/HEAD/scripts/install.sh)"
fi
