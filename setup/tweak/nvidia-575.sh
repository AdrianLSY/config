#!/usr/bin/env bash
set -e

# Roll back NVIDIA userspace to 575.64.05 and pair it with a matching CachyOS kernel snapshot.

sudo pacman -U --noconfirm \
  https://archive.cachyos.org/archive/cachyos/linux-cachyos-6.16.0-3-x86_64_v3.pkg.tar.zst \
  https://archive.cachyos.org/archive/cachyos/linux-cachyos-headers-6.16.0-3-x86_64_v3.pkg.tar.zst \
  https://archive.cachyos.org/archive/cachyos/linux-cachyos-nvidia-open-6.16.0-3-x86_64_v3.pkg.tar.zst \
  https://archive.archlinux.org/packages/n/nvidia-utils/nvidia-utils-575.64.05-2-x86_64.pkg.tar.zst \
  https://archive.archlinux.org/packages/l/lib32-nvidia-utils/lib32-nvidia-utils-575.64.05-1-x86_64.pkg.tar.zst

sudo mkinitcpio -P
