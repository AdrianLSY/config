#!/bin/bash
set -e

LOADER_CONF="/boot/loader/entries/linux-cachyos.conf"

REQUIRED_PARAMS=(
  "pci=noaer"
  "no_console_suspend"
  "libata.force=noncq"
  "nvidia_drm.modeset=1"
  "usbcore.autosuspend=-1"
  "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
)

MISSING_PARAMS=()

for param in "${REQUIRED_PARAMS[@]}"; do
  if ! sudo grep -qw "$param" "$LOADER_CONF"; then
    MISSING_PARAMS+=("$param")
  fi
done

if [ ${#MISSING_PARAMS[@]} -gt 0 ]; then
  sudo sed -i "/^options / s|\$| ${MISSING_PARAMS[*]}|" "$LOADER_CONF"
fi
