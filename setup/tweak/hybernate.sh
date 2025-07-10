#!/bin/bash
set -e

# Power button triggers hybernation
sudo sed -i '/^HandlePowerKey=/d' /etc/systemd/logind.conf && echo 'HandlePowerKey=hibernate' | sudo tee -a /etc/systemd/logind.conf > /dev/null
