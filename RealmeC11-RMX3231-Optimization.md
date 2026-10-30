# Realme C11 Performance & Battery Optimization Log

**Device:** Realme C11 2021 (RMX3231)  
**OS:** Android 11 Go Edition  
**Build:** RMX3231_11.A.125  
**Last updated:** 30 October 2026  
**Access:** ADB, non-root  
**Status:** Ongoing investigation

## 1. Project goals

- Improve everyday responsiveness and smoothness.
- Improve battery life, especially background and idle consumption.
- Reduce unnecessary CPU and memory activity.
- Maintain stable frame pacing.
- Avoid unsafe system modifications.

The display supports approximately 60.0024 Hz. The practical performance target is stable 60 FPS.

## 2. Device baseline

| Component | Observed configuration |
|---|---|
| CPU | 8-core ARM Cortex-A55 |
| RAM | Approximately 1.91 GB |
| Swap | Approximately 1.44 GB |
| Display | 720 × 1600, approximately 60 Hz |
| Android | Android 11 Go Edition |
| Root | Not available |
| Launcher | Niagara Launcher |
| CPU governor | schedutil |

CPU policies:

- policy0: CPUs 0–3, 768 MHz–1.2 GHz.
- policy4: CPUs 4–7, 768 MHz–1.6 GHz.

No CPU frequency or governor modifications have been applied.

## 3. Diagnostics completed

### CPU

Previous diagnostics showed:

- CPU idle can reach approximately 95%.
- Instagram has occasionally shown high CPU usage.
- System processes and UNISOC services contribute to CPU activity.
- No persistent system-wide CPU overload has been established.

### Memory

Observed snapshots:

- Total RAM: approximately 1.91 GB.
- Available RAM: approximately 792–843 MB in recent samples.
- Swap usage: approximately 697–828 MB in recent samples.

Swap usage alone does not prove memory thrashing.

### Battery

Recent observations:

- Battery health: Good.
- Temperature: approximately 34–39°C in earlier snapshots.
- Latest recorded level: 89%.
- Latest voltage: 4,056 mV.
- Latest temperature: 35.1°C.
- Latest charge counter: 4,356,989 µAh.

A reliable discharge rate has not yet been established.

### Wake locks

Previous `dumpsys power` inspection showed:

- `mWakeLockSummary=0x0`.
- `mHoldingWakeLockSuspendBlocker=false`.
- PowerManagerService wake-lock reference count: zero.

No persistent active wake-lock problem has been established.

## 4. Instagram investigation

Package: `com.instagram.android`

Previously observed version:

- Version: 449.0.0.0.74
- Version code: 385505972
- Target SDK: 36

Instagram appeared as a significant CPU consumer in accumulated battery statistics.

An earlier active service was observed:

`com.facebook.video.heroplayer.service.HeroKeepAliveService`

Its presence alone did not prove excessive battery consumption.

### Restrictions applied

On 30 October 2026, the following commands were executed:

```sh
adb shell cmd appops set com.instagram.android RUN_IN_BACKGROUND ignore
adb shell cmd appops set com.instagram.android RUN_ANY_IN_BACKGROUND ignore
adb shell am force-stop com.instagram.android
```

The first follow-up snapshot showed:

- No PID returned by `pidof`.
- Both AppOps restrictions remained set to `ignore`.
- A `TaskLifeDetectingService` restart record appeared.

### Second follow-up: Instagram reappeared

Three CPU snapshots were collected.

| Sample | Instagram PID | CPU |
|---|---|---:|
| 1 | 15952 | 3.0% |
| 2 | 15952 | 18.7% |
| 3 | 15952 | 3.1% |

The process was therefore running again despite the background restrictions.

**Interpretation:** AppOps restrictions have not prevented all Instagram execution. The reason for the process restart remains unknown.

### Third follow-up: Force-stop verification

A further test was performed:

1. Checked Instagram's PID before force-stop.
2. Executed `am force-stop`.
3. Checked the PID immediately afterward.
4. Checked again after 15 seconds.
5. Inspected Instagram service records and AppOps.

Results:

| Check | Result |
|---|---|
| Before force-stop | PID `15952` |
| Immediately after force-stop | No PID returned |
| After 15 seconds | No PID returned |
| `RUN_IN_BACKGROUND` | `ignore` |
| `RUN_ANY_IN_BACKGROUND` | `ignore` |

