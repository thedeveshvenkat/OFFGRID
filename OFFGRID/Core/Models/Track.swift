import Foundation

/// Opaque identifier for a track. Core code never parses or interprets it;
/// only the provider that issued it knows its format.
nonisolated struct TrackID: Hashable, Codable, Sendable, CustomStringConvertible {
    let rawValue: String

    init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    var description: String { rawValue }
}

/// The excerpt of a track that OFFGRID plays (PB-01: 20–30 seconds).
nonisolated struct Snippet: Hashable, Codable, Sendable {
    /// Allowed snippet length in seconds (PB-01).
    static let allowedDuration: ClosedRange<TimeInterval> = 20...30

    enum ValidationError: Error, Equatable {
        case negativeStart
        case durationOutOfRange(TimeInterval)
    }

    /// Offset into the track where the snippet begins, in seconds.
    let start: TimeInterval
    /// Snippet length in seconds.
    let duration: TimeInterval

    init(start: TimeInterval, duration: TimeInterval) throws {
        guard start >= 0, start.isFinite else { throw ValidationError.negativeStart }
        guard duration.isFinite, Self.allowedDuration.contains(duration) else {
            throw ValidationError.durationOutOfRange(duration)
        }
        self.start = start
        self.duration = duration
    }

    var end: TimeInterval { start + duration }

    private enum CodingKeys: String, CodingKey { case start, duration }

    /// Decoding goes through the same validation as `init(start:duration:)`.
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            start: container.decode(TimeInterval.self, forKey: .start),
            duration: container.decode(TimeInterval.self, forKey: .duration)
        )
    }
}

/// Provider-neutral description of a track. Contains no provider-specific
/// fields; audio is resolved separately through `TrackProvider.playbackSource(for:)`.
nonisolated struct Track: Identifiable, Hashable, Codable, Sendable {
    let id: TrackID
    let title: String
    let artistName: String
    let snippet: Snippet
    /// Artwork image, if the provider has one. The UI falls back to a
    /// generated look when this is nil.
    let artworkURL: URL?
    /// Page where the full song can be heard at its source, where permitted.
    let sourcePageURL: URL?
}
