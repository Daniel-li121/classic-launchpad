import AppKit
import ServiceManagement
import SwiftUI

@MainActor
final class LaunchpadSettings: ObservableObject {
    private enum Key {
        static let runInBackground = "runInBackground"
        static let interceptSystemGesture = "interceptSystemGesture"
    }

    private let defaults: UserDefaults
    private let loginItemService = SMAppService.mainApp

    @Published var runInBackground: Bool {
        didSet {
            defaults.set(runInBackground, forKey: Key.runInBackground)
        }
    }

    @Published var interceptSystemGesture: Bool {
        didSet {
            defaults.set(interceptSystemGesture, forKey: Key.interceptSystemGesture)
            NotificationCenter.default.post(name: .launchpadGesturePreferenceChanged, object: nil)
        }
    }

    @Published private(set) var launchAtLoginEnabled = false
    @Published private(set) var loginItemRequiresApproval = false
    @Published private(set) var loginItemError: String?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        runInBackground = defaults.object(forKey: Key.runInBackground) as? Bool ?? true
        interceptSystemGesture = defaults.object(forKey: Key.interceptSystemGesture) as? Bool ?? true
        refreshLoginItemStatus()
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        loginItemError = nil

        do {
            if enabled {
                if loginItemService.status != .enabled,
                   loginItemService.status != .requiresApproval {
                    try loginItemService.register()
                }
            } else if loginItemService.status != .notRegistered {
                try loginItemService.unregister()
            }
        } catch {
            loginItemError = error.localizedDescription
        }

        refreshLoginItemStatus()
    }

    func refreshLoginItemStatus() {
        let status = loginItemService.status
        launchAtLoginEnabled = status == .enabled || status == .requiresApproval
        loginItemRequiresApproval = status == .requiresApproval
    }

    func openLoginItemSettings() {
        SMAppService.openSystemSettingsLoginItems()
    }
}

struct LaunchpadSettingsView: View {
    @EnvironmentObject private var settings: LaunchpadSettings
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 11) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(.secondary)
                Text("Classic Launchpad 设置")
                    .font(.system(size: 19, weight: .semibold))
                Spacer()
                Button("完成") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }

            Divider()

            SettingsRow(
                icon: "moon.fill",
                title: "后台运行",
                detail: "开启时收起后仍会接管手势；关闭后，收起界面会退出 App 并把手势交还给 macOS。"
            ) {
                Toggle("", isOn: $settings.runInBackground)
                    .labelsHidden()
                    .toggleStyle(.switch)
            }

            SettingsRow(
                icon: "hand.pinch.fill",
                title: "接管四指手势",
                detail: "启用后，拇指与三指捏合会打开 Classic Launchpad；关闭此项或退出 App 时会立即交还给 macOS。"
            ) {
                Toggle("", isOn: $settings.interceptSystemGesture)
                    .labelsHidden()
                    .toggleStyle(.switch)
            }

            SettingsRow(
                icon: "power",
                title: "登录时自动启动",
                detail: "登录 macOS 后自动启动，以便随时使用触控板手势。"
            ) {
                Toggle(
                    "",
                    isOn: Binding(
                        get: { settings.launchAtLoginEnabled },
                        set: { enabled in
                            settings.setLaunchAtLogin(enabled)
                        }
                    )
                )
                .labelsHidden()
                .toggleStyle(.switch)
            }

            if settings.loginItemRequiresApproval {
                HStack {
                    Text("macOS 需要你在“登录项与扩展”中批准此登录项。")
                        .font(.system(size: 12))
                        .foregroundStyle(.orange)
                    Spacer()
                    Button("打开系统设置") {
                        settings.openLoginItemSettings()
                    }
                }
            }

            if let error = settings.loginItemError {
                Text("无法修改登录项：\(error)")
                    .font(.system(size: 12))
                    .foregroundStyle(.red)
                    .textSelection(.enabled)
            }

            Text("建议先将 App 放入“应用程序”文件夹，再启用自动启动。退出时为恢复系统 Apps 手势，Dock 会短暂重载。")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
        }
        .padding(24)
        .frame(width: 500)
        .frame(minHeight: 350)
        .background(.regularMaterial)
        .onAppear {
            settings.refreshLoginItemStatus()
        }
    }
}

private struct SettingsRow<Control: View>: View {
    let icon: String
    let title: String
    let detail: String
    let control: Control

    init(
        icon: String,
        title: String,
        detail: String,
        @ViewBuilder control: () -> Control
    ) {
        self.icon = icon
        self.title = title
        self.detail = detail
        self.control = control()
    }

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                Text(detail)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 18)
            control
        }
    }
}

extension Notification.Name {
    static let launchpadGesturePreferenceChanged = Notification.Name("ClassicLaunchpad.gesturePreferenceChanged")
    static let showLaunchpadSettings = Notification.Name("ClassicLaunchpad.showSettings")
    static let launchpadDidOpenApplication = Notification.Name("ClassicLaunchpad.didOpenApplication")
}
