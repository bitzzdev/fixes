# Arch Linux Post-Update `/boot` Health Check

A focused check for the main problem this system can encounter after an interrupted or low-internet `pacman -Syu`, especially when a kernel update is involved.

It checks only the boot-critical pieces:

- `/boot` is mounted
- `/boot` is the expected VFAT filesystem
- `vmlinuz-linux` exists and is not suspiciously small
- the Arch Unified Kernel Image exists and is not suspiciously small
- the UKI is recognized as an EFI executable
- AMD microcode exists when `amd-ucode` is installed
- the installed `linux` package has no missing files

It intentionally does not fail because of unrelated Wi-Fi, firmware, D-Bus, notification daemon, or journal warnings.

The commands use `sudo` when reading `/boot` because this system's `/boot` permissions prevent the normal user from reading those files directly.

## Bash

Copy and paste the entire block directly into Bash:

```bash
echo "===== ARCH /BOOT POST-UPDATE CHECK ====="
echo

FAILED=0

echo ">>> /boot mount"

if mountpoint -q /boot; then
    echo "[OK] /boot is mounted"
else
    echo "[FAIL] /boot is NOT mounted"
    FAILED=1
fi

echo
echo ">>> /boot filesystem"

BOOT_FS=$(findmnt -n -o FSTYPE /boot 2>/dev/null)

if [ "$BOOT_FS" = "vfat" ]; then
    echo "[OK] /boot is VFAT"
else
    echo "[FAIL] /boot filesystem could not be verified as VFAT"
    FAILED=1
fi

echo
echo ">>> Kernel"

if sudo test -s /boot/vmlinuz-linux; then
    SIZE=$(sudo stat -c '%s' /boot/vmlinuz-linux)

    if [ "$SIZE" -gt 1000000 ]; then
        echo "[OK] vmlinuz-linux exists: $((SIZE / 1024 / 1024)) MB"
    else
        echo "[FAIL] vmlinuz-linux is suspiciously small"
        FAILED=1
    fi
else
    echo "[FAIL] /boot/vmlinuz-linux is missing"
    FAILED=1
fi

echo
echo ">>> Unified Kernel Image"

UKI="/boot/EFI/Linux/arch-linux.efi"

if sudo test -s "$UKI"; then
    SIZE=$(sudo stat -c '%s' "$UKI")

    if [ "$SIZE" -gt 1000000 ]; then
        echo "[OK] arch-linux.efi exists: $((SIZE / 1024 / 1024)) MB"
    else
        echo "[FAIL] arch-linux.efi is suspiciously small"
        FAILED=1
    fi
else
    echo "[FAIL] /boot/EFI/Linux/arch-linux.efi is missing"
    FAILED=1
fi

echo
echo ">>> UKI format"

if sudo test -s "$UKI"; then
    UKI_TYPE=$(sudo file "$UKI")

    if echo "$UKI_TYPE" | grep -qiE 'PE32\+.*EFI|EFI.*application'; then
        echo "[OK] UKI is a valid EFI executable"
    else
        echo "[FAIL] UKI is not recognized as an EFI executable"
        echo "$UKI_TYPE"
        FAILED=1
    fi
fi

echo
echo ">>> AMD microcode"

if pacman -Q amd-ucode >/dev/null 2>&1; then
    if sudo test -s /boot/amd-ucode.img; then
        echo "[OK] AMD microcode exists"
    else
        echo "[FAIL] /boot/amd-ucode.img is missing"
        FAILED=1
    fi
else
    echo "[INFO] amd-ucode is not installed"
fi

echo
echo ">>> Linux package integrity"

KERNEL_CHECK=$(pacman -Qk linux 2>&1)

if echo "$KERNEL_CHECK" | grep -qE '[1-9][0-9]* missing files'; then
    echo "[FAIL] Linux package has missing files"
    echo "$KERNEL_CHECK" | grep 'missing files'
    FAILED=1
else
    echo "[OK] Linux package files are intact"
fi

echo
echo "========================================"

if [ "$FAILED" -eq 0 ]; then
    echo "[PASS] /boot CHECK PASSED"
    echo
    echo "Kernel and boot files look healthy."
    echo "Safe to reboot."
else
    echo "[FAIL] /boot CHECK FAILED"
    echo
    echo "DO NOT reboot yet."
    echo "Investigate the [FAIL] item above."
fi

echo "========================================"
```

