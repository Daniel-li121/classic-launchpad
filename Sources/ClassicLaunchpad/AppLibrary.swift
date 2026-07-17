import AppKit
import Foundation

struct InstalledApplication: Identifiable, Hashable, Sendable {
    let url: URL
    let name: String
    let bundleIdentifier: String?

    var id: String {
        bundleIdentifier ?? url.standardizedFileURL.path
    }

    func matches(_ query: String) -> Bool {
        let normalized = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return true }
        return name.localizedCaseInsensitiveContains(normalized)
            || bundleIdentifier?.localizedCaseInsensitiveContains(normalized) == true
    }
}

enum ApplicationVisibility {
    private static let technicalComponents: Set<String> = [
        "helper", "shim", "updater", "autoupdate", "autoupdater",
        "agent", "daemon", "service", "xpc", "crashpad", "crashreporter",
        "loginitem"
    ]

    static func shouldInclude(
        displayName: String,
        bundleIdentifier: String?,
        isBackgroundOnly: Bool
    ) -> Bool {
        let nameComponents = words(in: displayName)
        let identifierComponents = words(in: bundleIdentifier ?? "")
        let hasTechnicalIdentity = !nameComponents.isDisjoint(with: technicalComponents)
            || !identifierComponents.isDisjoint(with: technicalComponents)

        if hasTechnicalIdentity { return false }
        if isBackgroundOnly && displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return false
        }
        return true
    }

    static func metadataFlag(_ value: Any?) -> Bool {
        if let value = value as? Bool { return value }
        if let value = value as? NSNumber { return value.boolValue }
        if let value = value as? String {
            return ["1", "true", "yes"].contains(value.lowercased())
        }
        return false
    }

    private static func words(in value: String) -> Set<String> {
        Set(
            value.lowercased()
                .components(separatedBy: CharacterSet.alphanumerics.inverted)
                .filter { !$0.isEmpty }
        )
    }
}

enum ApplicationOrdering {
    static func moving(
        applicationID: String,
        to targetID: String,
        in applications: [InstalledApplication]
    ) -> [InstalledApplication] {
        guard applicationID != targetID,
              let sourceIndex = applications.firstIndex(where: { $0.id == applicationID }),
              let targetIndex = applications.firstIndex(where: { $0.id == targetID }) else {
            return applications
        }

        var reordered = applications
        let application = reordered.remove(at: sourceIndex)
        reordered.insert(application, at: min(targetIndex, reordered.endIndex))
        return reordered
    }

    static func applying(
        savedOrder: [String],
        to applications: [InstalledApplication]
    ) -> [InstalledApplication] {
        guard !savedOrder.isEmpty else { return applications }

        let rank = Dictionary(uniqueKeysWithValues: savedOrder.enumerated().map { ($0.element, $0.offset) })
        return applications.sorted { lhs, rhs in
            switch (rank[lhs.id], rank[rhs.id]) {
            case let (.some(lhsRank), .some(rhsRank)):
                return lhsRank < rhsRank
            case (.some, .none):
                return true
            case (.none, .some):
                return false
            case (.none, .none):
                return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
            }
        }
    }
}

enum ApplicationPaging {
    static func pages(
        applications: [InstalledApplication],
        pageSize: Int,
        assignments: [String: Int]
    ) -> [[InstalledApplication]] {
        let pageSize = max(1, pageSize)
        guard !applications.isEmpty else { return [] }

        if assignments.isEmpty {
            return stride(from: 0, to: applications.count, by: pageSize).map { start in
                Array(applications[start..<min(start + pageSize, applications.count)])
            }
        }

        var pages: [[InstalledApplication]] = []
        for (index, application) in applications.enumerated() {
            var destination = max(0, assignments[application.id] ?? (index / pageSize))
            while pages.count <= destination {
                pages.append([])
            }
            while pages[destination].count >= pageSize {
                destination += 1
                while pages.count <= destination {
                    pages.append([])
                }
            }
            pages[destination].append(application)
        }

        return pages.filter { !$0.isEmpty }
    }

