import CoreGraphics
import Foundation
import OpenMultitouchSupport

enum TrackpadGestureAction: Equatable, Sendable {
    case pinchIn
    case pinchOut
}

enum TrackpadListenerActivation {
    static func attempt(
        isListening: () -> Bool,
        startListening: () -> Void
    ) -> Bool {
        guard !isListening() else { return true }
        startListening()
        return isListening()
    }
}

/// Recognizes the old Launchpad gesture from four raw trackpad touch points.
/// A radial measurement avoids confusing horizontal four-finger Space swipes
/// with a pinch.
struct FourFingerPinchDetector: Sendable {
    private var largestSpread: CGFloat?
    private var smallestSpread: CGFloat?
    private var triggered = false
    private var lastTriggerTime: TimeInterval = 0

    private let inwardRatio: CGFloat = 0.78
    private let outwardRatio: CGFloat = 1.28
    private let minimumTravel: CGFloat = 0.035
    private let cooldown: TimeInterval = 0.65

    mutating func process(
        points: [CGPoint],
        timestamp: TimeInterval = ProcessInfo.processInfo.systemUptime
    ) -> TrackpadGestureAction? {
        guard points.count >= 4 else {
            resetSequence()
            return nil
        }

        let spread = radialSpread(of: points)
        largestSpread = max(largestSpread ?? spread, spread)
        smallestSpread = min(smallestSpread ?? spread, spread)

        guard !triggered, timestamp - lastTriggerTime >= cooldown,
              let largestSpread, let smallestSpread else { return nil }

        if largestSpread - spread >= minimumTravel,
           spread <= largestSpread * inwardRatio {
            return trigger(.pinchIn, at: timestamp)
        }

        if spread - smallestSpread >= minimumTravel,
           spread >= smallestSpread * outwardRatio {
            return trigger(.pinchOut, at: timestamp)
        }

        return nil
    }

    private func radialSpread(of points: [CGPoint]) -> CGFloat {
        let centroid = CGPoint(
            x: points.reduce(0) { $0 + $1.x } / CGFloat(points.count),
            y: points.reduce(0) { $0 + $1.y } / CGFloat(points.count)
        )

        return points.reduce(0) { result, point in
            let dx = point.x - centroid.x
            let dy = point.y - centroid.y
            return result + sqrt(dx * dx + dy * dy)
        } / CGFloat(points.count)
    }

    private mutating func trigger(
        _ action: TrackpadGestureAction,
        at timestamp: TimeInterval
    ) -> TrackpadGestureAction {
        triggered = true
        lastTriggerTime = timestamp
        return action
    }

    private mutating func resetSequence() {
        largestSpread = nil
        smallestSpread = nil
        triggered = false
    }
}

@MainActor
final class TrackpadGestureMonitor {
    private let manager = OMSManager.shared
    private var activationTask: Task<Void, Never>?
    private var streamTask: Task<Void, Never>?
    private var sessionID: UUID?

    func start(handler: @escaping @MainActor @Sendable (TrackpadGestureAction) -> Void) {
        stop()
        let sessionID = UUID()
        self.sessionID = sessionID
        let ready = AsyncStream<Void>.makeStream()

        streamTask = Task.detached(priority: .userInitiated) { [manager] in
            var detector = FourFingerPinchDetector()
            let stream = manager.touchDataStream
            var iterator = stream.makeAsyncIterator()

            // Signal only after the stream subscription exists, preventing the
            // first gesture from arriving before the consumer is ready.
            ready.continuation.yield()
            ready.continuation.finish()

            while let touchData = try? await iterator.next() {
                guard !Task.isCancelled else { return }

                let activePoints = touchData.compactMap { touch -> CGPoint? in
                    switch touch.state {
                    case .starting, .making, .touching:
                        return CGPoint(
                            x: CGFloat(touch.position.x),
                            y: CGFloat(touch.position.y)
                        )
                    default:
                        return nil
                    }
                }

                if let action = detector.process(points: activePoints) {
                    await handler(action)
                }
            }
        }

        // OMS starts and stops its hardware device through the main queue.
        // Keeping activation on MainActor serializes it with stop(), so a
        // cancelled startup can never re-enable listening after App exit.
        activationTask = Task { [weak self, manager] in
            for await _ in ready.stream { break }
            guard let self,
                  self.sessionID == sessionID,
                  !Task.isCancelled else { return }

            var failedAttempts = 0
            while self.sessionID == sessionID, !Task.isCancelled {
                // OMSManager.startListening() can report success during login
                // before macOS has made the trackpad available, even though no
                // listener was installed. Verify the real state and keep
                // retrying until the listener actually exists.
                if TrackpadListenerActivation.attempt(
                    isListening: { manager.isListening },
                    startListening: { _ = manager.startListening() }
                ) {
                    return
                }
                failedAttempts += 1
                let retryDelay: Duration = failedAttempts <= 40
                    ? .milliseconds(250)
                    : .seconds(1)
                try? await Task.sleep(for: retryDelay)
            }
        }
    }

    func stop() {
        sessionID = nil
        activationTask?.cancel()
        activationTask = nil
        streamTask?.cancel()
        streamTask = nil
        if manager.isListening {
            _ = manager.stopListening()
        }
    }
}
