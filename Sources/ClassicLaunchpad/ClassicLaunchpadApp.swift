import AppKit
import Darwin
import SwiftUI

@main
struct ClassicLaunchpadApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private let model = AppLibrary()
    private let settings = LaunchpadSettings()
    private let trackpadMonitor = TrackpadGestureMonitor()
    private let pageSwipeMonitor = HorizontalPageSwipeMonitor()
    private var window: NSWindow?
    private var didUseRawGestureMonitoring = false
    private var terminationTask: Task<Void, Never>?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        installMainMenu()
        createWindow()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applyGesturePreference),
            name: .launchpadGesturePreferenceChanged,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationWasOpened),
            name: .launchpadDidOpenApplication,
            object: nil
        )
        applyGesturePreference()
        pageSwipeMonitor.start()
        showLaunchpad()
    }

    func applicationWillTerminate(_ notification: Notification) {
        stopInputMonitoring()
        NotificationCenter.default.removeObserver(self)
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        guard terminationTask == nil else { return .terminateLater }

        // Releasing the private multitouch device is not enough on macOS 26:
        // Dock can retain a stale Apps-gesture registration. Give the device a
        // moment to settle, then restart Dock before completing termination.
        stopInputMonitoring()
        terminationTask = Task { [weak self, weak sender] in
            try? await Task.sleep(for: .milliseconds(180))
            self?.restartDockGestureServiceIfNeeded()
            try? await Task.sleep(for: .milliseconds(120))
            self?.terminationTask = nil
            sender?.reply(toApplicationShouldTerminate: true)
        }
        return .terminateLater
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showLaunchpad()
        return true
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        if window?.isVisible == false {
            showLaunchpad()
        }
    }

    @objc private func showLaunchpad() {
        guard let window else { return }
        if let screen = NSScreen.main ?? NSScreen.screens.first {
            window.setFrame(screen.frame, display: true)
        }
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        model.refreshIfNeeded()
    }

    @objc private func hideLaunchpad() {
        window?.orderOut(nil)
        if settings.runInBackground {
            NSApp.hide(nil)
        } else {
            stopInputMonitoring()
            NSApp.terminate(nil)
        }
    }

    private func createWindow() {
        guard let screen = NSScreen.main ?? NSScreen.screens.first else { return }

        let launchpadView = LaunchpadView(extendsIntoSafeArea: !isFourteenInchPreview, onDismiss: { [weak self] in
            self?.hideLaunchpad()
        })
        .environmentObject(model)
        .environmentObject(settings)

        let window = LaunchpadWindow(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        if isFourteenInchPreview {
            window.contentView = NSHostingView(
                rootView: FourteenInchPreviewContainer(content: launchpadView)
            )
        } else {
            window.contentView = NSHostingView(rootView: launchpadView)
        }
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = false
        window.level = .mainMenu + 1
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        window.delegate = self
        window.isReleasedWhenClosed = false
        window.acceptsMouseMovedEvents = true
        self.window = window
    }

    private var isFourteenInchPreview: Bool {
        Bundle.main.bundleURL.deletingPathExtension().lastPathComponent == "Classic Launchpad 14-inch Preview"
    }

    private func installMainMenu() {
        let mainMenu = NSMenu()

        let appItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "关于 Classic Launchpad", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "隐藏 Classic Launchpad", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        let settingsItem = NSMenuItem(title: "设置…", action: #selector(showSettings), keyEquivalent: ",")
        settingsItem.target = self
        appMenu.addItem(settingsItem)
        appMenu.addItem(withTitle: "退出 Classic Launchpad", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appItem.submenu = appMenu
        mainMenu.addItem(appItem)

        let viewItem = NSMenuItem()
        let viewMenu = NSMenu(title: "显示")
        let showItem = NSMenuItem(title: "显示 Launchpad", action: #selector(showLaunchpad), keyEquivalent: "l")
        showItem.keyEquivalentModifierMask = [.command, .shift]
        showItem.target = self
        viewMenu.addItem(showItem)
        let refreshItem = NSMenuItem(title: "重新扫描应用", action: #selector(refreshApplications), keyEquivalent: "r")
        refreshItem.keyEquivalentModifierMask = [.command]
        refreshItem.target = self
        viewMenu.addItem(refreshItem)
        let searchItem = NSMenuItem(title: "搜索", action: #selector(focusSearch), keyEquivalent: "f")
        searchItem.keyEquivalentModifierMask = [.command]
        searchItem.target = self
        viewMenu.addItem(searchItem)
        viewItem.submenu = viewMenu
        mainMenu.addItem(viewItem)

        NSApp.mainMenu = mainMenu
    }

    @objc private func refreshApplications() {
        model.refresh()
    }

    @objc private func focusSearch() {
        showLaunchpad()
        NotificationCenter.default.post(name: .focusLaunchpadSearch, object: nil)
    }

    private func startTrackpadGestures() {
        didUseRawGestureMonitoring = true
        trackpadMonitor.start { [weak self] gesture in
            guard let self else { return }
            switch gesture {
            case .pinchIn where self.window?.isVisible != true:
                self.showLaunchpad()
            case .pinchOut where self.window?.isVisible == true:
                self.hideLaunchpad()
            default:
                break
            }
        }
    }

    @objc private func applyGesturePreference() {
        if settings.interceptSystemGesture {
            startTrackpadGestures()
        } else {
            trackpadMonitor.stop()
        }
    }

    private func stopInputMonitoring() {
        trackpadMonitor.stop()
        pageSwipeMonitor.stop()
    }

    private func restartDockGestureServiceIfNeeded() {
        guard didUseRawGestureMonitoring else { return }
        for dock in NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.dock") {
            _ = Darwin.kill(dock.processIdentifier, SIGTERM)
        }
    }

    @objc private func applicationWasOpened() {
        hideLaunchpad()
    }

    @objc private func showSettings() {
        showLaunchpad()
        NotificationCenter.default.post(name: .showLaunchpadSettings, object: nil)
    }
}

private struct FourteenInchPreviewContainer<Content: View>: View {
    private let canvasSize = CGSize(width: 1512, height: 982)
    let content: Content

    var body: some View {
        GeometryReader { geometry in
            let inset: CGFloat = 20
            let availableWidth = max(1, geometry.size.width - inset * 2)
            let availableHeight = max(1, geometry.size.height - inset * 2)
            let scale = min(1, min(availableWidth / canvasSize.width, availableHeight / canvasSize.height))

            ZStack {
                Color.black

                ZStack {
                    content
                    Rectangle()
                        .stroke(.white.opacity(0.35), lineWidth: 1 / scale)
                        .allowsHitTesting(false)
                }
                .frame(width: canvasSize.width, height: canvasSize.height)
                .clipped()
                .scaleEffect(scale)
                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            }
        }
        .ignoresSafeArea()
    }
}

private final class LaunchpadWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}
