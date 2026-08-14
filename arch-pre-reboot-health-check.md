# Arch Linux Pre-Reboot System Health Check

Use these commands after `pacman -Syu`, especially after a kernel update or an interrupted network connection.

The checks verify the root filesystem, `/boot`, installed packages, kernel, microcode, initramfs, UKI, boot configuration, failed systemd services, and current boot errors.

## Bash

Copy and paste the entire block directly into Bash:

```bash
echo "===== ARCH /BOOT POST-UPDATE CHECK ====="
echo

FAILED=0

echo ">>> Checking /boot mount"

if mountpoint -q /boot; then
    echo "[OK] /boot is mounted"
    findmnt /boot
else
    echo "[FAIL] /boot is NOT mounted"
    FAILED=1
fi

echo
echo ">>> Checking /boot filesystem"

BOOT_FS=$(findmnt -n -o FSTYPE /boot 2>/dev/null || true)

if [ "$BOOT_FS" = "vfat" ] || [ "$BOOT_FS" = "fat" ] || [ "$BOOT_FS" = "msdos" ]; then
    echo "[OK] /boot filesystem: $BOOT_FS"
elif [ -n "$BOOT_FS" ]; then
    echo "[WARN] /boot filesystem is $BOOT_FS"
else
    echo "[FAIL] Unable to determine /boot filesystem"
    FAILED=1
fi

echo
echo ">>> Checking kernel"

if [ -s /boot/vmlinuz-linux ]; then
    SIZE=$(stat -c '%s' /boot/vmlinuz-linux)

    if [ "$SIZE" -gt 1000000 ]; then
        echo "[OK] /boot/vmlinuz-linux exists: $((SIZE / 1024 / 1024)) MB"
    else
        echo "[FAIL] /boot/vmlinuz-linux is suspiciously small"
        FAILED=1
    fi
else
    echo "[FAIL] /boot/vmlinuz-linux is missing"
    FAILED=1
fi

echo
echo ">>> Checking Unified Kernel Image"

UKI="/boot/EFI/Linux/arch-linux.efi"

if [ -s "$UKI" ]; then
    SIZE=$(stat -c '%s' "$UKI")

    if [ "$SIZE" -gt 1000000 ] && file "$UKI" | grep -qiE 'PE32\+.*EFI|EFI.*application'; then
        echo "[OK] Arch UKI exists and is a valid EFI executable"
        echo "     Size: $((SIZE / 1024 / 1024)) MB"
    else
        echo "[FAIL] UKI exists but appears invalid or incomplete"
        FAILED=1
    fi
else
    echo "[FAIL] $UKI is missing"
    FAILED=1
fi

echo
echo ">>> Checking AMD microcode"

if pacman -Q amd-ucode >/dev/null 2>&1; then
    if [ -s /boot/amd-ucode.img ]; then
        echo "[OK] AMD microcode exists"
    else
        echo "[FAIL] /boot/amd-ucode.img is missing"
        FAILED=1
    fi
else
    echo "[INFO] amd-ucode is not installed"
fi

echo
echo ">>> Checking kernel package integrity"

KERNEL_CHECK=$(pacman -Qk linux 2>&1)

if echo "$KERNEL_CHECK" | grep -qE '[1-9][0-9]* missing files'; then
    echo "[FAIL] Linux package has missing files"
    echo "$KERNEL_CHECK" | grep 'missing files'
    FAILED=1
else
    echo "[OK] Linux package has no missing files"
fi

echo
echo ">>> Checking UKI through boot configuration"

BOOTCTL=$(bootctl status 2>&1 || true)

if echo "$BOOTCTL" | grep -q "arch-linux.efi"; then
    echo "[OK] Boot configuration recognizes arch-linux.efi"
else
    echo "[FAIL] Boot configuration does not recognize arch-linux.efi"
    FAILED=1
fi

echo
echo "========================================"

if [ "$FAILED" -eq 0 ]; then
    echo "[PASS] /boot CHECK PASSED"
    echo
    echo "No /boot/kernel/UKI problems were detected."
    echo "The system appears safe to reboot."
else
    echo "[FAIL] /boot CHECK FAILED"
    echo
    echo "DO NOT REBOOT YET."
    echo "A possible /boot or kernel update problem was detected."
fi

echo "========================================"
```

