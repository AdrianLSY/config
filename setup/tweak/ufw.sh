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

VIRBR0_CIDR=$(ip -4 addr show virbr0 | awk '/inet / {print $2; exit}')

if [ -n "$VIRBR0_CIDR" ]; then
    VIRBR0_SUBNET=$(echo "$VIRBR0_CIDR" | sed 's|/[0-9]\+$||')
    VIRBR0_HOST="${VIRBR0_SUBNET%.*}.1"

    if ! sudo ufw status | grep -qw "$VIRBR0_CIDR"; then
        sudo ufw allow in on virbr0 from "$VIRBR0_CIDR"
        sudo ufw allow out on virbr0 to "$VIRBR0_CIDR"
    fi

    sudo ufw allow in on virbr0 proto udp from "$VIRBR0_CIDR" to "$VIRBR0_HOST" port 67
    sudo ufw allow out on virbr0 proto udp from "$VIRBR0_HOST" to "$VIRBR0_CIDR" port 68

    sudo ufw allow in on virbr0 proto udp to "$VIRBR0_HOST" port 53
    sudo ufw allow out on virbr0 proto udp from "$VIRBR0_HOST" to "$VIRBR0_CIDR" port 53
    sudo ufw allow in on virbr0 proto tcp to "$VIRBR0_HOST" port 53
    sudo ufw allow out on virbr0 proto tcp from "$VIRBR0_HOST" to "$VIRBR0_CIDR" port 53

    sudo ufw route allow in on virbr0
    sudo ufw route allow out on virbr0
fi

sudo ufw reload
