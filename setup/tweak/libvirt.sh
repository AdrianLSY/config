#!/bin/bash
set -e

FILE="/etc/libvirt/libvirtd.conf"

sudo sed -i '/^unix_sock_group *=/d' "$FILE" && echo 'unix_sock_group = "libvirt"' | sudo tee -a "$FILE" > /dev/null
sudo sed -i '/^unix_sock_rw_perms *=/d' "$FILE" && echo 'unix_sock_rw_perms = "0770"' | sudo tee -a "$FILE" > /dev/null

sudo usermod -a -G libvirt "${SUDO_USER:-$(whoami)}"
