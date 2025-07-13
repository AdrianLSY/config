#!/bin/bash
set -e

# Disables all USB devices from waking the system
if [ -f "$HOME/.config/hypr/scripts/wakeup" ]; then
    sudo tee /etc/systemd/system/wakeup.service > /dev/null << EOF
[Unit]
Description=Disable ACPI wakeup devices after boot
After=multi-user.target

[Service]
Type=oneshot
ExecStart=$HOME/.config/hypr/scripts/wakeup

[Install]
WantedBy=multi-user.target
EOF
    sudo systemctl enable wakeup.service
fi
