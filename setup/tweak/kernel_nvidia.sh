#!/bin/bash

set -e

FILE="/boot/loader/entries/linux-cachyos.conf"

REQUIRED_PARAMS=(
  "nvidia_drm.modeset=1"
  # "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
)

MISSING_PARAMS=()

if ! command -v nvidia-smi &> /dev/null; then
  echo "nvidia-smi not found. NVIDIA drivers might not be installed. Exiting."
  exit 1
fi

for param in "${REQUIRED_PARAMS[@]}"; do
  if ! sudo grep -qw "$param" "$FILE"; then
    MISSING_PARAMS+=("$param")
  fi
done

if [ ${#MISSING_PARAMS[@]} -gt 0 ]; then
  sudo sed -i "/^options / s|\$| ${MISSING_PARAMS[*]}|" "$FILE"
fi

sudo mkinitcpio -P
