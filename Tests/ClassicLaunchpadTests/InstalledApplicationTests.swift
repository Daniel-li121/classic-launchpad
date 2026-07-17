import Foundation
import Testing
@testable import ClassicLaunchpad

@Suite("Installed application search")
struct InstalledApplicationTests {
    private let app = InstalledApplication(
        url: URL(fileURLWithPath: "/Applications/Pixelmator Pro.app"),
        name: "Pixelmator Pro",
        bundleIdentifier: "com.pixelmatorteam.pixelmator.x"
    )

    @Test("Empty search includes the application")
    func emptySearch() {
        #expect(app.matches("  "))
    }

    @Test("Search is case insensitive")
    func caseInsensitiveSearch() {
        #expect(app.matches("PIXEL"))
    }

    @Test("Bundle identifier can be searched")
    func bundleSearch() {
        #expect(app.matches("pixelmatorteam"))
    }

    @Test("Unrelated search is excluded")
    func unrelatedSearch() {
        #expect(!app.matches("Safari"))
    }
}

@Suite("Application visibility")
struct ApplicationVisibilityTests {
    @Test("System launchers stay visible even when they are UI elements")
    func systemLaunchersStayVisible() {
        #expect(ApplicationVisibility.shouldInclude(
            displayName: "Apps",
            bundleIdentifier: "com.apple.apps.launcher",
            isBackgroundOnly: false
        ))
        #expect(ApplicationVisibility.shouldInclude(
            displayName: "Mission Control",
            bundleIdentifier: "com.apple.exposelauncher",
            isBackgroundOnly: false
        ))
    }

    @Test("Named menu-bar applications stay visible")
    func namedBackgroundAppsStayVisible() {
        #expect(ApplicationVisibility.shouldInclude(
            displayName: "OneDrive",
            bundleIdentifier: "com.microsoft.OneDrive",
            isBackgroundOnly: true
        ))
    }

    @Test("Clear technical components are hidden")
    func technicalComponentsAreHidden() {
        #expect(!ApplicationVisibility.shouldInclude(
            displayName: "Microsoft Defender Shim",
            bundleIdentifier: "com.microsoft.wdav.shim",
            isBackgroundOnly: true
        ))
        #expect(!ApplicationVisibility.shouldInclude(
            displayName: "Example Helper",
            bundleIdentifier: "com.example.product.helper",
            isBackgroundOnly: false
        ))
        #expect(!ApplicationVisibility.shouldInclude(
            displayName: "Example Updater",
            bundleIdentifier: "com.example.product.updater",
            isBackgroundOnly: false
        ))
    }

    @Test("Metadata flags accept plist booleans, numbers, and strings")
    func metadataFlagRepresentations() {
        #expect(ApplicationVisibility.metadataFlag(true))
        #expect(ApplicationVisibility.metadataFlag(NSNumber(value: 1)))
        #expect(ApplicationVisibility.metadataFlag("1"))
        #expect(ApplicationVisibility.metadataFlag("TRUE"))
        #expect(ApplicationVisibility.metadataFlag("yes"))
        #expect(!ApplicationVisibility.metadataFlag(false))
        #expect(!ApplicationVisibility.metadataFlag(NSNumber(value: 0)))
        #expect(!ApplicationVisibility.metadataFlag("0"))
        #expect(!ApplicationVisibility.metadataFlag(nil))
    }
}

@Suite("Four-finger pinch recognition")
struct FourFingerPinchDetectorTests {
    @Test("Four fingers moving inward trigger Launchpad")
    func pinchIn() {
        var detector = FourFingerPinchDetector()
        #expect(detector.process(points: square(radius: 0.28), timestamp: 1) == nil)
        #expect(detector.process(points: square(radius: 0.20), timestamp: 1.1) == .pinchIn)
    }

    @Test("Four fingers moving outward close Launchpad")
    func pinchOut() {
        var detector = FourFingerPinchDetector()
        #expect(detector.process(points: square(radius: 0.12), timestamp: 1) == nil)
        #expect(detector.process(points: square(radius: 0.17), timestamp: 1.1) == .pinchOut)
    }

    @Test("Fingers landing one by one still recognize the first pinch")
    func incrementalFirstPinch() {
        var detector = FourFingerPinchDetector()
        let spread = square(radius: 0.27)
        #expect(detector.process(points: Array(spread.prefix(2)), timestamp: 1) == nil)
        #expect(detector.process(points: Array(spread.prefix(3)), timestamp: 1.02) == nil)
        #expect(detector.process(points: spread, timestamp: 1.04) == nil)
        #expect(detector.process(points: square(radius: 0.20), timestamp: 1.12) == .pinchIn)
    }

    @Test("Horizontal four-finger swipe is ignored")
    func horizontalSwipe() {
        var detector = FourFingerPinchDetector()
        let initial = square(radius: 0.24)
        let shifted = initial.map { CGPoint(x: $0.x + 0.2, y: $0.y) }
        #expect(detector.process(points: initial, timestamp: 1) == nil)
        #expect(detector.process(points: shifted, timestamp: 1.1) == nil)
    }

    @Test("Two-finger zoom is ignored")
    func twoFingerZoom() {
        var detector = FourFingerPinchDetector()
        #expect(detector.process(
            points: [CGPoint(x: 0.1, y: 0.5), CGPoint(x: 0.9, y: 0.5)],
            timestamp: 1
        ) == nil)
        #expect(detector.process(
            points: [CGPoint(x: 0.4, y: 0.5), CGPoint(x: 0.6, y: 0.5)],
            timestamp: 1.1
        ) == nil)
    }

    private func square(radius: CGFloat) -> [CGPoint] {
        [
            CGPoint(x: 0.5 - radius, y: 0.5 - radius),
            CGPoint(x: 0.5 + radius, y: 0.5 - radius),
            CGPoint(x: 0.5 - radius, y: 0.5 + radius),
            CGPoint(x: 0.5 + radius, y: 0.5 + radius)
        ]
    }
}

@Suite("Two-finger horizontal page swipe")
struct HorizontalPageSwipeDetectorTests {
    @Test("Swipe left advances one page")
    func nextPage() {
        var detector = HorizontalPageSwipeDetector()
        detector.begin()
        #expect(detector.process(deltaX: -20, deltaY: 2) == nil)
        #expect(detector.process(deltaX: -24, deltaY: 1) == .next)
        #expect(detector.process(deltaX: -80, deltaY: 0) == nil)
    }

    @Test("Swipe right returns one page")
    func previousPage() {
        var detector = HorizontalPageSwipeDetector()
        detector.begin()
        #expect(detector.process(deltaX: 46, deltaY: 4) == .previous)
    }

    @Test("Vertical and diagonal scrolling is ignored")
    func verticalScroll() {
        var detector = HorizontalPageSwipeDetector()
        detector.begin()
        #expect(detector.process(deltaX: 30, deltaY: 50) == nil)
        #expect(detector.process(deltaX: 20, deltaY: 30) == nil)
    }
}
