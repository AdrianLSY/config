#!/bin/bash
set -e

sudo pacman -S --noconfirm micro

sed -i -e '/MICRO_TRUECOLOR/d' -e '/^# VERSION:.*/a SETUVAR --export MICRO_TRUECOLOR:1' /home/adrian/.config/fish/fish_variables