The service output contained numerous records marked `Destroy`, including:

- `IgBgFetchTaskLifeService`
- `TaskLifeDetectingService`

These entries represent destroyed service records. They do not establish that those services were actively running during the test.

**Conclusion:** Force-stop successfully terminated Instagram, and the process remained absent for at least 15 seconds. The earlier process reappearance is still unexplained. The latest test does not establish that Instagram can never restart.

No individual Instagram services have been disabled.

## 5. Gmail investigation

Gmail package: `com.google.android.gm`

The 11:09 snapshot initially showed 85.7% instantaneous CPU usage, even though the user had not opened Gmail or received emails.

A subsequent three-sample check showed:

| Sample | Gmail CPU |
|---|---:|
| Original snapshot | 85.7% |
| Recheck 1 | 0% |
| Recheck 2 | Not in top 12 |
| Recheck 3 | Not in top 12 |

Gmail memory usage:

- PSS: 183,050 KB.
- RSS: 259,580 KB.
- Swap PSS: 29,990 KB.
- Activities: 0.
- Views: 0.

Some scheduled Gmail background jobs were present. The diagnostics did not establish that those jobs caused the initial CPU spike.

**Conclusion:** The high Gmail CPU reading was not sustained in the follow-up snapshots. No Gmail restrictions are justified at this stage.

## 6. Latest diagnostic summary

| Area | Result |
|---|---|
| CPU behavior | Generally healthy idle capacity in sampled intervals |
| Gmail CPU | Initial spike not sustained |
| Instagram CPU | Previously reappeared; latest force-stop test successful for 15 seconds |
| Instagram services | Latest output showed destroyed service records, not confirmed active services |
| Memory | Approximately 792 MB available in previous snapshot |
| Swap | Usage observed, no confirmed thrashing |
| Battery temperature | Normal in observed snapshots |
| Wake locks | No persistent active issue established |
| CPU tuning | Unmodified |
| Instagram AppOps | Both restrictions remain set to `ignore` |
| Battery drain rate | Not yet established |

## 7. Next steps

1. Leave the phone idle for approximately five minutes after force-stopping Instagram.
2. Check whether Instagram's process reappears.
3. If it reappears, inspect its process state, foreground activity, and currently active services.
4. Verify that both background AppOps restrictions remain active.
5. Avoid restricting Gmail because its CPU spike was not sustained.
6. Continue monitoring battery and CPU behavior.
7. Make only reversible, evidence-based modifications.

## 8. Diagnostic workflow

All future diagnostic blocks must:

- Be compatible with fish shell on Arch Linux.
- Run phone diagnostics through ADB.
- Display and save output to `/tmp/phone-diagnostic.txt`.
- Automatically copy output using `wl-copy`, `xclip`, or `xsel`.
- Avoid root-only commands and protected sysfs modifications.

## 9. Safety and methodology

- No root access is available.
- Do not attempt kernel or GPU frequency modifications.
- Do not force CPU frequencies or change governors without evidence.
- Do not disable Android system services just because they appear in process reports.
- Record every modification and its reversal command.
- Separate measurements from hypotheses.
- Prefer short, reversible experiments.

### Instagram restriction reversal

If Instagram background restrictions cause unwanted behavior, restore the default AppOps modes:

```sh
adb shell cmd appops set com.instagram.android RUN_IN_BACKGROUND default
adb shell cmd appops set com.instagram.android RUN_ANY_BACKGROUND default
```

### Current state

Instagram's two background AppOps restrictions remain active. Its process was successfully terminated and remained absent for 15 seconds in the latest test. Earlier diagnostics showed it reappearing, so longer idle monitoring is still required.

Gmail's high CPU reading was temporary. No persistent CPU overload, memory thrashing, or wake-lock problem has been established.

**Next priority:** Repeat the unusual memory-counter sample before proposing any OS-level changes.


## 10. OS and kernel investigation

**Started:** 30 October 2026  
**Access level:** ADB shell, non-root  
**Stage 1:** Read-only kernel and OS inventory

### Kernel and Android build

| Item | Observed value |
|---|---|
| Kernel | Linux 4.14.193+-ab478 |
| Kernel build | #1 SMP PREEMPT, Thu May 9 16:42:40 CST 2024 |
| Architecture reported by kernel | armv8l |
| Android release | 11 |
| Android SDK | 30 |
| Build fingerprint | `realme/RMX3231/RMX3231:11/RP1A.201005.001/1709693423112:user/release-keys` |
| Board / hardware property | RMX3231 |
| Kernel configuration | `/proc/config.gz` exists and is readable |

