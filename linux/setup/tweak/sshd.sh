#!/bin/bash
set -e

CFG=/etc/ssh/sshd_config

# Key-only login: disable password/interactive auth. `UsePAM no` is a
# DELIBERATE choice — with password auth off, key auth doesn't need PAM and
# this trims the auth surface. Trade-off: pam_systemd session setup is skipped
# for SSH logins; acceptable here. Revisit if password/2FA login is ever
# needed. Each directive is replaced if present, appended if missing.
for opt in PasswordAuthentication KbdInteractiveAuthentication ChallengeResponseAuthentication UsePAM; do
    if sudo grep -q "^$opt" "$CFG"; then
        sudo sed -i "s/^$opt.*/$opt no/" "$CFG"
    else
        echo "$opt no" | sudo tee -a "$CFG" >/dev/null
    fi
done

# Never hand sshd a broken config: validate BEFORE enabling/reloading. On
# failure the running daemon keeps its previous config and this tweak fails
# loudly (the tweak runner isolates and reports it).
if ! sudo sshd -t; then
    echo "🔴 sshd: config validation failed — NOT reloading sshd" >&2
    exit 1
fi

sudo systemctl enable --now sshd
sudo systemctl reload sshd
