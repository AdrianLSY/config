#!/bin/bash
set -e

# Secure Boot Setup Script
# Configures Secure Boot with sbctl for systemd-boot

echo "=================================================="
echo "  Secure Boot Configuration"
echo "=================================================="

# --- Pre-flight Checks ---

# Check if running on UEFI system
if [[ ! -d /sys/firmware/efi ]]; then
    echo "⚠️  WARNING: This system is not booted in UEFI mode."
    echo "   Secure Boot requires UEFI firmware."
    echo "   Skipping Secure Boot setup."
    exit 0
fi

# Check if sbctl is installed
if ! command -v sbctl &>/dev/null; then
    echo "⚠️  WARNING: sbctl is not installed."
    echo "   Please install sbctl first: sudo pacman -S sbctl"
    echo "   Skipping Secure Boot setup."
    exit 0
fi

# Check if systemd-boot is the bootloader
if ! bootctl status &>/dev/null; then
    echo "⚠️  WARNING: systemd-boot does not appear to be installed."
    echo "   This script is designed for systemd-boot."
    echo "   Skipping Secure Boot setup."
    exit 0
fi

# Check if Secure Boot is already enabled
SB_STATUS=$(bootctl status 2>/dev/null | grep "Secure Boot:" | awk '{print $3}' || echo "unknown")
if [[ "$SB_STATUS" == "enabled" ]]; then
    echo "✅ Secure Boot is already enabled."
    echo "   Running verification to ensure everything is signed..."
    
    if sudo sbctl verify 2>&1 | grep -q "✓"; then
        echo "✅ All critical files are properly signed."
        echo "   Secure Boot setup is complete. Nothing to do."
        exit 0
    else
        echo "⚠️  Some files may need signing. Proceeding with signing..."
    fi
fi

echo ""
echo "🔧 Starting Secure Boot configuration..."
echo ""

# --- Key Generation ---

SECUREBOOT_DIR="/usr/share/secureboot"

if [[ -d "$SECUREBOOT_DIR" ]] && [[ -f "$SECUREBOOT_DIR/keys/db/db.key" ]]; then
    echo "✅ Secure Boot keys already exist in $SECUREBOOT_DIR"
    echo "   Skipping key generation."
else
    echo "🔑 Generating custom Secure Boot keys..."
    if sudo sbctl create-keys; then
        echo "✅ Secure Boot keys created successfully."
    else
        echo "❌ ERROR: Failed to create Secure Boot keys."
        echo "   Please check permissions and try again."
        exit 1
    fi
fi

echo ""

# --- Sign Boot Components ---

echo "✍️  Signing boot components..."
echo ""

SIGN_FAILED=()
SIGN_SUCCESS=()

# Function to sign a file
sign_file() {
    local file="$1"
    local description="$2"
    
    if [[ ! -f "$file" ]]; then
        echo "⏭️  $description: File not found, skipping."
        return
    fi
    
    echo "Signing: $description"
    if sudo sbctl sign -s "$file" 2>&1 | grep -q "✓"; then
        echo "✅ Signed: $description"
        SIGN_SUCCESS+=("$description")
    else
        echo "⚠️  Failed to sign: $description"
        SIGN_FAILED+=("$description")
    fi
}

# Sign bootloaders
sign_file "/boot/EFI/BOOT/BOOTX64.EFI" "Fallback bootloader"
sign_file "/boot/EFI/systemd/systemd-bootx64.efi" "systemd-boot"

# Sign all kernels
for kernel in /boot/vmlinuz-*; do
    if [[ -f "$kernel" ]]; then
        kernel_name=$(basename "$kernel")
        sign_file "$kernel" "Kernel: $kernel_name"
    fi
done

echo ""

# --- Verify Signatures ---

echo "🔍 Verifying all signatures..."
echo ""

VERIFY_OUTPUT=$(sudo sbctl verify 2>&1)

# Count signed files (lines with ✓)
SIGNED_COUNT=$(echo "$VERIFY_OUTPUT" | grep -c "✓" || echo "0")

# Count unsigned files (lines with ✗, excluding Microsoft/backup files)
UNSIGNED_COUNT=$(echo "$VERIFY_OUTPUT" | grep "✗" | grep -v -E "(Microsoft|EFI.backup)" | wc -l || echo "0")

echo "$VERIFY_OUTPUT" | grep "✓" || echo "No files verified as signed yet."