    static func assignments(for pages: [[InstalledApplication]]) -> [String: Int] {
        Dictionary(
            uniqueKeysWithValues: pages.enumerated().flatMap { page, applications in
                applications.map { ($0.id, page) }
            }
        )
    }
}

@MainActor
final class AppLibrary: ObservableObject {
    @Published private(set) var applications: [InstalledApplication] = []
    @Published private(set) var isLoading = false

    private let applicationOrderKey = "applicationOrder.v1"
    private let applicationPagesKey = "applicationPages.v1"
    private var applicationPageAssignments: [String: Int]
    private var refreshTask: Task<Void, Never>?
    private var lastRefreshDate: Date?

    init() {
        applicationPageAssignments = UserDefaults.standard.dictionary(forKey: applicationPagesKey)?
            .compactMapValues { value in
                if let number = value as? NSNumber { return number.intValue }
                return value as? Int
            } ?? [:]
        refresh()
    }

    func refresh() {
        refreshTask?.cancel()
        isLoading = true

        refreshTask = Task {
            let scannedApplications = await Task.detached(priority: .userInitiated) {
                Self.scanApplications()
            }.value

            guard !Task.isCancelled else { return }
            let applications = self.applyingSavedOrder(to: scannedApplications)
            if self.applications != applications {
                self.applications = applications
            }
            self.lastRefreshDate = Date()
            self.isLoading = false
            ApplicationIconStore.shared.prewarm(applications)
        }
    }

    func refreshIfNeeded(maximumAge: TimeInterval = 60) {
        guard !isLoading else { return }
        guard let lastRefreshDate else {
            refresh()
            return
        }
        if Date().timeIntervalSince(lastRefreshDate) >= maximumAge {
            refresh()
        }
    }

    func open(_ application: InstalledApplication) {
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        NSWorkspace.shared.openApplication(at: application.url, configuration: configuration) { _, error in
            if let error {
                NSLog("Unable to open %@: %@", application.name, error.localizedDescription)
                return
            }
            Task { @MainActor in
                NotificationCenter.default.post(name: .launchpadDidOpenApplication, object: nil)
            }
        }
    }

    func applicationPages(pageSize: Int) -> [[InstalledApplication]] {
        resolvedApplicationPages(pageSize: pageSize)
    }

    func moveApplication(
        id: String,
        to targetID: String,
        destinationPage: Int,
        pageSize: Int
    ) {
        freezePageAssignments(pageSize: pageSize)
        let reordered = ApplicationOrdering.moving(
            applicationID: id,
            to: targetID,
            in: applications
        )
        let normalizedDestinationPage = max(0, destinationPage)
        let pageChanged = applicationPageAssignments[id] != normalizedDestinationPage
        guard reordered != applications || pageChanged else { return }
        applications = reordered
        applicationPageAssignments[id] = normalizedDestinationPage
        freezePageAssignments(pageSize: pageSize)
        UserDefaults.standard.set(reordered.map(\.id), forKey: applicationOrderKey)
        UserDefaults.standard.set(applicationPageAssignments, forKey: applicationPagesKey)
    }

    private func resolvedApplicationPages(pageSize: Int) -> [[InstalledApplication]] {
        ApplicationPaging.pages(
            applications: applications,
            pageSize: pageSize,
            assignments: applicationPageAssignments
        )
    }

    private func freezePageAssignments(pageSize: Int) {
        let pages = resolvedApplicationPages(pageSize: pageSize)
        applicationPageAssignments = ApplicationPaging.assignments(for: pages)
    }

    private func applyingSavedOrder(to applications: [InstalledApplication]) -> [InstalledApplication] {
        let savedOrder = UserDefaults.standard.stringArray(forKey: applicationOrderKey) ?? []
        return ApplicationOrdering.applying(savedOrder: savedOrder, to: applications)
    }

