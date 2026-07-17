# Classic Launchpad

English | [简体中文](README.zh-CN.md)

A native macOS app that brings back the classic full-screen Launchpad experience.

## Download

Download the universal build for both Apple Silicon and Intel Macs from [GitHub Releases](https://github.com/Daniel-li121/classic-launchpad/releases/latest).

## Features

- Displays apps from `/Applications`, `/System/Applications`, and the user's Applications folder in a full-screen grid
- Automatically uses and blurs the current desktop wallpaper
- Multi-page grid with two-finger trackpad swipes, horizontal mouse dragging, and arrow-key navigation
- Interactive dragging, edge resistance, and classic Launchpad-style page transitions
- Cached wallpaper blur, on-demand rendering of adjacent pages, and app icon preloading
- Built-in settings for background operation, four-finger gesture interception, and launch at login
- Global classic “thumb + three fingers” pinch gesture to show Launchpad and spread gesture to dismiss it
- Search by app name or bundle identifier
- Click an icon to launch an app and dismiss Launchpad automatically
- Click the empty background outside the grid to dismiss, with no separate close button
- Keyboard shortcuts: `Esc` to dismiss, `⌘F` to search, `⌘R` to rescan, and `⇧⌘L` to show from the menu

## Build

Requires macOS 15 or later and a Swift 6 toolchain. After its first launch, the app stays available in the background so it can be opened at any time with the four-finger pinch gesture.

```bash
./scripts/package-app.sh
open "dist/Classic Launchpad.app"
```

The packaging script creates a release build, generates the app icon, assembles the `.app` bundle, and applies a local ad-hoc signature.

To create a shareable ZIP that supports both Apple Silicon and Intel Macs:

```bash
./scripts/package-app.sh --universal
```

Gesture monitoring uses the MIT-licensed [OpenMultitouchSupport](https://github.com/Kyome22/OpenMultitouchSupport), which reads raw touch points through macOS's private MultitouchSupport framework. This means the local build does not require Accessibility permission, but it is not suitable for Mac App Store distribution.

## Development

```bash
swift run ClassicLaunchpad
swift test
```
