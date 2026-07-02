#!/bin/bash
set -e

# DOCUMENTED DECISION: the firewall is intentionally disabled on this machine.
# Single-user desktop behind NAT; remote access comes in over tailscale and
# sshd is key-only (see sshd.sh). If that posture ever changes, replace this
# with `ufw enable` plus a tailscale-interface-only ruleset — see the open
# question in openspec change fix-bootstrap-review-findings.
echo "⚠️  ufw: intentionally DISABLING the firewall (documented decision — see $0)"
sudo ufw disable
