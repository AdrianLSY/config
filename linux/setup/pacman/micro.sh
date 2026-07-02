#!/bin/bash
set -e

sudo pacman -S --noconfirm micro

# fish writes fish_variables on its first run; on a fresh machine it may not
# exist yet — skip then (a later bootstrap re-applies once fish has run).
FISH_VARS="$HOME/.config/fish/fish_variables"
if [ -f "$FISH_VARS" ]; then
    sed -i -e '/MICRO_TRUECOLOR/d' -e '/^# VERSION:.*/a SETUVAR --export MICRO_TRUECOLOR:1' "$FISH_VARS"
else
    echo "micro: $FISH_VARS not found (fish has not run yet) — skipping MICRO_TRUECOLOR"
fi
