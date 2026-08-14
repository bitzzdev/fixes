# QCA9377 Wi-Fi Auto-Fix for Arch Linux

This document contains both Bash and Fish versions of an automatic Wi-Fi troubleshooting/fix script for Arch Linux.

The script is designed for the Qualcomm Atheros QCA9377 using the `ath10k_pci` driver.

It:

- Detects the active Wi-Fi interface automatically.
- Detects the Wi-Fi hardware and driver.
- Installs missing `iw` and `networkmanager` packages.
- Ensures `linux-firmware` is installed.
- Disables Wi-Fi power saving immediately.
- Makes Wi-Fi power saving disabled persistently through NetworkManager.
- Reloads NetworkManager.
- Rechecks the Wi-Fi state.
- Shows recent `ath10k`, firmware, authentication, deauthentication, and timeout errors.

It intentionally does not automatically replace firmware, downgrade the kernel, change PCIe ASPM settings, or unload/reload the Wi-Fi driver.

## Bash

```bash
# QCA9377 / ath10k Wi-Fi auto-fix for Arch Linux
set -e

echo "=== Wi-Fi Auto-Fix ==="

sudo -v

WIFI_IFACE="$(nmcli -t -f DEVICE,TYPE device status 2>/dev/null | awk -F: '$2=="wifi" {print $1; exit}')"

if [ -z "$WIFI_IFACE" ]; then
    echo "No Wi-Fi interface detected."
    exit 1
fi

echo "Detected Wi-Fi interface: $WIFI_IFACE"

WIFI_INFO="$(lspci -nnk 2>/dev/null | grep -A4 -Ei 'network controller|wireless controller|wifi')"

echo
echo "=== Wi-Fi Hardware ==="
echo "$WIFI_INFO"

DRIVER="$(lspci -nnk 2>/dev/null | awk '/Network controller|Wireless controller/{found=1} found && /Kernel driver in use:/{print $NF; exit}')"

echo
echo "Detected driver: ${DRIVER:-unknown}"

PACKAGES=""

command -v iw >/dev/null 2>&1 || PACKAGES="$PACKAGES iw"
command -v nmcli >/dev/null 2>&1 || PACKAGES="$PACKAGES networkmanager"

if [ -n "$PACKAGES" ]; then
    echo
    echo "Installing missing packages:$PACKAGES"
    sudo pacman -S --needed $PACKAGES
fi

echo
echo "=== Checking linux-firmware ==="
sudo pacman -S --needed linux-firmware

if echo "$WIFI_INFO" | grep -qi "QCA9377"; then
    echo "QCA9377 detected."
fi

if [ "$DRIVER" = "ath10k_pci" ]; then
    echo "ath10k_pci detected."
fi

echo
echo "=== Disabling Wi-Fi Power Saving ==="

if iw dev "$WIFI_IFACE" get power_save >/dev/null 2>&1; then
    sudo iw dev "$WIFI_IFACE" set power_save off
    echo "Power saving disabled on $WIFI_IFACE."
else
    echo "Could not control power saving on $WIFI_IFACE."
fi

echo
echo "=== Making Fix Persistent ==="

sudo mkdir -p /etc/NetworkManager/conf.d

sudo tee /etc/NetworkManager/conf.d/20-wifi-powersave-off.conf >/dev/null <<'EOF'
[connection]
wifi.powersave = 2
EOF

echo "NetworkManager power-saving configuration created."

echo
echo "=== Reloading NetworkManager ==="

sudo systemctl reload NetworkManager 2>/dev/null || sudo systemctl restart NetworkManager

sleep 2

if iw dev "$WIFI_IFACE" get power_save >/dev/null 2>&1; then
    sudo iw dev "$WIFI_IFACE" set power_save off || true
fi

echo
echo "=== Result ==="

echo "Interface:"
echo "$WIFI_IFACE"

echo
echo "Power saving:"
iw dev "$WIFI_IFACE" get power_save 2>/dev/null || true

echo
echo "Driver:"
echo "${DRIVER:-unknown}"

echo
echo "Firmware:"
pacman -Q linux-firmware 2>/dev/null || true

echo
echo "=== Recent Wi-Fi Errors ==="

sudo journalctl -k -b --no-pager 2>/dev/null \
    | grep -Ei 'ath10k|firmware crashed|device successfully recovered|authentication|deauth|disassoc|timeout' \
    | tail -30 || true

echo
echo "=== Done ==="
echo
echo "Wi-Fi power saving has been disabled."
echo "The NetworkManager setting has been made persistent."
echo
echo "If the Wi-Fi still disconnects, run:"
echo "sudo journalctl -k -b --no-pager | grep -Ei 'ath10k|firmware crashed|device successfully recovered|authentication|deauth|disassoc|timeout' | tail -100"
```

