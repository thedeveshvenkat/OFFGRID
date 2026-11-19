import Foundation
import Testing
@testable import OFFGRID

struct ProviderSelectionTests {
    @Test func releaseNeverSelectsTheMockProvider() {
        #expect(ProviderSelection.kind(for: .release) == .unconfigured)
        #expect(ProviderSelection.kind(for: .release) != .mock)
    }

    @Test func debugSelectsTheMockProvider() {
        #expect(ProviderSelection.kind(for: .debug) == .mock)
    }

    @Test func releaseEnvironmentServesNothing() async {
        let environment = AppEnvironment.make(configuration: .release)
        #expect(environment.trackProvider is UnconfiguredTrackProvider)
        await #expect(throws: TrackProviderError.notConfigured) {
            try await environment.trackProvider.nextTracks(count: 1)
        }
        await #expect(throws: TrackProviderError.notConfigured) {
            try await environment.trackProvider.playbackSource(for: TrackID("anything"))
        }
    }

    @Test func debugEnvironmentUsesTheMockProvider() {
        let environment = AppEnvironment.make(configuration: .debug)
        #expect(environment.trackProvider is MockTrackProvider)
    }

    @Test func testsRunInDebug() {
        // The suite runs against a Debug build; the Release path is covered by
        // the explicit-configuration tests above and the Release build check.
        #expect(BuildConfiguration.current == .debug)
    }
}