The kernel is a vendor build based on Linux 4.14.193. The available configuration archive is a useful next source of evidence, but its options have not yet been inspected. The reported `armv8l` value is the kernel's architecture string and does not change the previously observed ARM Cortex-A55 CPU inventory.

### CPU frequency scaling

Both CPU policies report the `schedutil` governor. Available governors are `userspace`, `powersave`, `performance`, and `schedutil`.

| Policy | CPU cluster | Minimum | Maximum | Current at inventory |
|---|---|---:|---:|---:|
| policy0 | CPUs 0–3 | 768 MHz | 1.2 GHz | 768 MHz |
| policy4 | CPUs 4–7 | 768 MHz | 1.6 GHz | 1.6 GHz |

These current-frequency values are single snapshots, not evidence of a sustained frequency state or a performance problem. No governor or frequency changes were made.

### Scheduler, memory, zRAM, and storage interfaces

- The queried `/proc/sys/kernel/sched_*` files returned no values.
- The queried debug scheduler directory returned no listing.
- `/proc/swaps` returned **Permission denied** to the ADB shell.
- `/sys/block/zram0` exists, but the requested zRAM attributes did not return readable values.
- The queried VM sysctl files and low-memory-killer parameter returned no values.
- The queried block queue scheduler and read-ahead attributes returned no values for the listed MMC devices.

These results mean the current ADB-shell inventory could not establish the active swap configuration, zRAM compression algorithm or statistics, VM tunables, or storage scheduler. They must not be interpreted as proof that those kernel facilities are disabled.

### Thermal subsystem

Android Thermal HAL 2.0 is connected and reports **Thermal Status 0** (no thermal severity reported at the time of capture).

Temperatures from the captured inventory:

| Sensor | Cached value | HAL current value |
|---|---:|---:|
| CPU | 49.52°C | 42.272°C |
| GPU | 45.197°C | 40.682°C |
| Board | 42.167°C | 38.494°C |

A cooling device named `test cooling device` reported value 100. Its meaning and scale are not established by this snapshot, so it is not being treated as proof of active throttling. Temperature readings are point-in-time observations.

### Kernel modules

The module inventory includes vendor graphics/display components (`pvrsrvkm`, `sprd_dpu`, `dpu_*`), Unisoc/Spreadtrum camera, sensor, Wi-Fi and Bluetooth components, plus Android kernel facilities such as Binder, ashmem-related components, dm-verity, FUSE, and zRAM-related block infrastructure.

The presence of a module does not establish that it is currently loaded and active in a performance-critical path, nor that changing it would improve performance.

### Stage 1 conclusions

1. This is a vendor Linux 4.14.193 PREEMPT kernel on Android 11, not a modern upstream kernel.
2. CPU frequency scaling is already using `schedutil`; there is no evidence supporting a governor change.
3. The big CPU policy reached its reported 1.6 GHz maximum in one sample. This is not a reason to lock it at that frequency.
4. Thermal HAL reports status 0. No thermal throttling has been established.
5. zRAM, swap, VM and storage scheduler details remain unresolved because the relevant interfaces were unavailable or unreadable to the shell.
6. No OS, kernel, scheduler, memory, storage, thermal, or graphics settings were changed during this stage.

## 11. OS/kernel optimization plan

The next phase remains read-only until each subsystem is understood. The immediate priority is to inspect the readable kernel configuration and obtain better evidence about memory/swap and storage behavior. Any later tuning must have a measurable baseline, a reversible change, and an after-test.

| Stage | Investigation | Status |
|---|---|---|
| 0 | Device and access baseline | Complete |
| 1 | Kernel and OS inventory | Complete; 30 Oct 2026 |
| 2 | Kernel configuration, memory pressure, zRAM/swap | In progress; read-only diagnostics prepared |
| 3 | CPU scheduler and cpufreq behavior | Pending |
| 4 | Storage I/O scheduler and latency | Pending |
| 5 | Thermal behavior under a repeatable workload | Pending |
| 6 | Display/compositor frame pacing | Pending |
| 7 | Android framework settings and reversible tuning | Pending |
| 8 | Before/after validation and rollback review | Pending |

