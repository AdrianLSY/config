#!/usr/bin/env bash

dir="$HOME/.config/rofi/clipboard"
theme='style'

wl-clipboard-history -l 50 \
    | rofi -dmenu -theme "${dir}/${theme}.rasi" -p "󰅎" \
    | sed 's/^[0-9]\+,//' \
    | wl-copy
