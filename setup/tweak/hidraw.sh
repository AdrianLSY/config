#!/bin/bash
set -e

# Create udev rule for hidraw devices
UDEV_RULE_FILE="/etc/udev/rules.d/99-hidraw-permissions.rule"

if [ ! -f "$UDEV_RULE_FILE" ]; then
    sudo tee "$UDEV_RULE_FILE" > /dev/null << 'EOF'
KERNEL=="hidraw*", ACTION=="add", MODE="0755"
EOF
fi

# Always reload udev rules to ensure they're active
sudo udevadm control --reload-rules
sudo udevadm trigger --subsystem-match=hidraw

# Apply permissions to existing hidraw devices
if ls /dev/hidraw* 1> /dev/null 2>&1; then
    sudo chmod a+rx /dev/hidraw*
fi
