#!/bin/bash
set -e

FILE="/boot/loader/entries/linux-cachyos.conf"

REQUIRED_PARAMS=(
  "pci=noaer"
  "no_console_suspend"
  "libata.force=noncq"
  "usbcore.autosuspend=-1"
)

MISSING_PARAMS=()

for param in "${REQUIRED_PARAMS[@]}"; do
  if ! sudo grep -qw "$param" "$FILE"; then
    MISSING_PARAMS+=("$param")
  fi
done

if [ ${#MISSING_PARAMS[@]} -gt 0 ]; then
  sudo sed -i "/^options / s|\$| ${MISSING_PARAMS[*]}|" "$FILE"
fi

sudo mkinitcpio -P
