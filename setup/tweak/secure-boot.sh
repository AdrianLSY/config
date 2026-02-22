#!/bin/bash
set -e

# Check if running on UEFI system
if [[ ! -d /sys/firmware/efi ]]; then
    echo "ERROR: not booted in UEFI mode, skipping Secure Boot setup" >&2
    exit 0
fi

# Check if sbctl is installed
if ! command -v sbctl &>/dev/null; then
    echo "ERROR: sbctl is not installed, run: sudo pacman -S sbctl" >&2
    exit 0
fi

# Check if systemd-boot is the bootloader
if ! sudo bootctl status &>/dev/null; then
    echo "ERROR: systemd-boot not detected, skipping Secure Boot setup" >&2
    exit 0
fi

# If Secure Boot is already enabled and all files are signed, nothing to do
SB_STATUS=$(sudo bootctl status 2>/dev/null | grep "Secure Boot:" | awk '{print $3}' || echo "unknown")
if [[ "$SB_STATUS" == "enabled" ]]; then
    if ! sudo sbctl verify 2>&1 | grep -q "✗"; then
        exit 0
    else
        echo "WARNING: Secure Boot is enabled but some files are unsigned, re-signing" >&2
    fi
fi

# --- Key Generation ---

SECUREBOOT_DIR="/var/lib/sbctl"

if [[ ! -d "$SECUREBOOT_DIR/keys" ]] || [[ ! -f "$SECUREBOOT_DIR/keys/db/db.key" ]]; then
    if ! sudo sbctl create-keys &>/dev/null; then
        echo "ERROR: failed to create Secure Boot keys" >&2
        exit 1
    fi
fi

# --- Sign Boot Components ---

SIGN_FAILED=0

sign_file() {
    local file="$1"
    if ! sudo sbctl sign -s "$file" &>/dev/null; then
        echo "ERROR: failed to sign $file" >&2
        SIGN_FAILED=$(( SIGN_FAILED + 1 ))
    fi
}

sign_file "/boot/EFI/BOOT/BOOTX64.EFI"
sign_file "/boot/EFI/systemd/systemd-bootx64.efi"

while IFS= read -r kernel; do
    sign_file "$kernel"
done < <(sudo find /boot -maxdepth 1 -name "vmlinuz-*" 2>/dev/null)

while IFS= read -r kernel; do
    sign_file "$kernel"
done < <(sudo find /boot -mindepth 3 -maxdepth 3 -name "linux" 2>/dev/null)

if [[ $SIGN_FAILED -gt 0 ]]; then
    echo "ERROR: $SIGN_FAILED file(s) failed to sign" >&2
    exit 1
fi

# --- Verify ---

VERIFY_OUTPUT=$(sudo sbctl verify 2>&1)
UNSIGNED=$(echo "$VERIFY_OUTPUT" | grep "✗" | grep -v -E "(Microsoft|EFI.backup)" || true)

if [[ -n "$UNSIGNED" ]]; then
    echo "ERROR: unsigned files remain after signing:" >&2
    echo "$UNSIGNED" >&2
    exit 1
fi

# --- Check Pacman Hook ---

if [[ ! -f "/usr/share/libalpm/hooks/zz-sbctl.hook" ]]; then
    echo "WARNING: sbctl pacman hook not found, kernel updates may not be signed automatically" >&2
fi
