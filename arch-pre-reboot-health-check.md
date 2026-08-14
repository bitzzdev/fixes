# Arch Linux Pre-Reboot System Health Check

Use these commands after `pacman -Syu`, especially after a kernel update or an interrupted network connection.

The checks verify the root filesystem, `/boot`, installed packages, kernel, microcode, initramfs, UKI, boot configuration, failed systemd services, and current boot errors.

## Bash

Copy and paste the entire block directly into Bash:

```bash
FAILED=0

check() {
    echo
    echo ">>> $1"
}

pass() {
    echo "[OK] $1"
}

warn() {
    echo "[WARN] $1"
}

fail() {
    echo "[FAIL] $1"
    FAILED=1
}

echo "========================================"
echo " Arch Linux Pre-Reboot Health Check"
echo "========================================"

check "Checking root filesystem"
if findmnt -n / >/dev/null 2>&1; then
    ROOT_FS=$(findmnt -n -o FSTYPE /)
    ROOT_DEV=$(findmnt -n -o SOURCE /)
    pass "Root mounted: $ROOT_DEV ($ROOT_FS)"
else
    fail "Root filesystem is not mounted"
fi

check "Checking /boot"
if mountpoint -q /boot; then
    BOOT_DEV=$(findmnt -n -o SOURCE /boot)
    BOOT_FS=$(findmnt -n -o FSTYPE /boot)
    pass "/boot mounted: $BOOT_DEV ($BOOT_FS)"
else
    fail "/boot is NOT mounted"
fi

check "Checking package update state"
UPDATES=$(pacman -Qu 2>/dev/null || true)
if [ -z "$UPDATES" ]; then
    pass "No pending package updates"
else
    warn "Packages still have available updates:"
    echo "$UPDATES"
fi

check "Checking installed package files"
QK_OUTPUT=$(sudo pacman -Qk 2>&1)
if echo "$QK_OUTPUT" | grep -qE '[0-9]+ missing files'; then
    fail "Some installed packages have missing files"
    echo "$QK_OUTPUT" | grep -E 'missing files'
else
    pass "No missing package files detected"
fi

check "Checking installed kernel"
KERNEL=$(pacman -Q linux 2>/dev/null || true)
if [ -n "$KERNEL" ]; then
    pass "Installed kernel: $KERNEL"
else
    fail "linux package is not installed"
fi

check "Checking kernel files in /boot"
if [ -f /boot/vmlinuz-linux ]; then
    SIZE=$(stat -c '%s' /boot/vmlinuz-linux)
    if [ "$SIZE" -gt 1000000 ]; then
        pass "vmlinuz-linux exists and is $((SIZE / 1024 / 1024)) MB"
    else
        fail "vmlinuz-linux exists but is suspiciously small"
    fi
else
    fail "/boot/vmlinuz-linux is missing"
fi

check "Checking CPU microcode"
if pacman -Q amd-ucode >/dev/null 2>&1; then
    if [ -s /boot/amd-ucode.img ]; then
        pass "AMD microcode present"
    else
        fail "amd-ucode is installed but /boot/amd-ucode.img is missing"
    fi
elif pacman -Q intel-ucode >/dev/null 2>&1; then
    if [ -s /boot/intel-ucode.img ]; then
        pass "Intel microcode present"
    else
        fail "intel-ucode is installed but /boot/intel-ucode.img is missing"
    fi
else
    warn "No CPU microcode package detected"
fi

check "Checking mkinitcpio"
if command -v mkinitcpio >/dev/null 2>&1; then
    pass "mkinitcpio is installed"
else
    fail "mkinitcpio is missing"
fi

check "Rebuilding initramfs and UKI"
if sudo mkinitcpio -P; then
    pass "initramfs/UKI generation completed successfully"
else
    fail "mkinitcpio failed"
fi

check "Checking Unified Kernel Image"
UKI="/boot/EFI/Linux/arch-linux.efi"

if [ -f "$UKI" ]; then
    SIZE=$(stat -c '%s' "$UKI")
    if [ "$SIZE" -gt 1000000 ]; then
        if file "$UKI" | grep -qiE 'PE32\+.*EFI|EFI.*application'; then
            pass "Valid UKI found: $((SIZE / 1024 / 1024)) MB"
        else
            warn "UKI exists but file does not look like a normal EFI executable"
        fi
    else
        fail "UKI exists but is suspiciously small"
    fi
else
    fail "UKI missing: $UKI"
fi

check "Checking boot configuration"
if command -v bootctl >/dev/null 2>&1; then
    BOOTCTL_OUTPUT=$(sudo bootctl status 2>&1 || true)

    if echo "$BOOTCTL_OUTPUT" | grep -q "arch-linux.efi"; then
        pass "Arch UKI is recognized by boot configuration"
    else
        warn "bootctl did not clearly report arch-linux.efi"
    fi

    echo "$BOOTCTL_OUTPUT" | grep -E \
        'Current Boot Loader:|Product:|Default Boot Loader Entry:|title:|version:|source:|linux:|options:' \
        || true
else
    warn "bootctl is not available"
fi

check "Checking failed systemd services"
FAILED_SERVICES=$(systemctl --failed --no-legend 2>/dev/null || true)

if [ -z "$FAILED_SERVICES" ]; then
    pass "No failed systemd services"
else
    warn "Failed systemd services detected:"
    echo "$FAILED_SERVICES"
fi

check "Checking current boot errors"
ERRORS=$(sudo journalctl -b -p err..alert --no-pager 2>/dev/null || true)

if [ -z "$ERRORS" ]; then
    pass "No error-level boot messages"
else
    warn "Error-level messages were found:"
    echo "$ERRORS"
fi

echo
echo "========================================"

if [ "$FAILED" -eq 0 ]; then
    echo " SYSTEM CHECK PASSED"
    echo "========================================"
    echo
    echo "No critical problems were detected."
    echo "The system appears safe to reboot."
    echo
    echo "Run:"
    echo "  sudo reboot"
else
    echo " SYSTEM CHECK FAILED"
    echo "========================================"
    echo
    echo "Do NOT reboot yet."
    echo "Fix the [FAIL] items above first."
fi
```