## Fish

Copy and paste the entire block directly into Fish:

```fish
echo "===== ARCH /BOOT POST-UPDATE CHECK ====="
echo

set FAILED 0

echo ">>> Checking /boot mount"

if mountpoint -q /boot
    echo "[OK] /boot is mounted"
    findmnt /boot
else
    echo "[FAIL] /boot is NOT mounted"
    set FAILED 1
end

echo
echo ">>> Checking /boot filesystem"

set BOOT_FS (findmnt -n -o FSTYPE /boot 2>/dev/null)

if test "$BOOT_FS" = "vfat"; or test "$BOOT_FS" = "fat"; or test "$BOOT_FS" = "msdos"
    echo "[OK] /boot filesystem: $BOOT_FS"
else if test -n "$BOOT_FS"
    echo "[WARN] /boot filesystem is $BOOT_FS"
else
    echo "[FAIL] Unable to determine /boot filesystem"
    set FAILED 1
end

echo
echo ">>> Checking kernel"

if test -s /boot/vmlinuz-linux
    set SIZE (stat -c '%s' /boot/vmlinuz-linux)

    if test $SIZE -gt 1000000
        set MB (math "floor($SIZE / 1024 / 1024)")
        echo "[OK] /boot/vmlinuz-linux exists: $MB MB"
    else
        echo "[FAIL] /boot/vmlinuz-linux is suspiciously small"
        set FAILED 1
    end
else
    echo "[FAIL] /boot/vmlinuz-linux is missing"
    set FAILED 1
end

echo
echo ">>> Checking Unified Kernel Image"

set UKI /boot/EFI/Linux/arch-linux.efi

if test -s $UKI
    set SIZE (stat -c '%s' $UKI)

    if test $SIZE -gt 1000000; and file $UKI | grep -qiE 'PE32\+.*EFI|EFI.*application'
        set MB (math "floor($SIZE / 1024 / 1024)")
        echo "[OK] Arch UKI exists and is a valid EFI executable"
        echo "     Size: $MB MB"
    else
        echo "[FAIL] UKI exists but appears invalid or incomplete"
        set FAILED 1
    end
else
    echo "[FAIL] $UKI is missing"
    set FAILED 1
end

echo
echo ">>> Checking AMD microcode"

if pacman -Q amd-ucode >/dev/null 2>&1
    if test -s /boot/amd-ucode.img
        echo "[OK] AMD microcode exists"
    else
        echo "[FAIL] /boot/amd-ucode.img is missing"
        set FAILED 1
    end
else
    echo "[INFO] amd-ucode is not installed"
end

echo
echo ">>> Checking kernel package integrity"

set KERNEL_CHECK (pacman -Qk linux 2>&1)

if printf '%s\n' $KERNEL_CHECK | grep -qE '[1-9][0-9]* missing files'
    echo "[FAIL] Linux package has missing files"
    printf '%s\n' $KERNEL_CHECK | grep 'missing files'
    set FAILED 1
else
    echo "[OK] Linux package has no missing files"
end

echo
echo ">>> Checking UKI through boot configuration"

set BOOTCTL (bootctl status 2>&1)

if printf '%s\n' $BOOTCTL | grep -q "arch-linux.efi"
    echo "[OK] Boot configuration recognizes arch-linux.efi"
else
    echo "[FAIL] Boot configuration does not recognize arch-linux.efi"
    set FAILED 1
end

echo
echo "========================================"

if test $FAILED -eq 0
    echo "[PASS] /boot CHECK PASSED"
    echo
    echo "No /boot/kernel/UKI problems were detected."
    echo "The system appears safe to reboot."
else
    echo "[FAIL] /boot CHECK FAILED"
    echo
    echo "DO NOT REBOOT YET."
    echo "A possible /boot or kernel update problem was detected."
end

echo "========================================"
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
