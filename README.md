# Classic Launchpad

English | [简体中文](README.zh-CN.md)

A native macOS app that brings back the classic full-screen Launchpad experience.

📖 [User Guide](docs/User-Guide.md)

## Current release and compatibility

| | |
| --- | --- |
| Current version | [v1.0.4](https://github.com/Daniel-li121/classic-launchpad/releases/tag/v1.0.4) |
| Supported macOS versions | macOS 15 or later |
| Supported Macs | Apple Silicon only |

## Installation

1. Download `Classic-Launchpad-1.0.4-arm64.zip` from the [latest GitHub Release](https://github.com/Daniel-li121/classic-launchpad/releases/latest).
2. Unzip the download.
3. Drag `Classic Launchpad.app` into the **Applications** folder.
4. Open Classic Launchpad from the Applications folder.

The current download uses a local ad-hoc signature and has not been notarized by Apple. On first launch, macOS may prevent it from opening. Control-click the app, choose **Open**, and confirm **Open**. If it is still blocked, open **System Settings → Privacy & Security**, find the message about Classic Launchpad, and choose **Open Anyway**. Only bypass this warning for a copy downloaded from this repository.

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

The packaging script creates an arm64 release build for Apple Silicon, generates the app icon, assembles and locally signs the `.app` bundle, and writes a shareable ZIP to `dist/Classic-Launchpad-<version>-arm64.zip`.

Gesture monitoring uses the MIT-licensed [OpenMultitouchSupport](https://github.com/Kyome22/OpenMultitouchSupport), which reads raw touch points through macOS's private MultitouchSupport framework. This means the local build does not require Accessibility permission, but it is not suitable for Mac App Store distribution.

## Reporting issues

Before opening a report, please search the [existing issues](https://github.com/Daniel-li121/classic-launchpad/issues) for the same problem. If it has not been reported, [create a new issue](https://github.com/Daniel-li121/classic-launchpad/issues/new) and include:

- Classic Launchpad version
- macOS version and Mac model or chip
- Steps that consistently reproduce the problem
- What you expected to happen and what happened instead
- Relevant screenshots, screen recordings, or logs
- For gesture problems, the related Classic Launchpad and macOS trackpad settings

## Development

```bash
swift run ClassicLaunchpad
swift test
```
