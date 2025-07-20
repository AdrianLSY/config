#!/usr/bin/env bash

dir="$HOME/.config/rofi/clipboard"
theme='style'

## Run
wl-clipboard-history -l 50 | rofi \
    -dmenu \
    -theme "${dir}/${theme}.rasi" \
    -p "󰅎" | wl-copy
