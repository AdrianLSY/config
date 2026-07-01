#!/bin/bash
set -e

asdf plugin add bun
asdf install bun latest

VERSION=$(asdf list bun | tail -1 | tr -d ' *')
if [[ "$VERSION" =~ ^[0-9] ]]; then
    sed -i "/^bun /d" ~/.tool-versions && echo "bun $VERSION" >> ~/.tool-versions
else
    echo "WARNING: could not resolve installed version for bun, skipping ~/.tool-versions update" >&2
fi
