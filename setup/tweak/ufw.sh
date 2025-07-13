#!/bin/bash
set -e

# Get current subnet in CIDR notation (e.g., 192.168.1.0/24)
SUBNET=$(ip -4 addr show scope global | awk '/inet / {print $2; exit}')

# Use subnet directly
ALLOW_SUBNET="$SUBNET"

if sudo ufw status | grep -qw "$ALLOW_SUBNET"; then
    echo "Rule for $ALLOW_SUBNET already exists. Nothing to do."
else
    sudo ufw allow from "$ALLOW_SUBNET"
fi
