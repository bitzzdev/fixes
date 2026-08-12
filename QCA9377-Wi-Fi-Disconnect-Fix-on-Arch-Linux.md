# QCA9377 Wi-Fi Disconnect Fix on Arch Linux

## Problem

The laptop uses a Qualcomm Atheros QCA9377 Wi-Fi adapter with the `ath10k_pci` Linux driver.

Symptoms:

* Wi-Fi repeatedly disconnects from the Realme C11 hotspot.
* Another phone hotspot may work more reliably.
* Signal strength can be strong while disconnecting.
* NetworkManager repeatedly reconnects.
* Kernel logs show `ath10k` firmware crashes.

The important kernel error is:

```text
ath10k_pci 0000:02:00.0: firmware crashed!
ath10k_pci 0000:02:00.0: device successfully recovered
```

This means the Wi-Fi firmware crashed and the Linux driver had to recover the adapter.

---

# Primary Fix

> [!IMPORTANT]
> **The first fix to try is disabling Wi-Fi power saving on `wlan0`.**
>
> The adapter was found with Wi-Fi power saving enabled:
>
> ```text
> Power save: on
> ```
>
> Disable it temporarily with:

```fish
sudo iw dev wlan0 set power_save off
```

Then verify:

```fish
iw dev wlan0 get power_save
```

It should report:

```text
Power save: off
```

Now reconnect to the problematic hotspot and use the laptop normally.

**Do not make the change permanent until you confirm that it actually improves stability.**

---

## 1. Install Wi-Fi Diagnostic Tools

If `iw` is not installed:

```fish
sudo pacman -S iw usbutils
```

`iw` is required for checking Wi-Fi power management, link information, channels, and other wireless properties.

---

## 2. Verify the Wi-Fi Adapter and Driver

Run:

```fish
lspci -nnk | grep -A4 -Ei 'network|wireless|wifi'
```

Expected hardware:

```text
Qualcomm Atheros QCA9377 802.11ac Wireless Network Adapter
```

Expected driver:

```text
Kernel driver in use: ath10k_pci
Kernel modules: ath10k_pci
```

The QCA9377 is correctly supported by the Linux `ath10k` driver.

---

## 3. Check the Kernel

```fish
uname -r
```

Example:

```text
7.1.7-arch1-1
```

---

## 4. Check Linux Firmware

```fish
pacman -Q linux-firmware
```

Example:

```text
linux-firmware 20260622-1
```

The QCA9377 firmware is supplied through the `linux-firmware` package.

Check available QCA9377 firmware:

```fish
find /usr/lib/firmware/ath10k/QCA9377 -type f | sort
```

---

## 5. Check Wi-Fi Interfaces

```fish
iw dev
```

The system may show multiple interfaces such as:

```text
Interface wlan0
    type managed

Interface wlan1
    type managed
```

Determine which interface is actually connected:

```fish
nmcli device status
```

For the affected setup, `wlan0` was the active Wi-Fi interface.

---

# 6. Check Wi-Fi Power Saving

Check the current setting:

```fish
iw dev wlan0 get power_save
```

If it says:

```text
Power save: on
```

perform the temporary fix:

```fish
sudo iw dev wlan0 set power_save off
```

Verify:

```fish
iw dev wlan0 get power_save
```

Expected:

```text
Power save: off
```

### Why this matters

Wi-Fi power management can cause instability with certain combinations of:

* Wi-Fi chipsets
* kernel drivers
* firmware
* access points
* phone hotspots

The QCA9377 + `ath10k` combination is therefore worth testing with power saving disabled.

---

# 7. Check the Wi-Fi Connection

After applying the temporary fix:

```fish
iw dev wlan0 link
```

Example:

```text
Connected to 82:0f:27:8d:d7:68
SSID: gg
freq: 2447.0
signal: -46 dBm
rx bitrate: 72.2 MBit/s
```

A signal around `-46 dBm` is strong.

Therefore, if the connection is repeatedly dropping at this signal strength, weak signal is not the obvious explanation.

---

# 8. Check for Firmware Crashes

Run:

```fish
sudo journalctl -k -b --no-pager | grep -Ei 'ath10k|firmware crashed|device successfully recovered'
```

A problematic system may show:

```text
ath10k_pci 0000:02:00.0: firmware crashed!
```

followed by:

```text
ath10k_pci 0000:02:00.0: device successfully recovered
```

This is important evidence that the Wi-Fi firmware itself crashed.

---

# 9. Check Authentication and Disconnect Errors

Run:

```fish
sudo journalctl -k -b --no-pager | grep -Ei 'authentication|deauth|disassoc|timeout|ath10k' | tail -100
```

Important messages include:

```text
authentication with XX:XX:XX:XX:XX:XX timed out
```

```text
deauthenticating ... by local choice
```

```text
firmware crashed!
```

```text
device successfully recovered
```

---

# 10. Check RFKILL

Make sure Wi-Fi isn't being blocked:

```fish
rfkill list
```

The Wi-Fi adapter should show:

```text
Soft blocked: no
Hard blocked: no
```

---

# 11. Test the Realme Hotspot

After disabling power saving:

```fish
sudo iw dev wlan0 set power_save off
```

Verify:

```fish
iw dev wlan0 get power_save
```

Then connect to the Realme C11 hotspot.

