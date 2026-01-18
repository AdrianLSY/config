# Secure Boot Setup Automation

This directory contains automated Secure Boot setup for CachyOS Linux systems using systemd-boot.

## Overview

Secure Boot is a UEFI firmware feature that ensures only trusted software can boot on your system. This automation:

- Installs `sbctl` (Secure Boot Control utility)
- Generates custom Secure Boot keys
- Signs all boot components (bootloader, kernels)
- Includes Microsoft keys for Windows dual-boot compatibility
- Configures automatic signing of future kernel updates via pacman hooks

## System Requirements

- **UEFI firmware** (not legacy BIOS)
- **systemd-boot** bootloader
- **TPM2** (optional, but recommended for additional security)
- **Administrator access** (sudo privileges)

## What Gets Automated

### ✅ Fully Automated Steps

1. **sbctl installation** (`setup/pacman/sbctl.sh`)
   - Installs sbctl package via pacman
   - Integrated into standard pacman module

2. **Key generation** (`setup/tweak/secure-boot.sh`)
   - Creates custom Secure Boot keys (PK, KEK, db)
   - Generates unique Owner UUID
   - Keys stored in `/usr/share/secureboot/`

3. **Boot component signing**
   - Systemd-boot bootloader: `/boot/EFI/BOOT/BOOTX64.EFI`, `/boot/EFI/systemd/systemd-bootx64.efi`
   - All installed kernels: `/boot/vmlinuz-*`
   - Verifies all signatures

4. **Pacman hook setup**
   - Installs `/usr/share/libalpm/hooks/zz-sbctl.hook`
   - Automatically signs new kernels and EFI binaries on updates
   - No manual intervention needed for future updates

### ⚠️ Manual Steps Required

**You must complete these steps manually** after the automated setup:

1. **Enter firmware setup mode**
   - Reboot into BIOS/UEFI settings (usually F2, F10, DEL, or F12 during boot)
   - Navigate to: Security → Secure Boot settings
   - Clear/Delete all existing Secure Boot keys
   - This puts firmware into "Setup Mode"
   - Save and exit (system will reboot)

2. **Enroll custom keys**
   - After reboot, open terminal and run:
     ```bash
     sudo sbctl enroll-keys --microsoft
     ```
   - The `--microsoft` flag includes Microsoft UEFI CA and Windows Production PCA keys
   - This ensures Windows continues to boot in dual-boot setups

3. **Enable Secure Boot**
   - Reboot into BIOS/UEFI settings again
   - Navigate to: Security → Secure Boot settings
   - **Enable Secure Boot**
   - Save and exit

4. **Verify setup**
   - After boot, verify Secure Boot is active:
     ```bash
     sbctl status
     ```
   - You should see:
     ```
     Installed:    ✓ sbctl is installed
     Setup Mode:   ✓ Disabled
     Secure Boot:  ✓ Enabled
     Vendor Keys:  microsoft
     ```

## Architecture

### Key Components

**PK (Platform Key)**
- Top-level key that controls all other keys
- Only one PK can be enrolled at a time
- Controls who can modify KEK

**KEK (Key Exchange Key)**
- Controls who can modify signature databases (db, dbx)
- Multiple KEKs can be enrolled

**db (Signature Database)**
- Contains trusted signatures and certificates
- Allows signed binaries to boot
- Includes your custom key + Microsoft keys

**dbx (Forbidden Signature Database)**
- Contains revoked/blacklisted signatures
- Prevents known-bad binaries from booting

### File Locations

| Item | Location | Purpose |
|------|----------|---------|
| Keys | `/usr/share/secureboot/` | Your custom Secure Boot keys (PK, KEK, db) |
| Hook | `/usr/share/libalpm/hooks/zz-sbctl.hook` | Auto-signs EFI binaries on pacman updates |
| Bootloaders | `/boot/EFI/BOOT/BOOTX64.EFI`<br>`/boot/EFI/systemd/systemd-bootx64.efi` | Signed bootloader binaries |
| Kernels | `/boot/vmlinuz-*` | Signed kernel images |
| Config | `/boot/loader/` | systemd-boot configuration |

## Dual-Boot with Windows

### Why `--microsoft` Flag?

When enrolling keys with `sbctl enroll-keys --microsoft`, the following Microsoft keys are included:

- **Microsoft Corporation UEFI CA**
- **Windows Production PCA**

These keys are necessary for:
- Windows bootloader to be trusted
- Windows updates to continue working
- Third-party UEFI drivers (some hardware)

### Without Microsoft Keys

If you **only** run Linux and never plan to boot Windows:
```bash
sudo sbctl enroll-keys  # No --microsoft flag
```

⚠️ **Warning**: This will prevent Windows from booting. Only use this for Linux-only systems.

## NVIDIA Drivers

If you have NVIDIA drivers installed (especially nvidia-open), kernel modules are **automatically handled**:

1. The `zz-sbctl.hook` triggers on module updates
2. `sbctl sign-all -g` signs all necessary binaries
3. Compressed modules (`.ko.zst`) don't need individual signing
4. The signed kernel image validates module loading

**No manual NVIDIA module signing required.**

## Common Commands

### Check Secure Boot Status
```bash
sbctl status
```

### List Signed Files
```bash
sudo sbctl list-files
```

### Verify All Signatures
```bash
sudo sbctl verify
```

### Manually Sign a File
```bash
sudo sbctl sign -s /path/to/file.efi
```

### Remove File from Database
```bash
sudo sbctl remove-file /path/to/file.efi
```

### List Enrolled Keys
```bash
sudo sbctl list-keys
```

## Troubleshooting

### System Won't Boot After Enabling Secure Boot

