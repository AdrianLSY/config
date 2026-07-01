#!/bin/bash
set -e

asdf plugin add rust
asdf install rust latest

VERSION=$(asdf list rust | tail -1 | tr -d ' *')
if [[ "$VERSION" =~ ^[0-9] ]]; then
    sed -i "/^rust /d" ~/.tool-versions && echo "rust $VERSION" >> ~/.tool-versions
else
    echo "WARNING: could not resolve installed version for rust, skipping ~/.tool-versions update" >&2
fi
