#if DEBUG
import Foundation

/// Obviously fake demo tracks (mock-data-policy rule 2): `mock_` IDs,
/// invented names, no artwork, no links, no real artists.
nonisolated enum MockCatalog {
    static let idPrefix = "mock_"
    static let trackCount = 12
    static let snippetDuration: TimeInterval = 24

    private static let artists = ["Test Signal A", "Test Signal B", "Test Signal C", "Test Signal D"]

    static let tracks: [Track] = (0..<trackCount).map { index in
        Track(
            id: id(forIndex: index),
            title: String(format: "Placeholder Tone %02d", index + 1),
            artistName: artists[index % artists.count],
            // 24 s is inside the 20–30 s range, so this cannot fail.
            snippet: try! Snippet(start: 0, duration: snippetDuration),
            artworkURL: nil,
            sourcePageURL: nil
        )
    }

    static func id(forIndex index: Int) -> TrackID {
        TrackID(String(format: "\(idPrefix)%03d", index + 1))
    }

    static func index(of id: TrackID) -> Int? {
        tracks.firstIndex { $0.id == id }
    }
}
#endif