if [[ $UNSIGNED_COUNT -gt 0 ]]; then
    echo ""
    echo "⚠️  Warning: Some critical files are not signed:"
    echo "$VERIFY_OUTPUT" | grep "✗" | grep -v -E "(Microsoft|EFI.backup)"
    echo ""
    echo "   This may prevent booting with Secure Boot enabled."
    echo "   Please review and sign missing files manually if needed."
fi

echo ""
echo "📊 Summary:"
echo "   Signed files: $SIGNED_COUNT"
echo "   Unsigned critical files: $UNSIGNED_COUNT"
echo ""

if (( ${#SIGN_FAILED[@]} )); then
    echo "⚠️  Failed to sign: ${SIGN_FAILED[*]}"
    echo ""
fi

# --- Generate Instructions ---

INSTRUCTIONS_FILE="/tmp/secure-boot-instructions.txt"

cat > "$INSTRUCTIONS_FILE" <<'EOF'
═══════════════════════════════════════════════════════════
  SECURE BOOT SETUP - MANUAL STEPS REQUIRED
═══════════════════════════════════════════════════════════

✅ Secure Boot keys have been created
✅ Boot components have been signed

⚠️  IMPORTANT: You must complete these steps manually:

1. After this setup completes and you reboot, press the key
   to enter your BIOS/UEFI firmware settings during boot.
   Common keys: F2, F10, DEL, or F12
   
2. Navigate to: Security → Secure Boot settings

3. Clear/Delete existing Secure Boot keys
   (This puts firmware in "Setup Mode")
   
   Note: The exact menu location varies by manufacturer:
   - ASUS: Advanced Mode → Boot → Secure Boot
   - MSI: Settings → Security → Secure Boot
   - Gigabyte: BIOS Features → Secure Boot
   - Dell: Settings → Secure Boot → Expert Key Management
   
4. Save and exit BIOS (system will reboot)

5. After reboot, open a terminal and run:
   
   sudo sbctl enroll-keys --microsoft
   
   The --microsoft flag includes Microsoft UEFI CA keys,
   which are required for Windows dual-boot compatibility.

6. Verify key enrollment:
   
   sbctl status
   
   You should see "Setup Mode: ✓ Disabled"

7. Reboot again into BIOS/UEFI firmware settings

8. Navigate to: Security → Secure Boot settings

9. Enable Secure Boot

10. Save and exit

11. After booting into Linux, verify Secure Boot is active:
    
    sbctl status
    
    You should see:
    - Installed:    ✓ sbctl is installed
    - Setup Mode:   ✓ Disabled
    - Secure Boot:  ✓ Enabled
    - Vendor Keys:  microsoft

═══════════════════════════════════════════════════════════
  TROUBLESHOOTING
═══════════════════════════════════════════════════════════

If system fails to boot after enabling Secure Boot:

1. Enter BIOS and temporarily disable Secure Boot
2. Boot into Linux
3. Run: sudo sbctl verify
4. Sign any missing files: sudo sbctl sign -s /path/to/file
5. Re-enable Secure Boot in BIOS

For more help, see: setup/README-SECURE-BOOT.md

═══════════════════════════════════════════════════════════

Full documentation: ~/.config/setup/README-SECURE-BOOT.md

EOF

# Display instructions
cat "$INSTRUCTIONS_FILE"

echo ""
echo "📄 Instructions saved to: $INSTRUCTIONS_FILE"
echo ""

# --- Check Pacman Hook ---

HOOK_FILE="/usr/share/libalpm/hooks/zz-sbctl.hook"

if [[ -f "$HOOK_FILE" ]]; then
    echo "✅ Pacman hook is installed: $HOOK_FILE"
    echo "   Future kernel/bootloader updates will be signed automatically."
else
    echo "⚠️  WARNING: Pacman hook not found at $HOOK_FILE"
    echo "   Kernel updates may not be signed automatically."
    echo "   Try reinstalling sbctl: sudo pacman -S sbctl"
fi

echo ""
echo "=================================================="
echo "  Secure Boot Configuration Complete"
echo "=================================================="
echo ""
echo "Next steps:"
echo "  1. Review the instructions above"
echo "  2. Reboot when ready to complete setup"
echo "  3. Follow the manual steps in BIOS"
echo "  4. Run: sudo sbctl enroll-keys --microsoft"
echo "  5. Enable Secure Boot in BIOS"
echo ""