## Fish

Copy and paste the entire block directly into Fish:

```fish
set FAILED 0

function check
    echo
    echo ">>> $argv"
end

function pass
    echo "[OK] $argv"
end

function warn
    echo "[WARN] $argv"
end

function fail
    echo "[FAIL] $argv"
    set -g FAILED 1
end

echo "========================================"
echo " Arch Linux Pre-Reboot Health Check"
echo "========================================"

check "Checking root filesystem"
if findmnt -n / >/dev/null 2>&1
    set ROOT_FS (findmnt -n -o FSTYPE /)
    set ROOT_DEV (findmnt -n -o SOURCE /)
    pass "Root mounted: $ROOT_DEV ($ROOT_FS)"
else
    fail "Root filesystem is not mounted"
end

check "Checking /boot"
if mountpoint -q /boot
    set BOOT_DEV (findmnt -n -o SOURCE /boot)
    set BOOT_FS (findmnt -n -o FSTYPE /boot)
    pass "/boot mounted: $BOOT_DEV ($BOOT_FS)"
else
    fail "/boot is NOT mounted"
end

check "Checking package update state"
set UPDATES (pacman -Qu 2>/dev/null)

if test (count $UPDATES) -eq 0
    pass "No pending package updates"
else
    warn "Packages still have available updates:"
    printf '%s\n' $UPDATES
end

check "Checking installed package files"
set QK_OUTPUT (sudo pacman -Qk 2>&1)

if printf '%s\n' $QK_OUTPUT | grep -qE '[0-9]+ missing files'
    fail "Some installed packages have missing files"
    printf '%s\n' $QK_OUTPUT | grep -E 'missing files'
else
    pass "No missing package files detected"
end

check "Checking installed kernel"
set KERNEL (pacman -Q linux 2>/dev/null)

if test (count $KERNEL) -gt 0
    pass "Installed kernel: $KERNEL"
else
    fail "linux package is not installed"
end

check "Checking kernel files in /boot"
if test -f /boot/vmlinuz-linux
    set SIZE (stat -c '%s' /boot/vmlinuz-linux)

    if test $SIZE -gt 1000000
        set MB (math "floor($SIZE / 1024 / 1024)")
        pass "vmlinuz-linux exists and is $MB MB"
    else
        fail "vmlinuz-linux exists but is suspiciously small"
    end
else
    fail "/boot/vmlinuz-linux is missing"
end

check "Checking CPU microcode"
if pacman -Q amd-ucode >/dev/null 2>&1
    if test -s /boot/amd-ucode.img
        pass "AMD microcode present"
    else
        fail "amd-ucode is installed but /boot/amd-ucode.img is missing"
    end
else if pacman -Q intel-ucode >/dev/null 2>&1
    if test -s /boot/intel-ucode.img
        pass "Intel microcode present"
    else
        fail "intel-ucode is installed but /boot/intel-ucode.img is missing"
    end
else
    warn "No CPU microcode package detected"
end

check "Checking mkinitcpio"
if command -v mkinitcpio >/dev/null 2>&1
    pass "mkinitcpio is installed"
else
    fail "mkinitcpio is missing"
end

check "Rebuilding initramfs and UKI"
if sudo mkinitcpio -P
    pass "initramfs/UKI generation completed successfully"
else
    fail "mkinitcpio failed"
end

check "Checking Unified Kernel Image"
set UKI /boot/EFI/Linux/arch-linux.efi

if test -f $UKI
    set SIZE (stat -c '%s' $UKI)

    if test $SIZE -gt 1000000
        if file $UKI | grep -qiE 'PE32\+.*EFI|EFI.*application'
            set MB (math "floor($SIZE / 1024 / 1024)")
            pass "Valid UKI found: $MB MB"
        else
            warn "UKI exists but file does not look like a normal EFI executable"
        end
    else
        fail "UKI exists but is suspiciously small"
    end
else
    fail "UKI missing: $UKI"
end

check "Checking boot configuration"
if command -v bootctl >/dev/null 2>&1
    set BOOTCTL_OUTPUT (sudo bootctl status 2>&1)

    if printf '%s\n' $BOOTCTL_OUTPUT | grep -q "arch-linux.efi"
        pass "Arch UKI is recognized by boot configuration"
    else
        warn "bootctl did not clearly report arch-linux.efi"
    end

    printf '%s\n' $BOOTCTL_OUTPUT | grep -E \
        'Current Boot Loader:|Product:|Default Boot Loader Entry:|title:|version:|source:|linux:|options:'
else
    warn "bootctl is not available"
end

check "Checking failed systemd services"
set FAILED_SERVICES (systemctl --failed --no-legend 2>/dev/null)

if test (count $FAILED_SERVICES) -eq 0
    pass "No failed systemd services"
else
    warn "Failed systemd services detected:"
    printf '%s\n' $FAILED_SERVICES
end

check "Checking current boot errors"
set ERRORS (sudo journalctl -b -p err..alert --no-pager 2>/dev/null)

if test (count $ERRORS) -eq 0
    pass "No error-level boot messages"
else
    warn "Error-level messages were found:"
    printf '%s\n' $ERRORS
end

echo
echo "========================================"

if test $FAILED -eq 0
    echo " SYSTEM CHECK PASSED"
    echo "========================================"
    echo
    echo "No critical problems were detected."
    echo "The system appears safe to reboot."
    echo
    echo "Run:"
    echo "  sudo reboot"
else
    echo " SYSTEM CHECK FAILED"
    echo "========================================"
    echo
    echo "Do NOT reboot yet."
    echo "Fix the [FAIL] items above first."
end
```

## Result

A successful check ends with:

```text
SYSTEM CHECK PASSED

No critical problems were detected.
The system appears safe to reboot.
```

If it ends with:

```text
SYSTEM CHECK FAILED

Do NOT reboot yet.
```

do not reboot until the `[FAIL]` item has been investigated.
