#!/bin/bash
set -e

# Install erlang if not already installed
if ! asdf plugin list | grep -qx "erlang" || ! asdf list erlang 2>/dev/null | grep -q .; then
    asdf plugin add erlang
    asdf install erlang latest
fi

VERSION=$(asdf list erlang | tail -1 | tr -d ' *')
if [[ "$VERSION" =~ ^[0-9] ]]; then
    sed -i "/^erlang /d" ~/.tool-versions && echo "erlang $VERSION" >> ~/.tool-versions
else
    echo "WARNING: could not resolve installed version for erlang, skipping ~/.tool-versions update" >&2
fi

# Elixir requires a compatible Erlang/OTP installation
OTP_VERSION=$(asdf list erlang 2>/dev/null | tail -1 | tr -d ' *' | cut -d. -f1)
if [[ -z "$OTP_VERSION" ]] || ! [[ "$OTP_VERSION" =~ ^[0-9]+$ ]]; then
    echo "ERROR: no erlang version installed via asdf, cannot install elixir" >&2
    exit 1
fi

export ELIXIR_OTP_RELEASE="$OTP_VERSION"

asdf plugin add elixir
asdf install elixir latest

VERSION=$(asdf list elixir | tail -1 | tr -d ' *')
if [[ "$VERSION" =~ ^[0-9] ]]; then
    sed -i "/^elixir /d" ~/.tool-versions && echo "elixir $VERSION" >> ~/.tool-versions
else
    echo "WARNING: could not resolve installed version for elixir, skipping ~/.tool-versions update" >&2
fi
