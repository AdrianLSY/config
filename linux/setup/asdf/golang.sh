#!/bin/bash
set -e

asdf plugin add golang
asdf install golang latest

VERSION=$(asdf list golang | tail -1 | tr -d ' *')
if [[ "$VERSION" =~ ^[0-9] ]]; then
    sed -i "/^golang /d" ~/.tool-versions && echo "golang $VERSION" >> ~/.tool-versions
else
    echo "WARNING: could not resolve installed version for golang, skipping ~/.tool-versions update" >&2
fi