**Solution 1**: Disable Secure Boot temporarily
1. Enter BIOS/UEFI settings
2. Navigate to Security → Secure Boot
3. Disable Secure Boot
4. Boot into Linux
5. Run `sudo sbctl verify` to check what's not signed
6. Sign missing files: `sudo sbctl sign -s /path/to/file.efi`
7. Re-enable Secure Boot

**Solution 2**: Check if keys are enrolled
```bash
sbctl status
```
If "Setup Mode: ✓ Enabled", you forgot to run `sbctl enroll-keys --microsoft`

### Windows Won't Boot

**Cause**: Microsoft keys not included during enrollment

**Solution**:
1. Boot into Linux (disable Secure Boot if necessary)
2. Clear existing enrollment:
   ```bash
   sudo sbctl enroll-keys --microsoft
   ```
3. Reboot into BIOS and re-enable Secure Boot

### Kernel Update Fails to Boot

**Cause**: New kernel not signed (hook failed)

**Solution**:
1. Boot into older kernel from systemd-boot menu
2. Manually sign new kernel:
   ```bash
   sudo sbctl sign-all -g
   ```
3. Verify: `sudo sbctl verify`
4. Reboot

### Hook Not Running After Updates

**Check if hook exists**:
```bash
ls -la /usr/share/libalpm/hooks/zz-sbctl.hook
```

**Reinstall sbctl**:
```bash
sudo pacman -S --noconfirm sbctl
```

**Manually trigger signing**:
```bash
sudo sbctl sign-all -g
```

## Security Considerations

### Key Protection

Your custom Secure Boot keys are stored in `/usr/share/secureboot/`. **Back them up securely**:

```bash
# Backup to encrypted location
sudo cp -r /usr/share/secureboot/ ~/.config/secure-boot-keys-backup/
sudo chown -R $USER:$USER ~/.config/secure-boot-keys-backup/
chmod 700 ~/.config/secure-boot-keys-backup/

# Or backup to external drive
sudo cp -r /usr/share/secureboot/ /mnt/external-drive/secure-boot-keys/
```

**Important**:
- Store backup on encrypted media
- Keep backup offline (USB drive, encrypted cloud)
- Without keys, you can't sign new kernels/bootloaders
- If keys are lost, you must regenerate and re-enroll (requires BIOS access)

### Key Rotation

If keys are compromised:

1. Generate new keys:
   ```bash
   sudo rm -rf /usr/share/secureboot/
   sudo sbctl create-keys
   ```

2. Re-sign everything:
   ```bash
   sudo sbctl sign-all -g
   ```

3. Re-enroll in firmware:
   - Boot into BIOS → Clear Secure Boot keys
   - Save and reboot
   - Run `sudo sbctl enroll-keys --microsoft`
   - Reboot into BIOS → Enable Secure Boot

### TPM Integration

Your system has TPM2 support. Future enhancements could include:

- **Measured Boot**: Use TPM to measure boot chain integrity
- **Sealed Keys**: Encrypt disk encryption keys with TPM
- **Remote Attestation**: Verify boot state remotely

These are **not** currently automated but can be configured manually with `systemd-cryptenroll` and related tools.

## Maintenance

### After Kernel Updates

**Automatic** (via pacman hook):
- New kernels are signed automatically
- No manual intervention needed
- Check pacman output for "Signing EFI binaries..." message

**Manual verification** (optional):
```bash
sudo sbctl verify
```

### After Bootloader Updates

**Automatic** (via pacman hook):
- systemd-boot updates trigger automatic re-signing
- Verify with `sudo sbctl verify`

### After Installing New Bootable OSes

If you install another OS (e.g., Ubuntu, Fedora):

1. Boot into CachyOS
2. Sign the new OS's bootloader:
   ```bash
   sudo sbctl sign -s /boot/EFI/ubuntu/shimx64.efi  # Example for Ubuntu
   ```
3. Verify: `sudo sbctl verify`

## Implementation Details

### Script Execution Order

When you run `./setup.sh`, the execution order is:

1. `setup/pacman/.setup.sh`
   - Installs `sbctl` package
   - Runs **before** configuration

2. `setup/tweak/.setup.sh`
   - Runs `secure-boot.sh`
   - Creates keys
   - Signs boot components
   - Generates instructions

3. Main `setup.sh`
   - Displays final instructions
   - Offers reboot option

### Idempotency

The scripts are idempotent (safe to run multiple times):

- **Keys**: Only created if `/usr/share/secureboot/` doesn't exist
- **Signing**: Re-signs files even if already signed (safe operation)
- **Verification**: Always runs to ensure current state is valid

### Error Handling

- **Non-UEFI systems**: Script exits with warning
- **Missing sbctl**: Skips Secure Boot setup, warns user
- **Already enabled**: Skips configuration, reports success
- **Signing failures**: Warns but continues (logs errors)

## References

- [sbctl GitHub](https://github.com/Foxboron/sbctl)
- [ArchWiki: Secure Boot](https://wiki.archlinux.org/title/Unified_Extensible_Firmware_Interface/Secure_Boot)
- [systemd-boot Documentation](https://www.freedesktop.org/software/systemd/man/systemd-boot.html)
- [UEFI Secure Boot Specification](https://uefi.org/specifications)

## Support

For issues or questions:

1. Check `sbctl status` and `sbctl verify` output
2. Review `/var/log/pacman.log` for hook execution
3. Consult ArchWiki: https://wiki.archlinux.org/title/Unified_Extensible_Firmware_Interface/Secure_Boot
4. Check sbctl issues: https://github.com/Foxboron/sbctl/issues

---

**Last Updated**: January 2026  
**Compatible With**: CachyOS Linux, Arch Linux, systemd-boot  
**Maintainer**: Your system configuration repository
