#!/bin/bash
set -e

# Allow any client from subnet to connect to this machine

# Get current subnet
SUBNET=$(ip -4 addr show scope global | awk '/inet / {print $2; exit}')

# Get network part
NETWORK=$(ipcalc -n "$SUBNET" | awk -F'=' '/NETWORK/ {print $2}')$(echo "$SUBNET" | grep -o "/[0-9]\+")
ALLOW_SUBNET="$NETWORK"

# Check if rule already exists
if sudo ufw status | grep -qw "$ALLOW_SUBNET"; then
    echo "Rule for $ALLOW_SUBNET already exists. Nothing to do."
else
    sudo ufw allow from "$ALLOW_SUBNET"
    echo "Allowed all incoming connections from $ALLOW_SUBNET"
fi
