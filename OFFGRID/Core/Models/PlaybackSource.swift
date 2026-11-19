import Foundation

/// Everything the audio player needs to play one track's snippet.
/// Requested just before playback, so providers whose audio links are
/// short-lived can hand out a fresh one each time.
nonisolated struct PlaybackSource: Hashable, Sendable {
    let trackID: TrackID
    /// Local file or remote stream URL for the audio.
    let audioURL: URL
    let snippet: Snippet
}
