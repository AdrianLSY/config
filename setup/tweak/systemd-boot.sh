#!/bin/bash
set -e

# Skips systemd-boot os selector
sudo sed -i '/^timeout /d' /boot/loader/loader.conf && echo 'timeout 0' | sudo tee -a /boot/loader/loader.conf > /dev/null
