import Foundation

/// The provider Release builds get until a real backend exists (milestone 1E).
/// It serves nothing, so a Release build can never show mock content.
nonisolated struct UnconfiguredTrackProvider: TrackProvider {
    func nextTracks(count: Int) async throws -> [Track] {
        throw TrackProviderError.notConfigured
    }

    func playbackSource(for trackID: TrackID) async throws -> PlaybackSource {
        throw TrackProviderError.notConfigured
    }
}
