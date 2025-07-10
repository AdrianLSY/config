#!/bin/bash
set -e

LOADER_CONF="/boot/loader/entries/linux-cachyos.conf"

if ! grep -q "nvidia_drm.modeset=1" "$LOADER_CONF" || ! grep -q "nvidia.NVreg_PreserveVideoMemoryAllocations=1" "$LOADER_CONF"; then
  sed -i "/^options / s|\$| nvidia_drm.modeset=1 nvidia.NVreg_PreserveVideoMemoryAllocations=1|" "$LOADER_CONF"
  echo "Patched $LOADER_CONF with NVIDIA kernel parameters."
fi
