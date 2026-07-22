# Classic Launchpad User Guide

English | [简体中文](User-Guide.zh-CN.md)

This guide applies to Classic Launchpad 1.0.3 on macOS 15 or later.

## Quick start

1. Open Classic Launchpad from the Applications folder.
2. Pinch inward with your thumb and three fingers to show it again at any time.
3. Swipe left or right with two fingers to change pages.
4. Click an app icon to launch it. Classic Launchpad dismisses automatically.
5. Spread your thumb and three fingers, press `Esc`, or click an empty area to dismiss it.

## Core features

### Browse apps full screen

Classic Launchpad scans `/Applications`, `/System/Applications`, and the Applications folder in your home directory. The grid automatically adapts from 4–9 columns and 3–5 rows to fit the current screen. Apps are placed on additional pages when necessary.

Clearly technical components such as helpers, shims, updaters, agents, daemons, and XPC services are hidden. User-facing system launchers and menu bar apps remain visible.

### Navigate pages

- Swipe horizontally with two fingers on a trackpad.
- Drag the page horizontally with a mouse.
- Press the left or right arrow key.
- Click a page dot at the bottom of the screen.

Page changes use an interactive, full-page Launchpad-style animation. Dragging beyond the first or last page adds edge resistance instead of changing pages.

### Search

Use the search field or press `⌘F`. Search matches both the displayed app name and its bundle identifier. Clear the search field to return to the saved page layout.

### Reorder apps

Drag an icon onto another icon to change its position. To move an app to another page, keep dragging it near the left or right edge for about half a second; the destination page opens automatically, and you can drop the icon there.

The order and page assignments are saved between launches. Moving an app from one page to another does not automatically pull the first app from the next page back to fill the gap. Reordering is disabled while search is active, so clear the search field first.

## Trackpad gestures

| Gesture | Action |
| --- | --- |
| Thumb + three fingers, pinch inward | Show Classic Launchpad |
| Thumb + three fingers, spread outward | Dismiss Classic Launchpad |
| Two fingers, swipe left or right | Change pages while Classic Launchpad is visible |

The four-finger gesture works while the app is running in the background. Horizontal four-finger Space switching is ignored by the pinch recognizer.

## Settings

Open settings with the gear button next to the search field or press `⌘,`.

| Setting | Default | Behavior |
| --- | --- | --- |
| Run in background | On | Dismissing the interface hides it while the app remains ready for the trackpad gesture. When off, dismissing the interface quits the app. |
| Intercept four-finger gesture | On | Uses the classic pinch gesture for Classic Launchpad. Turn it off to hand the gesture back to macOS without quitting. |
| Launch at login | Off | Starts Classic Launchpad automatically after signing in. macOS may require approval in Login Items & Extensions. |

Move the app into the Applications folder before enabling launch at login.

## Dismiss versus quit

These two actions are intentionally different:

- **Dismiss:** clicking an app, clicking an empty area, pressing `Esc`, or spreading four fingers hides the interface. With **Run in background** enabled, Classic Launchpad keeps running and continues to receive the pinch gesture.
- **Quit:** press `⌘Q`, choose **Classic Launchpad → Quit Classic Launchpad**, or quit it from the Dock. The app stops all trackpad monitoring and returns gesture handling to macOS.

If **Run in background** is disabled, every dismiss action also quits the app.

## Less obvious features and behavior

### The native Apps/Launchpad gesture returns after quitting

When Classic Launchpad intercepts the four-finger gesture, the system Apps interface (called Launchpad on earlier macOS versions) cannot receive the same gesture. Quitting Classic Launchpad releases the raw trackpad monitor and restores the native macOS response.

On some macOS versions, Dock can retain an old gesture registration. To guarantee that the native Apps gesture returns, Classic Launchpad briefly reloads Dock during quit if raw gesture monitoring was used. The Dock may disappear and reappear for a moment; this is expected and does not close your running apps or windows.

You can also turn off **Intercept four-finger gesture** in settings to return the gesture to macOS while leaving Classic Launchpad running.

### Gesture monitoring recovers automatically after login

When Classic Launchpad starts as a login item, macOS may still be initializing the trackpad service. The app now verifies that the listener was actually installed and keeps retrying automatically until the trackpad becomes available. You no longer need to quit and reopen the app after restarting the Mac. The same retry mechanism also supports an external trackpad connected later.

### The app list refreshes automatically

Classic Launchpad rescans installed apps when it is shown if the previous scan is more than 60 seconds old. Press `⌘R` to rescan immediately after installing or removing an app.

### Empty page space is preserved

Page assignments are saved independently from sorting. Moving an icon to a later page intentionally leaves its old page partially empty instead of pulling another icon backward.

### Search temporarily changes the layout

Search results are repaginated from the first page and do not change the saved icon order. Drag sorting is unavailable until the search field is cleared.

### The wallpaper is cached for performance

The blurred desktop wallpaper is rendered once when Classic Launchpad starts. If you change the desktop wallpaper while it is running, quit and reopen Classic Launchpad to update the background.

## Keyboard shortcuts

| Shortcut | Action |
| --- | --- |
| `Esc` | Dismiss Classic Launchpad |
| `←` / `→` | Previous or next page |
| `⌘F` | Show Classic Launchpad and focus search |
| `⌘R` | Rescan installed apps |
| `⌘,` | Open settings |
| `⇧⌘L` | Use the app menu command to show Launchpad |
| `⌘Q` | Quit completely and restore the native gesture |

## Troubleshooting

### The four-finger gesture does not open Classic Launchpad

- Confirm that Classic Launchpad is still running.
- Open settings and enable **Intercept four-finger gesture**.
- If **Run in background** is off, dismissing the interface quits the app; reopen it before trying the gesture.
- Quit and reopen Classic Launchpad if the trackpad was disconnected or changed.

### A newly installed app is missing

Press `⌘R` to rescan. Confirm that the app is inside `/Applications`, `/System/Applications`, or your home Applications folder.

### Launch at login needs approval

Use the button shown in Classic Launchpad settings to open **System Settings → General → Login Items & Extensions**, then approve Classic Launchpad.

### The system Apps/Launchpad gesture does not respond

Quit Classic Launchpad completely with `⌘Q`, wait for Dock to reload, and try the gesture again. Hiding the interface is not the same as quitting when background operation is enabled.

## Feedback

Search the [existing issues](https://github.com/Daniel-li121/classic-launchpad/issues) or [open a new issue](https://github.com/Daniel-li121/classic-launchpad/issues/new). Include the Classic Launchpad version, macOS version, Mac model or chip, reproduction steps, expected and actual behavior, and any useful screenshots or recordings.
