# Android Storage Optimization Log

**Device:** Realme C11 2021 (RMX3231)  
**OS:** Android 11 Go Edition  
**Access:** ADB, non-root  
**Status:** Baseline not yet measured; inventory in progress

## 1. Goal

Investigate internal storage usage, identify large and safe-to-remove files or caches, and increase genuinely available internal storage without deleting personal data or breaking apps.

**User target:** At least 20 GB free.

This is a target, not yet a confirmed achievable amount. The device's usable data-partition capacity and exact storage accounting must be measured first. The reported Android Settings categories may be rounded or include app data/cache and should not be added blindly.

## 2. Current user-reported storage picture

The following are preliminary estimates supplied by the device owner, not yet independently measured:

| Category | Reported size |
|---|---:|
| Apps | About 20 GB |
| Images | About 2.2 GB |
| Videos | A few hundred MB |
| Downloads | A few hundred MB |
| System | About 7.9 GB |

The category values may overlap conceptually: app storage can include app data and cache, and Android's storage UI may classify files differently from filesystem tools. We need the actual `/data` capacity, used/free values, and directory breakdown before deciding what can be removed.

## 3. Safety rules

- Do not delete anything from `/system`, `/vendor`, `/product`, `/metadata`, or other OS partitions.
- Do not recursively delete `Android/data`, `Android/obb`, or app-private directories.
- Do not run `pm clear` on apps. It erases app data and can remove accounts, settings, downloads, and local databases.
- Do not clear WhatsApp or other messenger data without checking its in-app storage manager and backup status.
- Do not delete DCIM, Pictures, or videos until originals are backed up and verified.
- Do not assume every file under Downloads is disposable. APKs, documents, archives, and project files may matter.
- Prefer app-provided cache controls and Android Settings over broad ADB deletion commands.
- Record the before/after free-space value for every cleanup step.

## 4. Cleanup order

Use this order, starting with reversible or easily verified items:

1. **Downloads:** Sort by size and review large APKs, ZIPs, videos, installers, and duplicate files. Delete only items confirmed unnecessary.
2. **Offline media:** Review YouTube and other streaming-app downloads inside each app. Remove only content that can be downloaded again.
3. **Messaging media:** Use WhatsApp's Settings → Storage and data → Manage storage. Review large files and forwarded media individually. Preserve important media first.
4. **Gallery and videos:** Find duplicates, screen recordings, exports, and unwanted large videos. Back up before deletion; empty the gallery trash/recently deleted folder only after verification.
5. **App caches:** Compare individual app storage sizes in Android Settings → Apps. Clear cache for unusually large apps where safe. Do not choose Clear storage/data unless intentionally resetting that app.
6. **Unused apps:** Uninstall apps that are genuinely no longer needed. Check whether they contain local-only data before uninstalling.
7. **Browser and social app downloads:** Review in-app downloads, cached media, and offline files through each app's own controls.
8. **Re-measure:** Recheck free space after each category. Do not run a mass cleanup in one step because it becomes difficult to identify what actually freed space.

## 5. Storage baseline to collect

Capture:

- Data partition total, used, and available space.
- Emulated shared-storage total, used, and available space.
- Top-level shared-storage directory sizes.
- Android's diskstats report, if available.
- Installed third-party package list for later app-by-app review.

The first pass is read-only. Directory sizes can take time to calculate. Permission-denied output is an access limitation, not proof that a directory is empty.

### Fish-compatible ADB diagnostic

The remote command intentionally uses simple commands rather than a shell loop. The earlier storage diagnostic failed because it sent fish's `end` keyword to Android's `/system/bin/sh`, which expects a different loop syntax. No storage changes were made by that failed attempt.

```fish
begin
    echo "===== STORAGE CAPACITY ====="
    adb shell df -h /data /storage/emulated/0

    echo
    echo "===== SHARED STORAGE TOP-LEVEL SIZES ====="
    adb shell 'du -h -d 1 /storage/emulated/0 2>&1'

    echo
    echo "===== ANDROID DISKSTATS ====="
    adb shell dumpsys diskstats

    echo
    echo "===== THIRD-PARTY PACKAGES ====="
    adb shell pm list packages -3
end 2>&1 | tee /tmp/rmx3231-storage-baseline.txt

if type -q wl-copy
    wl-copy < /tmp/rmx3231-storage-baseline.txt
else if type -q xclip
    xclip -selection clipboard -i /tmp/rmx3231-storage-baseline.txt
else if type -q xsel
    xsel --clipboard --input < /tmp/rmx3231-storage-baseline.txt
else
    echo "Clipboard utility missing."
end
```

This captures shared-storage folders and app package names, but Android may restrict access to app-private data and `dumpsys diskstats` may expose only cached/last-measured totals. We will use Settings' per-app storage screen to verify large app entries rather than infer private app sizes from inaccessible directories.

## 6. App-by-app investigation

For each large app, record:

| App | App size | User data | Cache | Keep / remove / investigate |
|---|---:|---:|---:|---|
| To be measured | — | — | — | — |

Prioritize apps with unusually large user data or cache, not simply the largest APK. App data may contain offline files, media, databases, and user-created content.

## 7. Progress log

| Step | Action | Result |
|---|---|---|
| 0 | Record owner-reported category estimates | Apps ~20 GB; images ~2.2 GB; videos/downloads a few hundred MB each; system ~7.9 GB |
| 1 | First ADB storage diagnostic attempt | Failed due to fish loop syntax being passed to Android shell; no changes made |
| 2 | Corrected read-only storage baseline | Pending |

## 8. Decision criteria

- Never promise 20 GB free until the usable `/data` capacity and current free space are measured.
- If the total usable data partition is less than the target plus unavoidable app/system data, the target is mathematically impossible without changing the installed app set or moving personal files off-device.
- A large `System` category is not a cleanup target unless a specific safe user-data component is identified.
- Prefer moving backed-up photos/videos and removing unneeded app data over deleting Android components.
- After cleanup, verify that the phone still boots, core apps work, media is intact, and the free-space figure remains stable after a reboot.

## 9. Current state

No storage files, app data, caches, or system components have been deleted or modified. The exact free-space baseline and per-app breakdown are still pending.
