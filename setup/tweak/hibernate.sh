#!/bin/bash
set -e

FILE="/etc/systemd/logind.conf"

# Power button triggers hibernation
sudo sed -i '/^HandlePowerKey=/d' "$FILE" && echo 'HandlePowerKey=hibernate' | sudo tee -a "$FILE" > /dev/null
