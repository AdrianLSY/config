#!/bin/bash
set -e

asdf plugin add ruby
asdf install ruby latest

VERSION=$(asdf list ruby | tail -1 | tr -d ' *')
if [[ "$VERSION" =~ ^[0-9] ]]; then
    sed -i "/^ruby /d" ~/.tool-versions && echo "ruby $VERSION" >> ~/.tool-versions
else
    echo "WARNING: could not resolve installed version for ruby, skipping ~/.tool-versions update" >&2
fi
