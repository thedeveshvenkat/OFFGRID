import Foundation

nonisolated enum PlaybackState: Equatable, Sendable {
    case idle
    case loading
    case playing
    case paused
    case failed(String)
}

/// Plays one snippet at a time. The real implementation (looping, fades,
/// background audio, lock-screen controls) arrives in milestone 1A.4; features
/// depend only on this protocol, so the audio source can change freely.
@MainActor
protocol AudioPlayer: AnyObject {
    var state: PlaybackState { get }

    /// Prepares the snippet described by `source`; does not start playback.
    func load(_ source: PlaybackSource) async throws
    func play()
    func pause()
    func stop()
}
