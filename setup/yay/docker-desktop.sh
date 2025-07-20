#!/bin/bash
set -e

yay -S --noconfirm docker-desktop

if ! gpg --list-keys | grep -q '^pub'; then
    gpg --batch --passphrase '' --quick-gen-key "Adrian Low <adrianlow1998@gmail.com>" default default never
fi
GPG_ID=$(gpg --list-keys --with-colons | awk -F: '/^pub/ { print $5; exit }')
if [[ -z "$GPG_ID" ]]; then
    echo "Error: Failed to get GPG key ID."
    exit 1
fi
if [[ ! -d "$HOME/.password-store" ]]; then
    pass init "$GPG_ID"
fi
