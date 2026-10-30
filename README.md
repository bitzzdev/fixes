# Fixes

A practical, evidence-based collection of device, operating-system, application, and network fixes. Each guide records the environment, diagnostics, changes, verification, and rollback steps.

## Categories

| Folder | Scope |
|---|---|
| [android/](android/) | Android devices, ADB, apps, storage, battery, and performance |
| [linux/](linux/) | Linux distributions, desktop environments, kernel, and packages |
| [windows/](windows/) | Windows system, drivers, applications, and storage |
| [network/](network/) | Wi-Fi, hotspot, connectivity, ADB networking, and protocols |
| [cross-platform/](cross-platform/) | Workflows and fixes shared across platforms |

## Android guides

- [Realme C11 RMX3231 optimization log](android/realme-c11-rmx3231-optimization.md)
- [Android storage optimization](android/storage-optimization.md)

## Documentation principles

- Diagnose before changing settings.
- Prefer read-only checks before modifications.
- Avoid destructive commands unless the target and consequences are explicit.
- Record exact device/build context and measured results.
- Include rollback instructions for reversible changes.
- Never treat a single snapshot as proof of a persistent problem.
