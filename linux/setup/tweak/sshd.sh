#!/bin/bash
set -e

# Ensure the directives exist (insert if missing, replace if present)
for opt in PasswordAuthentication KbdInteractiveAuthentication ChallengeResponseAuthentication UsePAM; do
    sudo grep -q "^$opt" /etc/ssh/sshd_config && \
        sudo sed -i "s/^$opt.*/$opt no/" /etc/ssh/sshd_config || \
        echo "$opt no" | sudo tee -a /etc/ssh/sshd_config >/dev/null
done

sudo systemctl enable --now sshd
sudo systemctl reload sshd