**Constraint:** The phone is not rooted. ADB shell access does not grant permission to modify protected kernel interfaces. Do not attempt writes to protected `/sys`, `/proc`, or vendor nodes, and do not recommend root-only tuning as if it were available. Building or flashing a custom kernel would be a separate, higher-risk project requiring verified device-specific source, configuration, toolchain, boot image details, and a recovery path.


### Stage 2 preparation: memory and zRAM read-only checks

The next diagnostic pass is designed to distinguish configuration from live behavior:

- Pull the readable kernel config to the Linux host and inspect only relevant swap, zRAM, zsmalloc, memory-management, reclaim, and low-memory-killer options.
- Capture `/proc/meminfo` and selected `/proc/vmstat` counters twice, ten seconds apart. Counter deltas such as page scanning, page stealing, and swap I/O are more informative than a single low `MemFree` value.
- Inspect zRAM sysfs permissions and readable attributes without attempting writes.
- Capture Android's `dumpsys meminfo` summary as a framework-level cross-check.
- Re-check `/proc/swaps`; if it remains denied, record that limitation rather than inferring swap state.

No changes are authorized by this diagnostic stage. In particular, do not change `swappiness`, zRAM size/algorithm, LMK settings, or storage queue parameters based on configuration flags alone.


### Stage 2 results: kernel configuration and memory observations

**Date:** 30 October 2026  
**Method:** Read-only ADB diagnostics and host-side inspection of the pulled kernel config.

#### Kernel configuration flags

The pulled `/proc/config.gz` confirms these options are enabled:

| Option | Result |
|---|---|
| `CONFIG_SWAP` | `y` |
| `CONFIG_PSI` | `y` |
| `CONFIG_MEMCG` | `y` |
| `CONFIG_VM_EVENT_COUNTERS` | `y` |
| `CONFIG_COMPACTION` | `y` |
| `CONFIG_MIGRATION` | `y` |
| `CONFIG_ZSMALLOC` | `y` |
| `CONFIG_ZRAM` | `y` |
| `CONFIG_ZRAM_WRITEBACK` | `y` |

These flags confirm kernel build support only. They do not reveal the live zRAM configuration, compression algorithm, backing device, or writeback state.

#### Runtime access limitations

- `/proc/swaps` returned **Permission denied**.
- `/sys/block/zram0` and its `disksize`, `comp_algorithm`, `mm_stat`, `stat`, and `writeback` attributes all returned **Permission denied**.
- `/proc/pressure/memory` returned **Permission denied**. CPU and I/O pressure entries were also listed but inaccessible.
- No protected interface was written to.

#### Memory snapshots

| Metric | Snapshot 1 | Snapshot 2, 10 seconds later |
|---|---:|---:|
| MemTotal | 1,914,140 KB | 1,914,140 KB |
| MemFree | 37,196 KB | 35,016 KB |
| MemAvailable | 653,216 KB | 648,648 KB |
| Cached | 657,832 KB | 656,556 KB |
| SwapTotal | 1,435,600 KB | 1,435,600 KB |
| SwapFree | 481,040 KB | 451,256 KB |
| AnonPages | 326,460 KB | 304,252 KB |

MemAvailable changed by approximately -4.5 MB during the interval. Reported SwapFree decreased by approximately 29.1 MB, but the `pswpin` and `pswpout` counters did not change. This short sample does not establish sustained swap pressure; the mismatch needs another sample rather than an assumption.

#### VM counter deltas over 10 seconds

| Counter | Snapshot 1 | Snapshot 2 | Delta |
|---|---:|---:|---:|
| workingset_refault | 17,006 | 17,037 | +31 |
| pswpin | 12,800 | 12,800 | 0 |
| pswpout | 1,024 | 1,024 | 0 |
| allocstall_dma | 299,868,439 | 299,879,352 | +10,913 |
| allocstall_normal | 1,723,955,770 | 1,723,991,241 | +35,471 |
| allocstall_movable | 0 | 0 | 0 |
| pgsteal_kswapd | 369,221,002 | 369,232,318 | +11,316 |
| pgsteal_direct | 228,093,001 | 228,096,540 | +3,539 |
| pgscan_kswapd | 431 | 431 | 0 |
| pgscan_direct | 795,656,890 | 795,664,689 | +7,799 |
| pgscan_direct_throttle | 455,370,066 | 455,376,025 | +5,959 |
| oom_kill | 334,611 | 334,617 | +6 |

