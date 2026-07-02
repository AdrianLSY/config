#!/bin/bash
set -e

# Seat-scoped access to hidraw devices: uaccess makes systemd-logind grant an
# ACL to the ACTIVE seat user, instead of the old MODE="0666" world-writable
# nodes that let any local process sniff or inject HID traffic (keyboards
# included). The rule file is (re)written every run so rule changes deploy to
# machines that still carry the old version.
UDEV_RULE_FILE="/etc/udev/rules.d/99-hidraw-permissions.rules"

sudo tee "$UDEV_RULE_FILE" > /dev/null << 'EOF'
KERNEL=="hidraw*", SUBSYSTEM=="hidraw", TAG+="uaccess"
EOF

# Reload rules and re-trigger so logind applies ACLs to already-present nodes
# (replaces the old blanket `chmod a+rw /dev/hidraw*`).
sudo udevadm control --reload-rules
sudo udevadm trigger --subsystem-match=hidraw
