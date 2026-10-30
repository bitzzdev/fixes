# Fixing VLC "Codec not supported: h264" on Arch Linux

## Problem

VLC fails to play H.264 videos and shows:

```
Codec not supported:
VLC could not decode the format "h264" (H264 - MPEG-4 AVC (part 10))
```

Even though `ffmpeg` is installed.

---

## Cause

On newer Arch Linux releases, the FFmpeg decoder is **not included** in the base `vlc` package.

Instead, it is provided by the separate package:

- `vlc-plugin-ffmpeg`

Without this plugin, VLC cannot decode H.264, H.265, AV1, and many other formats.

---

## Diagnosis

### Check VLC version

```bash
vlc --version
```

### Check installed packages

```bash
pacman -Q vlc ffmpeg
```

### Verify the FFmpeg plugin exists

```bash
find /usr/lib/vlc/plugins -name "*avcodec*"
```

If this prints **nothing**, the FFmpeg plugin is missing.

---

## Fix

Install the FFmpeg plugin:

```bash
sudo pacman -S vlc-plugin-ffmpeg
```

---

## Verify

Check that the plugin now exists:

```bash
find /usr/lib/vlc/plugins -name "*avcodec*"
```

Expected output:

```text
/usr/lib/vlc/plugins/codec/libavcodec_plugin.so
```

Open the video again.

The H.264 codec error should be gone.

---

## If `vlc-plugin-ffmpeg` is not found

Update the package databases and list available VLC plugins:

```bash
sudo pacman -Sy
pacman -Ss "^vlc-plugin"
```

Install the package that provides FFmpeg support.

---

## Useful Debug Commands

```bash
# VLC version
vlc --version

# Installed packages
pacman -Q vlc ffmpeg

# Search for FFmpeg plugin
find /usr/lib/vlc/plugins -name "*avcodec*"

# Check package contents
pacman -Ql vlc

# Debug playback
vlc -vvv /path/to/video.mp4

# Inspect video
ffprobe /path/to/video.mp4
```

---

## Root Cause Summary

- ❌ Not a corrupt video
- ❌ Not a broken FFmpeg installation
- ❌ Not missing system libraries
- ✅ Missing `vlc-plugin-ffmpeg` package

Installing `vlc-plugin-ffmpeg` restores H.264 decoding.