    nonisolated private static func scanApplications() -> [InstalledApplication] {
        let fileManager = FileManager.default
        let home = fileManager.homeDirectoryForCurrentUser
        let roots = [
            URL(fileURLWithPath: "/Applications", isDirectory: true),
            URL(fileURLWithPath: "/System/Applications", isDirectory: true),
            home.appendingPathComponent("Applications", isDirectory: true)
        ]

        let keys: [URLResourceKey] = [.isDirectoryKey, .isPackageKey, .isHiddenKey, .nameKey]
        var found: [String: InstalledApplication] = [:]

        for root in roots where fileManager.fileExists(atPath: root.path) {
            guard let enumerator = fileManager.enumerator(
                at: root,
                includingPropertiesForKeys: keys,
                options: [.skipsHiddenFiles, .skipsPackageDescendants],
                errorHandler: { _, _ in true }
            ) else { continue }

            for case let url as URL in enumerator {
                guard url.pathExtension.caseInsensitiveCompare("app") == .orderedSame else { continue }

                let bundle = Bundle(url: url)
                let displayName = (bundle?.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String)
                    ?? (bundle?.object(forInfoDictionaryKey: "CFBundleName") as? String)
                    ?? url.deletingPathExtension().lastPathComponent
                let bundleIdentifier = bundle?.bundleIdentifier
                guard bundleShouldBeDisplayed(
                    bundle,
                    displayName: displayName,
                    bundleIdentifier: bundleIdentifier
                ) else { continue }
                let item = InstalledApplication(url: url, name: displayName, bundleIdentifier: bundleIdentifier)

                let key = bundleIdentifier ?? url.standardizedFileURL.path
                if let existing = found[key] {
                    if preferredLocation(url.path, over: existing.url.path) {
                        found[key] = item
                    }
                } else {
                    found[key] = item
                }
            }
        }

        return found.values.sorted {
            $0.name.localizedStandardCompare($1.name) == .orderedAscending
        }
    }

    nonisolated private static func bundleShouldBeDisplayed(
        _ bundle: Bundle?,
        displayName: String,
        bundleIdentifier: String?
    ) -> Bool {
        guard let info = bundle?.infoDictionary else { return true }
        return ApplicationVisibility.shouldInclude(
            displayName: displayName,
            bundleIdentifier: bundleIdentifier,
            isBackgroundOnly: ApplicationVisibility.metadataFlag(info["LSBackgroundOnly"])
        )
    }

    nonisolated private static func preferredLocation(_ candidate: String, over existing: String) -> Bool {
        func rank(_ path: String) -> Int {
            if path.hasPrefix("/Applications/") { return 0 }
            if path.contains("/Applications/") { return 1 }
            if path.hasPrefix("/System/Applications/") { return 2 }
            return 3
        }
        return rank(candidate) < rank(existing)
    }
}

@MainActor
final class ApplicationIconStore {
    static let shared = ApplicationIconStore()
    private let cache = NSCache<NSString, NSImage>()
    private var prewarmTask: Task<Void, Never>?

    func icon(for application: InstalledApplication) -> NSImage {
        let key = application.url.path as NSString
        if let cached = cache.object(forKey: key) {
            return cached
        }

        let icon = NSWorkspace.shared.icon(forFile: application.url.path)
        icon.size = NSSize(width: 128, height: 128)
        cache.setObject(icon, forKey: key)
        return icon
    }

    func prewarm(_ applications: [InstalledApplication]) {
        prewarmTask?.cancel()
        prewarmTask = Task { [weak self] in
            guard let self else { return }
            for (index, application) in applications.enumerated() {
                guard !Task.isCancelled else { return }
                _ = self.icon(for: application)
                if index.isMultiple(of: 6) {
                    await Task.yield()
                }
            }
        }
    }
}
