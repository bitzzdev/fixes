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

**Next priority:** Determine whether Instagram restarts during a longer idle period and, if so, identify what triggers it.
