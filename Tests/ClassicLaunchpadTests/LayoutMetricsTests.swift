import CoreGraphics
import Testing
@testable import ClassicLaunchpad

@Suite("Adaptive screen layout")
struct LayoutMetricsTests {
    private struct ScreenCase {
        let name: String
        let size: CGSize
        let columns: Int
        let rows: Int
    }

    private let screens = [
        ScreenCase(name: "Minimum supported window", size: CGSize(width: 760, height: 520), columns: 5, rows: 3),
        ScreenCase(name: "Compact 1024×640", size: CGSize(width: 1024, height: 640), columns: 7, rows: 4),
        ScreenCase(name: "Compact 1024×666", size: CGSize(width: 1024, height: 666), columns: 7, rows: 4),
        ScreenCase(name: "HD 1280×720", size: CGSize(width: 1280, height: 720), columns: 8, rows: 5),
        ScreenCase(name: "13-inch MacBook 1280×800", size: CGSize(width: 1280, height: 800), columns: 8, rows: 5),
        ScreenCase(name: "13-inch MacBook Air 1280×832", size: CGSize(width: 1280, height: 832), columns: 8, rows: 5),
        ScreenCase(name: "1440×900", size: CGSize(width: 1440, height: 900), columns: 9, rows: 5),
        ScreenCase(name: "14-inch MacBook Pro 1512×982", size: CGSize(width: 1512, height: 982), columns: 9, rows: 5),
        ScreenCase(name: "16-inch MacBook Pro 1728×1117", size: CGSize(width: 1728, height: 1117), columns: 9, rows: 5),
        ScreenCase(name: "Full HD 1920×1080", size: CGSize(width: 1920, height: 1080), columns: 9, rows: 5),
        ScreenCase(name: "Current display 2560×1440", size: CGSize(width: 2560, height: 1440), columns: 9, rows: 5),
        ScreenCase(name: "Ultrawide 3440×1440", size: CGSize(width: 3440, height: 1440), columns: 9, rows: 5),
        ScreenCase(name: "4K 3840×2160", size: CGSize(width: 3840, height: 2160), columns: 9, rows: 5),
        ScreenCase(name: "5K 5120×2880", size: CGSize(width: 5120, height: 2880), columns: 9, rows: 5),
        ScreenCase(name: "Portrait display 1080×1920", size: CGSize(width: 1080, height: 1920), columns: 7, rows: 5)
    ]

    @Test("Expected row and column counts across common displays")
    func expectedGridCounts() {
        for screen in screens {
            let metrics = GridMetrics(size: screen.size)
            #expect(metrics.columnCount == screen.columns, Comment(rawValue: screen.name))
            #expect(metrics.rowCount == screen.rows, Comment(rawValue: screen.name))
            #expect(metrics.columns.count == screen.columns, Comment(rawValue: screen.name))
            #expect(metrics.pageSize == screen.columns * screen.rows, Comment(rawValue: screen.name))
        }
    }

    @Test("Content never overflows vertically")
    func verticalFit() {
        for screen in screens {
            let metrics = GridMetrics(size: screen.size)
            let gridHeight = CGFloat(metrics.rowCount) * metrics.tileHeight
                + CGFloat(max(0, metrics.rowCount - 1)) * metrics.rowSpacing
            let occupiedHeight = metrics.topPadding + 46 + gridHeight + 42 + 14

            #expect(occupiedHeight <= screen.size.height, Comment(rawValue: screen.name))
            #expect(metrics.tileHeight >= 106, Comment(rawValue: screen.name))
            #expect(metrics.tileHeight <= 126, Comment(rawValue: screen.name))
            #expect(metrics.rowSpacing >= 4, Comment(rawValue: screen.name))
            #expect(metrics.rowSpacing <= 18, Comment(rawValue: screen.name))
        }
    }

    @Test("Grid remains within supported capacity bounds")
    func capacityBounds() {
        for screen in screens {
            let metrics = GridMetrics(size: screen.size)
            #expect((4...9).contains(metrics.columnCount), Comment(rawValue: screen.name))
            #expect((3...5).contains(metrics.rowCount), Comment(rawValue: screen.name))
            #expect(metrics.pageSize <= 45, Comment(rawValue: screen.name))
        }
    }

    @Test("Minimum-width grid has enough horizontal room")
    func minimumHorizontalFit() {
        for screen in screens {
            let metrics = GridMetrics(size: screen.size)
            let minimumGridWidth = CGFloat(metrics.columnCount) * 122
                + CGFloat(max(0, metrics.columnCount - 1)) * 8
                + metrics.horizontalPadding * 2
            #expect(minimumGridWidth <= screen.size.width, Comment(rawValue: screen.name))
        }
    }
}
