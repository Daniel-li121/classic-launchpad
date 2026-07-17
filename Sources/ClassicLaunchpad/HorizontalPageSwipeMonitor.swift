import AppKit

enum HorizontalPageSwipe: Int, Equatable, Sendable {
    case previous = -1
    case next = 1
}

struct HorizontalPageSwipeDetector: Sendable {
    private var accumulatedX: CGFloat = 0
    private var accumulatedY: CGFloat = 0
    private var triggered = false

    private let triggerDistance: CGFloat = 42
    private let horizontalDominance: CGFloat = 1.35

    mutating func begin() {
        accumulatedX = 0
        accumulatedY = 0
        triggered = false
    }

    mutating func process(deltaX: CGFloat, deltaY: CGFloat) -> HorizontalPageSwipe? {
        guard !triggered else { return nil }

        accumulatedX += deltaX
        accumulatedY += deltaY

        let horizontalDistance = abs(accumulatedX)
        let verticalDistance = abs(accumulatedY)
        guard horizontalDistance >= triggerDistance,
              horizontalDistance >= verticalDistance * horizontalDominance else {
            return nil
        }

        triggered = true
        // AppKit's precise scrolling delta describes content movement, which
        // is opposite to the physical two-finger movement used for paging.
        return accumulatedX > 0 ? .previous : .next
    }
}

@MainActor
final class HorizontalPageSwipeMonitor {
    private var eventMonitor: Any?
    private var detector = HorizontalPageSwipeDetector()

    func start() {
        stop()
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { [weak self] event in
            self?.process(event)
            return event
        }
    }

    func stop() {
        if let eventMonitor {
            NSEvent.removeMonitor(eventMonitor)
            self.eventMonitor = nil
        }
    }

    private func process(_ event: NSEvent) {
        guard event.hasPreciseScrollingDeltas,
              event.momentumPhase.isEmpty else { return }

        if event.phase.contains(.began) {
            detector.begin()
        }

        guard event.phase.contains(.began) || event.phase.contains(.changed) else { return }

        if let swipe = detector.process(
            deltaX: event.scrollingDeltaX,
            deltaY: event.scrollingDeltaY
        ) {
            NotificationCenter.default.post(name: .launchpadPageSwipe, object: swipe)
        }
    }
}

extension Notification.Name {
    static let launchpadPageSwipe = Notification.Name("ClassicLaunchpad.pageSwipe")
}
