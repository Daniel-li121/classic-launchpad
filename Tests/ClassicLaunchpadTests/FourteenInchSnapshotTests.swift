import AppKit
import SwiftUI
import Testing
@testable import ClassicLaunchpad

@Suite("14-inch MacBook Pro layout")
struct FourteenInchSnapshotTests {
    private let canvasSize = CGSize(width: 1512, height: 982)

    @Test("Adaptive geometry is centered at 1512×982")
    func centeredGeometry() {
        let metrics = GridMetrics(size: canvasSize)
        let contentWidth = canvasSize.width - metrics.horizontalPadding * 2
        let gridWidth = CGFloat(metrics.columnCount) * 122
            + CGFloat(metrics.columnCount - 1) * 8
        let gridInset = (contentWidth - gridWidth) / 2
        let leftEdge = metrics.horizontalPadding + gridInset
        let rightEdge = canvasSize.width - metrics.horizontalPadding - gridInset

        #expect(metrics.columnCount == 9)
        #expect(metrics.rowCount == 5)
        #expect(metrics.pageSize == 45)
        #expect(abs(canvasSize.width / 2 - 756) < 0.001)
        #expect(abs(leftEdge - (canvasSize.width - rightEdge)) < 0.001)
        #expect(gridInset >= 0)
    }

    @Test("Native SwiftUI snapshot renders at exactly 1512×982")
    @MainActor
    func nativeSnapshot() async throws {
        let library = AppLibrary()
        let settings = LaunchpadSettings()

        while library.isLoading {
            try await Task.sleep(for: .milliseconds(25))
        }

        let view = LaunchpadView(extendsIntoSafeArea: false, onDismiss: {})
            .environmentObject(library)
            .environmentObject(settings)
            .frame(width: canvasSize.width, height: canvasSize.height)

        let hostingView = NSHostingView(rootView: view)
        hostingView.frame = NSRect(origin: .zero, size: canvasSize)

        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: canvasSize),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.contentView = hostingView
        window.layoutIfNeeded()
        hostingView.layoutSubtreeIfNeeded()
        hostingView.displayIfNeeded()

        let bitmap = try #require(NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(canvasSize.width),
            pixelsHigh: Int(canvasSize.height),
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ))
        bitmap.size = canvasSize
        hostingView.cacheDisplay(in: hostingView.bounds, to: bitmap)

        #expect(bitmap.pixelsWide == 1512)
        #expect(bitmap.pixelsHigh == 982)

        if let outputPath = ProcessInfo.processInfo.environment["CLASSIC_LAUNCHPAD_SNAPSHOT_PATH"] {
            let png = try #require(bitmap.representation(using: .png, properties: [:]))
            try png.write(to: URL(fileURLWithPath: outputPath), options: .atomic)
        }
    }
}