The reclaim/allocstall deltas are unusually large, and `oom_kill` increased by six. However, MemAvailable remained around 649–653 MB and swap I/O counters did not change. Vendor-kernel counter behavior or semantics may differ; one short sample is not enough to conclude that the phone is actively suffering OOM events or user-visible memory thrashing. Repeat the counters and compare them with available lmkd/kernel logs before diagnosing.

#### Android process memory snapshot

Largest RSS entries in the captured `dumpsys meminfo` summary:

| Process | RSS |
|---|---:|
| ChatGPT | 219,388 KB |
| X | 185,936 KB |
| system | 182,824 KB |
| LinkedIn | 167,000 KB |
| Gmail | 165,872 KB |
| Instagram | 146,324 KB |
| Google Play services | 125,024 KB |
| GitHub | 102,784 KB |
| System UI | 96,396 KB |
| Niagara Launcher | 86,892 KB |

RSS includes shared pages and is not equivalent to private memory use. This is a single snapshot and does not identify an app that should be restricted. The command's broken-pipe message occurred because output was intentionally limited with `head -70`; it is not evidence of a device crash.

#### Stage 2 conclusion

1. The kernel has swap, zRAM, zsmalloc, zRAM writeback, PSI, memory-cgroup, compaction, migration, and VM-event-counter support compiled in.
2. Live zRAM details, the swap table, and PSI readings remain inaccessible to the non-root ADB shell.
3. MemAvailable remained around 649–653 MB during the short sample.
4. SwapFree dropped by about 29 MB, but `pswpin` and `pswpout` did not change. This inconsistency needs verification.
5. Reclaim/allocstall counters increased, and `oom_kill` rose by six. Treat this as an anomaly to validate, not a confirmed diagnosis.
6. No memory, swap, zRAM, LMK, or kernel settings were changed.

**Next action:** Repeat the selected VM counters and meminfo after a short interval, and inspect available Android lmkd/kernel log evidence if readable. Do not tune zRAM or memory policy until this is understood.


### Stage 2 follow-up: repeat memory counters and OOM evidence

**Time:** 30 October 2026, 11:59:56–12:00:17 IST  
**Method:** Two read-only samples 20 seconds apart, plus log and service checks.

| Metric | Sample 1 | Sample 2 | Change |
|---|---:|---:|---:|
| MemFree | 37,380 KB | 37,884 KB | +504 KB |
| MemAvailable | 646,308 KB | 628,612 KB | -17,696 KB |
| SwapTotal | 1,435,600 KB | 1,435,600 KB | 0 |
| SwapFree | 696,652 KB | 682,452 KB | -14,200 KB |
| AnonPages | 429,936 KB | 413,300 KB | -16,636 KB |
| workingset_refault | 16,630 | 16,630 | 0 |
| pswpin | 12,800 | 12,800 | 0 |
| pswpout | 1,024 | 1,024 | 0 |
| allocstall_dma | 299,910,919 | 299,930,198 | +19,279 |
| allocstall_normal | 1,724,389,567 | 1,724,459,907 | +70,340 |
| pgsteal_kswapd | 369,448,065 | 369,468,195 | +20,130 |
| pgsteal_direct | 228,149,785 | 228,165,012 | +15,227 |
| pgscan_kswapd | 431 | 431 | 0 |
| pgscan_direct | 795,709,897 | 795,735,146 | +25,249 |
| pgscan_direct_throttle | 455,408,299 | 455,419,414 | +11,115 |
| oom_kill | 334,640 | 334,649 | +9 |

The available-memory reduction was about 17.3 MiB, and SwapFree fell about 13.9 MiB. However, the swap-in/out counters did not change, so this is not enough to attribute the SwapFree change to ordinary swap I/O.

The reclaim and allocation-stall counters continued increasing rapidly. The `oom_kill` counter rose by nine, but the queried logcat buffers contained no matching `lmkd` or `lowmemorykiller` messages, and the queried kernel log search returned no OOM/killed-process messages. The Binder service-list query returned no service name matching LMK or memory.

**Interpretation:** This is a repeatable counter anomaly that warrants checking process-exit records and the actual lmkd process. The counters alone do not identify which process was killed or establish user-visible memory pressure. No changes were made.


### Stage 2 follow-up: LMKD and process-kill evidence

**Date:** 30 October 2026  
**Method:** Read-only inspection of the lmkd process, low-memory properties, Android event log, ActivityManager exit history, and VM counters.