Use the laptop normally for 10 to 15 minutes.

Monitor the connection with:

```fish
iw dev wlan0 link
```

If the connection remains stable for substantially longer than before, power management is likely involved.

---

# 12. Compare Against the Vivo Hotspot

A useful controlled test is to compare both phones.

### Test A: Realme C11

1. Connect the laptop to the Realme hotspot.
2. Disable Wi-Fi power saving.
3. Use the connection normally.
4. Watch for disconnects.

### Test B: Vivo Y11

Repeat the same test using the Vivo hotspot.

Interpretation:

| Result                                   | Likely cause                                      |
| ---------------------------------------- | ------------------------------------------------- |
| Both phones disconnect                   | QCA9377/ath10k side is more suspicious            |
| Realme disconnects, Vivo stays stable    | Realme/QCA9377 compatibility issue is possible    |
| Both become stable with power saving off | Wi-Fi power management is strongly implicated     |
| Firmware crashes continue                | Investigate ath10k firmware/PCIe power management |

---

# 13. Count Firmware Crashes

Before testing:

```fish
sudo journalctl -k -b --no-pager | grep -c "firmware crashed"
```

Then test the hotspot.

After another disconnect:

```fish
sudo journalctl -k -b --no-pager | grep -c "firmware crashed"
```

If the number increases, another ath10k firmware crash occurred.

---

# 14. Current Findings

The affected system has:

```text
Wi-Fi:
Qualcomm Atheros QCA9377

PCI ID:
168c:0042

Driver:
ath10k_pci

Kernel:
7.1.7-arch1-1

Firmware package:
linux-firmware 20260622-1
```

The firmware reports:

```text
WLAN.TF.2.1-00021-QCARMSWP-1
API 6
```

The adapter was operating on:

```text
2.4 GHz
Channel 8
2447 MHz
20 MHz width
```

Signal strength:

```text
-46 dBm
```

Power saving:

```text
Power save: on
```

Most importantly, the kernel recorded:

```text
ath10k_pci 0000:02:00.0: firmware crashed!
```

and subsequently:

```text
ath10k_pci 0000:02:00.0: device successfully recovered
```

This confirms that there has been at least one real Wi-Fi firmware failure during the current boot.

---

# 15. Do Not Manually Replace Firmware Yet

Do **not** immediately:

* Download random `ath10k` firmware from GitHub.
* Manually overwrite `/usr/lib/firmware/ath10k`.
* Install unofficial Wi-Fi drivers.
* Remove `ath10k_pci`.
* Downgrade the kernel without testing.
* Change multiple Wi-Fi settings at once.

The adapter is already using the correct Linux driver and firmware package.

First test the simple power-saving fix.

---

# 16. If the Fix Works

If:

```fish
sudo iw dev wlan0 set power_save off
```

makes the Wi-Fi stable, the next step is to make the setting persistent through NetworkManager.

Do not make it permanent until the temporary test has proven that disabling power saving actually helps.

---

# 17. If the Fix Does Not Work

If the Wi-Fi continues disconnecting with power saving disabled, investigate:

1. `ath10k` firmware stability.
2. QCA9377 firmware selection.
3. PCIe power management.
4. NetworkManager configuration.
5. Kernel regressions.
6. 2.4 GHz versus 5 GHz behavior.
7. Compatibility between the QCA9377 and the Realme hotspot.

The kernel logs should be checked after each test.

---

# Quick Fix

For the current session, the main fix is simply:

```fish
sudo iw dev wlan0 set power_save off
```

Verify:

```fish
iw dev wlan0 get power_save
```

Expected:

```text
Power save: off
```

Then reconnect to the hotspot and test the connection.

> [!NOTE]
> This is a **temporary diagnostic fix** until stability is confirmed. If it solves the disconnect problem, make it permanent afterward through NetworkManager.

---

# Full Diagnostic Command Block

For future troubleshooting:

```fish
echo "===== WIFI ====="
iw dev

echo
echo "===== POWER SAVE ====="
iw dev wlan0 get power_save

echo
echo "===== LINK ====="
iw dev wlan0 link

echo
echo "===== DEVICE ====="
nmcli device status

echo
echo "===== RFKILL ====="
rfkill list

echo
echo "===== DRIVER ====="
lspci -nnk | grep -A4 -Ei 'network|wireless|wifi'

echo
echo "===== FIRMWARE ====="
pacman -Q linux-firmware
sudo dmesg | grep -i ath10k | grep -Ei 'firmware|fw|htt-ver|wmi-op|hw'

echo
echo "===== WIFI ERRORS ====="
sudo journalctl -k -b --no-pager | grep -Ei 'ath10k|firmware crashed|device successfully recovered|authentication|deauth|disassoc|timeout' | tail -100
```

# Conclusion

The QCA9377 is correctly detected and is using `ath10k_pci`. The installed `linux-firmware` package is also present.

However, the kernel has recorded an actual **ath10k firmware crash**, and the Wi-Fi adapter had to recover.

The first and safest fix to test is:

```fish
sudo iw dev wlan0 set power_save off
```

If the Wi-Fi becomes stable afterward, power management is likely contributing to the problem.

If the firmware continues crashing even with power saving disabled, the next investigation should focus on **ath10k firmware stability and PCIe power management** rather than simply replacing the Wi-Fi driver.
