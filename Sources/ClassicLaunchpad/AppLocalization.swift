import Foundation

enum AppLanguage: CaseIterable, Equatable, Sendable {
    case english
    case simplifiedChinese
    case japanese

    static func resolve(preferredLanguages: [String]) -> AppLanguage {
        guard let identifier = preferredLanguages.first?.lowercased() else {
            return .english
        }

        let languageCode = identifier
            .replacingOccurrences(of: "_", with: "-")
            .split(separator: "-")
            .first

        switch languageCode {
        case "zh": return .simplifiedChinese
        case "ja": return .japanese
        default: return .english
        }
    }
}

enum AppText: CaseIterable, Sendable {
    case aboutClassicLaunchpad
    case hideClassicLaunchpad
    case settings
    case quitClassicLaunchpad
    case view
    case showLaunchpad
    case rescanApplications
    case search
    case settingsTitle
    case done
    case runInBackgroundTitle
    case runInBackgroundDetail
    case interceptGestureTitle
    case interceptGestureDetail
    case launchAtLoginTitle
    case launchAtLoginDetail
    case loginItemApproval
    case openSystemSettings
    case loginItemErrorFormat
    case settingsFooter
    case settingsHelp
    case findingApplications
    case noApplicationsFound
    case tryAnotherName
    case open
    case openApplicationFormat
    case pageFormat
}

enum L10n {
    static let language = AppLanguage.resolve(preferredLanguages: Locale.preferredLanguages)

    static func text(_ key: AppText, language: AppLanguage = language) -> String {
        let translations: (english: String, chinese: String, japanese: String) = switch key {
        case .aboutClassicLaunchpad:
            ("About Classic Launchpad", "关于 Classic Launchpad", "Classic Launchpadについて")
        case .hideClassicLaunchpad:
            ("Hide Classic Launchpad", "隐藏 Classic Launchpad", "Classic Launchpadを隠す")
        case .settings:
            ("Settings…", "设置…", "設定…")
        case .quitClassicLaunchpad:
            ("Quit Classic Launchpad", "退出 Classic Launchpad", "Classic Launchpadを終了")
        case .view:
            ("View", "显示", "表示")
        case .showLaunchpad:
            ("Show Launchpad", "显示 Launchpad", "Launchpadを表示")
        case .rescanApplications:
            ("Rescan Applications", "重新扫描应用", "Appを再スキャン")
        case .search:
            ("Search", "搜索", "検索")
        case .settingsTitle:
            ("Classic Launchpad Settings", "Classic Launchpad 设置", "Classic Launchpad設定")
        case .done:
            ("Done", "完成", "完了")
        case .runInBackgroundTitle:
            ("Run in background", "后台运行", "バックグラウンドで実行")
        case .runInBackgroundDetail:
            (
                "When enabled, dismissing keeps gesture control active in the background. When disabled, dismissing quits the app and returns the gesture to macOS.",
                "开启时收起后仍会接管手势；关闭后，收起界面会退出 App 并把手势交还给 macOS。",
                "オンの場合、画面を閉じてもバックグラウンドでジェスチャーの制御を続けます。オフの場合、画面を閉じるとAppを終了し、ジェスチャーをmacOSに戻します。"
            )
        case .interceptGestureTitle:
            ("Intercept four-finger gesture", "接管四指手势", "4本指ジェスチャーを制御")
        case .interceptGestureDetail:
            (
                "When enabled, pinching with your thumb and three fingers opens Classic Launchpad. Disabling this option or quitting the app immediately returns the gesture to macOS.",
                "启用后，拇指与三指捏合会打开 Classic Launchpad；关闭此项或退出 App 时会立即交还给 macOS。",
                "有効にすると、親指と3本の指でピンチしてClassic Launchpadを開けます。この設定を無効にするかAppを終了すると、ジェスチャーはすぐにmacOSへ戻ります。"
            )
        case .launchAtLoginTitle:
            ("Launch at login", "登录时自动启动", "ログイン時に起動")
        case .launchAtLoginDetail:
            (
                "Starts automatically after you log in to macOS, keeping the trackpad gesture ready at any time.",
                "登录 macOS 后自动启动，以便随时使用触控板手势。",
                "macOSへのログイン後に自動起動し、いつでもトラックパッドジェスチャーを使用できるようにします。"
            )
        case .loginItemApproval:
            (
                "macOS requires approval for this item in Login Items & Extensions.",
                "macOS 需要你在“登录项与扩展”中批准此登录项。",
                "macOSの「ログイン項目と機能拡張」で、このログイン項目を許可してください。"
            )
        case .openSystemSettings:
            ("Open System Settings", "打开系统设置", "システム設定を開く")
        case .loginItemErrorFormat:
            ("Unable to change login item: %@", "无法修改登录项：%@", "ログイン項目を変更できません：%@")
        case .settingsFooter:
            (
                "Move the app into the Applications folder before enabling launch at login. Dock briefly reloads on quit to restore the native Apps gesture.",
                "建议先将 App 放入“应用程序”文件夹，再启用自动启动。退出时为恢复系统 Apps 手势，Dock 会短暂重载。",
                "ログイン時の起動を有効にする前に、Appを「アプリケーション」フォルダへ移動してください。終了時にシステムのAppsジェスチャーを復元するため、Dockが一時的に再読み込みされます。"
            )
        case .settingsHelp:
            ("Settings (⌘,)", "设置（⌘,）", "設定（⌘,）")
        case .findingApplications:
            ("Finding applications…", "正在查找应用…", "Appを検索中…")
        case .noApplicationsFound:
            ("No applications found", "没有找到应用", "Appが見つかりません")
        case .tryAnotherName:
            ("Try another name", "试试其他名称", "別の名前を試してください")
        case .open:
            ("Open", "打开", "開く")
        case .openApplicationFormat:
            ("Open %@", "打开 %@", "%@を開く")
        case .pageFormat:
            ("Page %d", "第 %d 页", "%dページ")
        }

        return switch language {
        case .english: translations.english
        case .simplifiedChinese: translations.chinese
        case .japanese: translations.japanese
        }
    }

    static func loginItemError(_ error: String) -> String {
        String(format: text(.loginItemErrorFormat), error)
    }

    static func openApplication(_ name: String) -> String {
        String(format: text(.openApplicationFormat), name)
    }

    static func page(_ number: Int) -> String {
        String(format: text(.pageFormat), number)
    }
}