#### LMKD status and configuration

The low-memory-killer daemon is running:

- PID: `323`
- Process: `lmkd`
- Init service state: `running`

Relevant properties reported by the device:

| Property | Value |
|---|---:|
| `ro.lmk.critical` | 201 |
| `ro.lmk.critical_upgrade` | true |
| `ro.lmk.downgrade_pressure` | 60 |
| `ro.lmk.kill_heaviest_task` | false |
| `ro.lmk.low` | 1001 |
| `ro.lmk.medium` | 700 |
| `ro.lmk.psi_complete_stall_ms` | 400 |
| `ro.lmk.swap_free_low_percentage` | 20 |
| `ro.lmk.upgrade_pressure` | 30 |
| `ro.lmk.use_minfree_levels` | false |
| `persist.sys.zram_enabled` | 1 |
| `persist.sys.lmk.reportkills` | true |

The properties document the vendor's configured LMKD policy. Their presence does not by itself indicate that the thresholds are currently being crossed. No property was changed.

#### Actual process-kill evidence

Unlike the earlier log query, this event-log capture contains direct LMKD `killinfo` records followed by matching ActivityManager process-death records.

At approximately **12:01:33**, LMKD emitted killinfo records for processes whose subsequent `am_proc_died` entries included:

- `com.google.process.gservices`
- `com.google.process.gapps`
- `com.facebook.services`
- `com.github.android`
- `com.android.vending:background`
- `com.instagram.android`

At approximately **12:02:52**, another group of LMKD killinfo records was followed by process-death entries for Brave browser and its Chromium child processes.

This is evidence that LMKD did kill cached/background processes during the captured period. It also confirms that the earlier increase in the `oom_kill` counter should not be dismissed as merely a display anomaly. The logs do not, by themselves, establish that the user experienced visible lag or that every process death was caused by the same memory-pressure episode.

The event log also contains separate ActivityManager `am_kill` entries with reasons such as `empty #4`, `empty #5`, and `remove task`. These are distinct framework kill records; they should not all be attributed to LMKD.

#### ActivityManager exit history

`dumpsys activity exit-info` is supported on this Android build and returned historical process-exit records. The captured first 120 lines showed older records for `com.google.android.apps.restore`, including an older `LOW_MEMORY` exit on 21 October. The output was truncated before a complete recent-exit review, so it does not provide a complete per-package explanation for the 30 October LMKD events.

#### VM counter snapshot

At the end of this diagnostic, the counters were:

| Counter | Value |
|---|---:|
| `pswpin` | 12,800 |
| `pswpout` | 1,024 |
| `allocstall_normal` | 1,726,622,055 |
| `pgsteal_direct` | 228,457,577 |
| `pgscan_direct` | 796,886,580 |
| `pgscan_direct_throttle` | 456,163,318 |
| `oom_kill` | 335,261 |

These are cumulative counters, not rates. Their absolute magnitudes cannot be used to infer current pressure without a fresh timed delta. Earlier short samples showed rapid counter increases while MemAvailable remained roughly 628–653 MB and swap I/O counters stayed unchanged. The new killinfo records now establish that some LMKD kills did occur, but a controlled before/after workload is still needed to quantify how often this happens and whether it affects responsiveness.

#### Stage 2 interpretation and decision

1. LMKD is active and has reported actual process kills, including Instagram, Google background processes, GitHub, Facebook services, Play Store background, and Brave processes in the captured event window.
2. Android also independently killed some cached/empty or task-removed processes; those framework events should not be conflated with LMKD kills.
3. The available exit-info excerpt is incomplete and does not fully explain the latest kill batch.
4. The current evidence confirms background process reclamation, but does not yet prove harmful user-visible memory thrashing. MemAvailable, timed VM counter deltas, swap I/O, and user-visible app reloads must be correlated.
5. No LMKD properties, zRAM settings, swap settings, VM tunables, or kernel parameters were modified.

**Next action:** Complete a short controlled memory-pressure check with a fresh baseline, then a timed follow-up while performing a consistent everyday workload. Record MemAvailable, SwapFree, `pswpin`/`pswpout`, reclaim/allocstall deltas, and whether recently used apps are unexpectedly killed or need to reload. Do not weaken LMKD or change zRAM policy to keep more apps resident; that could make a 2 GB device less stable.


