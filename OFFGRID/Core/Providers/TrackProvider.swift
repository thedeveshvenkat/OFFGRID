import Foundation

nonisolated enum TrackProviderError: Error, Equatable {
    /// No track source is configured for this build.
    case notConfigured
    /// The provider does not know this track.
    case trackNotFound(TrackID)
    /// The request itself was invalid (for example, a non-positive count).
    case invalidRequest
}

/// Source of tracks for the feed and games. Core code depends only on this
/// protocol; each source (mock now, a backend later) is one implementation.
nonisolated protocol TrackProvider: Sendable {
    /// The next `count` tracks of the listener's stream. The stream is
    /// infinite (FY-06), so callers can keep asking.
    func nextTracks(count: Int) async throws -> [Track]

    /// Audio for one track, requested just before it plays.
    func playbackSource(for trackID: TrackID) async throws -> PlaybackSource
}
