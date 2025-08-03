#!/bin/bash

# Wake up (wake up)
# Grab a brush and put a little make-up
# Hide the scars to fade away the shake-up
# Why'd you leave the keys upon the table?
# Here you go create another fable
# You wanted to
# Grab a brush and put a little makeup
# You wanted to
# Hide the scars to fade away the shake-up
# You wanted to
# Why'd you leave the keys upon the table?
# You wanted to
# I don't think you trust
# In
# my
# self-righteous suicide
# I
# cry
# when angels deserve to
# Die

set -e

# Disables all USB devices from waking the system
if [ ! -f "/etc/systemd/system/wakeup.service" ]; then
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

"$HOME/.config/hypr/scripts/wakeup"
