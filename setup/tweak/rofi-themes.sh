#!/bin/bash
set -e

if [ -d "rofi-themes" ]; then
    rm -rf rofi-themes
fi
git clone https://github.com/AdrianLSY/rofi-themes.git
chmod +x rofi-themes/setup.sh
./rofi-themes/setup.sh
rm -rf rofi-themes
