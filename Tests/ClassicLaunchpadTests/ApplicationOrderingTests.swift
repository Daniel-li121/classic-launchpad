import Foundation
import Testing
@testable import ClassicLaunchpad

@Suite("Application ordering")
struct ApplicationOrderingTests {
    private func application(_ name: String) -> InstalledApplication {
        InstalledApplication(
            url: URL(fileURLWithPath: "/Applications/\(name).app"),
            name: name,
            bundleIdentifier: "test.\(name.lowercased())"
        )
    }

    @Test("Dragging forward moves the application to the target position")
    func moveForward() {
        let applications = [application("A"), application("B"), application("C"), application("D")]
        let result = ApplicationOrdering.moving(
            applicationID: applications[0].id,
            to: applications[2].id,
            in: applications
        )

        #expect(result.map(\.name) == ["B", "C", "A", "D"])
    }

    @Test("Dragging backward moves the application to the target position")
    func moveBackward() {
        let applications = [application("A"), application("B"), application("C"), application("D")]
        let result = ApplicationOrdering.moving(
            applicationID: applications[3].id,
            to: applications[1].id,
            in: applications
        )

        #expect(result.map(\.name) == ["A", "D", "B", "C"])
    }

    @Test("Dragging to the next page moves the application to that page's end")
    func moveToNextPage() {
        let applications = ["A", "B", "C", "D", "E", "F", "G", "H"].map(application)
        let result = ApplicationOrdering.moving(
            applicationID: applications[0].id,
            to: applications[7].id,
            in: applications
        )

        #expect(result.map(\.name) == ["B", "C", "D", "E", "F", "G", "H", "A"])
    }

    @Test("Moving to a partially filled second page leaves a gap on the first page")
    func preservePageGap() {
        let original = ["A", "B", "C", "D", "E"].map(application)
        let reordered = ApplicationOrdering.moving(
            applicationID: original[0].id,
            to: original[4].id,
            in: original
        )
        let assignments = [
            original[0].id: 1,
            original[1].id: 0,
            original[2].id: 0,
            original[3].id: 1,
            original[4].id: 1
        ]
        let pages = ApplicationPaging.pages(
            applications: reordered,
            pageSize: 3,
            assignments: assignments
        )

        #expect(pages.map { $0.map(\.name) } == [["B", "C"], ["D", "E", "A"]])
    }

    @Test("Saved order is restored and newly installed apps are appended")
    func restoreSavedOrder() {
        let applications = [application("A"), application("B"), application("C"), application("D")]
        let savedOrder = [applications[2].id, applications[0].id, applications[1].id]
        let result = ApplicationOrdering.applying(savedOrder: savedOrder, to: applications)

        #expect(result.map(\.name) == ["C", "A", "B", "D"])
    }
}