## Fish

Copy and paste the entire block directly into Fish:

```fish
echo "===== ARCH /BOOT POST-UPDATE CHECK ====="
echo

set FAILED 0

echo ">>> /boot mount"

if mountpoint -q /boot
    echo "[OK] /boot is mounted"
else
    echo "[FAIL] /boot is NOT mounted"
    set FAILED 1
end

echo
echo ">>> /boot filesystem"

set BOOT_FS (findmnt -n -o FSTYPE /boot 2>/dev/null)

if test "$BOOT_FS" = "vfat"
    echo "[OK] /boot is VFAT"
else
    echo "[FAIL] /boot filesystem could not be verified as VFAT"
    set FAILED 1
end

echo
echo ">>> Kernel"

if sudo test -s /boot/vmlinuz-linux
    set SIZE (sudo stat -c '%s' /boot/vmlinuz-linux)

    if test $SIZE -gt 1000000
        set MB (math "floor($SIZE / 1024 / 1024)")
        echo "[OK] vmlinuz-linux exists: $MB MB"
    else
        echo "[FAIL] vmlinuz-linux is suspiciously small"
        set FAILED 1
    end
else
    echo "[FAIL] /boot/vmlinuz-linux is missing"
    set FAILED 1
end

echo
echo ">>> Unified Kernel Image"

set UKI /boot/EFI/Linux/arch-linux.efi

if sudo test -s $UKI
    set SIZE (sudo stat -c '%s' $UKI)

    if test $SIZE -gt 1000000
        set MB (math "floor($SIZE / 1024 / 1024)")
        echo "[OK] arch-linux.efi exists: $MB MB"
    else
        echo "[FAIL] arch-linux.efi is suspiciously small"
        set FAILED 1
    end
else
    echo "[FAIL] /boot/EFI/Linux/arch-linux.efi is missing"
    set FAILED 1
end

echo
echo ">>> UKI format"

if sudo test -s $UKI
    set UKI_TYPE (sudo file $UKI)

    if string match -rq 'PE32\+.*EFI|EFI.*application' -- $UKI_TYPE
        echo "[OK] UKI is a valid EFI executable"
    else
        echo "[FAIL] UKI is not recognized as an EFI executable"
        echo "$UKI_TYPE"
        set FAILED 1
    end
end

echo
echo ">>> AMD microcode"

if pacman -Q amd-ucode >/dev/null 2>&1
    if sudo test -s /boot/amd-ucode.img
        echo "[OK] AMD microcode exists"
    else
        echo "[FAIL] /boot/amd-ucode.img is missing"
        set FAILED 1
    end
else
    echo "[INFO] amd-ucode is not installed"
end

echo
echo ">>> Linux package integrity"

set KERNEL_CHECK (pacman -Qk linux 2>&1)

if printf '%s\n' $KERNEL_CHECK | grep -qE '[1-9][0-9]* missing files'
    echo "[FAIL] Linux package has missing files"
    printf '%s\n' $KERNEL_CHECK | grep 'missing files'
    set FAILED 1
else
    echo "[OK] Linux package files are intact"
end

echo
echo "========================================"

if test $FAILED -eq 0
    echo "[PASS] /boot CHECK PASSED"
    echo
    echo "Kernel and boot files look healthy."
    echo "Safe to reboot."
else
    echo "[FAIL] /boot CHECK FAILED"
    echo
    echo "DO NOT reboot yet."
    echo "Investigate the [FAIL] item above."
end

echo "========================================"
```

## What a successful check means

A successful result should end with:

```text
[PASS] /boot CHECK PASSED

Kernel and boot files look healthy.
Safe to reboot.
```

If it reports `[FAIL]`, the specific check immediately above the final result identifies what needs attention.

This check does not use `bootctl status` as a failure condition because this system uses GRUB 2.14 to load the Arch UKI. The `systemd-boot not installed in ESP` message from `bootctl` is therefore not a problem.
