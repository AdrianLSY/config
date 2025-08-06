#!/bin/bash
set -e

# Allow all hidraw devices
if [ ! -f "/etc/systemd/system/hidraw.service" ]; then
    sudo tee /etc/systemd/system/hidraw.service > /dev/null << EOF
[Unit]
Description=Disable ACPI hidraw devices after boot
After=multi-user.target

[Service]
Type=oneshot
ExecStart=$HOME/.config/hypr/scripts/hidraw

[Install]
WantedBy=multi-user.target
EOF
    sudo systemctl enable hidraw.service
fi

"$HOME/.config/hypr/scripts/hidraw"