## Fish

```fish
# QCA9377 / ath10k Wi-Fi auto-fix for Arch Linux

echo "=== Wi-Fi Auto-Fix ==="

sudo -v
or exit 1

set WIFI_IFACE (nmcli -t -f DEVICE,TYPE device status 2>/dev/null | awk -F: '$2=="wifi" {print $1; exit}')

if test -z "$WIFI_IFACE"
    echo "No Wi-Fi interface detected."
    exit 1
end

echo "Detected Wi-Fi interface: $WIFI_IFACE"

set WIFI_INFO (lspci -nnk 2>/dev/null | grep -A4 -Ei 'network controller|wireless controller|wifi')

echo
echo "=== Wi-Fi Hardware ==="
echo "$WIFI_INFO"

set DRIVER (lspci -nnk 2>/dev/null | awk '/Network controller|Wireless controller/{found=1} found && /Kernel driver in use:/{print $NF; exit}')

echo
echo "Detected driver: "(string join " " $DRIVER)

set PACKAGES

if not command -q iw
    set -a PACKAGES iw
end

if not command -q nmcli
    set -a PACKAGES networkmanager
end

if test (count $PACKAGES) -gt 0
    echo
    echo "Installing missing packages:"
    printf '%s\n' $PACKAGES
    sudo pacman -S --needed $PACKAGES
end

echo
echo "=== Checking linux-firmware ==="
sudo pacman -S --needed linux-firmware

if string match -qi '*QCA9377*' "$WIFI_INFO"
    echo "QCA9377 detected."
end

if test "$DRIVER" = "ath10k_pci"
    echo "ath10k_pci detected."
end

echo
echo "=== Disabling Wi-Fi Power Saving ==="

if iw dev "$WIFI_IFACE" get power_save >/dev/null 2>&1
    sudo iw dev "$WIFI_IFACE" set power_save off
    echo "Power saving disabled on $WIFI_IFACE."
else
    echo "Could not control power saving on $WIFI_IFACE."
end

echo
echo "=== Making Fix Persistent ==="

sudo mkdir -p /etc/NetworkManager/conf.d

printf '%s\n' \
'[connection]' \
'wifi.powersave = 2' \
| sudo tee /etc/NetworkManager/conf.d/20-wifi-powersave-off.conf >/dev/null

echo "NetworkManager power-saving configuration created."

echo
echo "=== Reloading NetworkManager ==="

sudo systemctl reload NetworkManager 2>/dev/null
or sudo systemctl restart NetworkManager

sleep 2

if iw dev "$WIFI_IFACE" get power_save >/dev/null 2>&1
    sudo iw dev "$WIFI_IFACE" set power_save off
end

echo
echo "=== Result ==="

echo "Interface:"
echo "$WIFI_IFACE"

echo
echo "Power saving:"
iw dev "$WIFI_IFACE" get power_save 2>/dev/null

echo
echo "Driver:"
echo "$DRIVER"

echo
echo "Firmware:"
pacman -Q linux-firmware 2>/dev/null

echo
echo "=== Recent Wi-Fi Errors ==="

sudo journalctl -k -b --no-pager 2>/dev/null \
    | grep -Ei 'ath10k|firmware crashed|device successfully recovered|authentication|deauth|disassoc|timeout' \
    | tail -30

echo
echo "=== Done ==="
echo
echo "Wi-Fi power saving has been disabled."
echo "The NetworkManager setting has been made persistent."
echo
echo "If the Wi-Fi still disconnects, run:"
echo "sudo journalctl -k -b --no-pager | grep -Ei 'ath10k|firmware crashed|device successfully recovered|authentication|deauth|disassoc|timeout' | tail -100"
```

## Persistent Configuration Created

The scripts create:

```ini
[connection]
wifi.powersave = 2
```

at:

```text
/etc/NetworkManager/conf.d/20-wifi-powersave-off.conf
```

This makes the power-saving change persistent across NetworkManager restarts and reboots.

## If the Problem Continues

The automatic fix deliberately stops before making riskier changes.

If Wi-Fi still disconnects, inspect the ath10k errors with:

```bash
sudo journalctl -k -b --no-pager | grep -Ei 'ath10k|firmware crashed|device successfully recovered|authentication|deauth|disassoc|timeout' | tail -100
```

At that point, investigate ath10k firmware stability, PCIe power management, kernel behavior, and Realme hotspot compatibility rather than replacing the driver blindly.