### Stage 2 follow-up: 90-second normal-use memory test

**Date:** 30 October 2026, 12:05:07–12:06:37 IST  
**Method:** Read-only memory snapshots and Android event-log review before and after approximately 90 seconds of ordinary app switching.

#### Memory snapshot

| Metric | Baseline | Follow-up | Change |
|---|---:|---:|---:|
| MemFree | 36,328 KB | 43,780 KB | +7,452 KB |
| MemAvailable | 821,456 KB | 592,340 KB | -229,116 KB |
| SwapTotal | 1,435,600 KB | 1,435,600 KB | 0 |
| SwapFree | 685,460 KB | 385,908 KB | -299,552 KB |
| AnonPages | 314,872 KB | 314,524 KB | -348 KB |

MemAvailable fell by approximately 223.7 MiB and SwapFree by approximately 292.5 MiB during the interval, while AnonPages was almost unchanged. This does not show that 292.5 MiB of new application data was swapped out. The relationship between the reported swap-free change and actual swap I/O remains unresolved; the expected `/proc/vmstat` lines were not present in the pasted output for this test, so no timed swap-in/out or reclaim-counter delta can be calculated from it.

#### Process-kill events

The baseline event-log excerpt already contained vendor `rampolicy` kills immediately before the test, including Google background processes, Google Play services, HeyTap and Spreadtrum processes. Brave and Gmail also had separate `remove task` kill records.

During the 90-second interval, the follow-up event log showed:

- Android removed empty cached Google processes.
- At approximately 12:05:42, LMKD emitted five `killinfo` records. Matching process-death records included `android.process.media`, `com.google.android.permissioncontroller`, `com.facebook.services`, `com.github.android`, and `com.openai.chatgpt`.
- At approximately 12:06:13–12:06:32, further vendor `rampolicy` kills affected HeyTap, Spreadtrum, Facebook App Manager, Google extension services, TalkBack, Flipkart, Google background processes and other vendor processes.
- A further LMKD batch at approximately 12:06:17 had matching process-death records for Facebook System, Android Contacts/People (`android.process.acore`) and Gmail.

This confirms that process reclamation continued during the normal-use test. The event records distinguish LMKD `killinfo` batches from ActivityManager `rampolicy` and `empty #4` kills; these mechanisms should not be treated as identical.

#### Interpretation and limitations

1. The device reclaimed multiple cached/background processes during ordinary use, including some app processes. This can cause an app to recreate its process or reload when reopened.
2. The test output does not state exactly which apps were opened or whether their screens visibly reloaded, so the user-visible impact is not yet measured.
3. MemAvailable decreased materially, but remained about 578 MiB at the end of the sample.
4. SwapFree decreased materially while AnonPages stayed nearly flat. Because the timed VM counters were absent from the pasted output, this sample cannot establish the cause or amount of swap traffic.
5. The repeated vendor `rampolicy` kills indicate an additional vendor process-management policy is active alongside LMKD. The exact policy implementation and thresholds have not been established.
6. No LMKD, rampolicy, zRAM, swap, or VM settings were changed.

**Next action:** Identify which apps were deliberately used during the 90-second test and whether they reloaded when revisited. Then collect a clean short sample that explicitly prints `/proc/vmstat` before and after, alongside MemAvailable, SwapFree, AnonPages, and recent kill events. Do not disable rampolicy or weaken LMKD based on these observations alone.


### Stage 2 user-visible impact check

**Date:** 30 October 2026  
**User-reported workload:** Switched between WhatsApp, Instagram, and YouTube during the 90-second normal-use test.  
**Observed user-visible result:** None of these three apps reloaded when revisited.

This is an important distinction: although LMKD and vendor `rampolicy` killed other cached/background processes during the interval, the three apps the user actively switched between remained available without a visible reload. The test therefore confirms background process reclamation, but does not demonstrate that the observed kills disrupted this particular multitasking workload.

The result does not prove that all app switching is unaffected or that memory pressure never causes reloads. It does mean that changing LMKD or vendor memory policy is not justified by the current user-visible evidence. Keep the stock memory-management policy unchanged.

**Stage 2 practical conclusion:** Memory reclamation is observable, but no adverse effect was reported in the tested WhatsApp/Instagram/YouTube switching sequence. The unresolved SwapFree/AnonPages discrepancy and lack of timed VM counter output remain diagnostic limitations. No memory-related settings were changed.
