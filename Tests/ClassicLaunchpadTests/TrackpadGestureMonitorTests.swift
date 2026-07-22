import Testing
@testable import ClassicLaunchpad

@Suite("Trackpad listener activation")
struct TrackpadListenerActivationTests {
    @Test("A false success before the trackpad is ready keeps retrying")
    func retriesUntilListenerExists() {
        var isListening = false
        var attempts = 0

        let firstAttemptIsReady = TrackpadListenerActivation.attempt(
            isListening: { isListening },
            startListening: {
                attempts += 1
                // Simulate OMSManager returning success without installing a
                // listener while macOS is still starting the trackpad service.
            }
        )

        #expect(!firstAttemptIsReady)
        #expect(attempts == 1)

        let secondAttemptIsReady = TrackpadListenerActivation.attempt(
            isListening: { isListening },
            startListening: {
                attempts += 1
                isListening = true
            }
        )

        #expect(secondAttemptIsReady)
        #expect(attempts == 2)
    }

    @Test("An existing listener is not started twice")
    func existingListenerIsKept() {
        var startWasCalled = false

        let isReady = TrackpadListenerActivation.attempt(
            isListening: { true },
            startListening: { startWasCalled = true }
        )

        #expect(isReady)
        #expect(!startWasCalled)
    }
}
