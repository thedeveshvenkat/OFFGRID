#if DEBUG
import Foundation

/// Debug-only track source: cycles through `MockCatalog` forever and serves
/// generated placeholder tones as audio.
actor MockTrackProvider: TrackProvider {
    private let generator: PlaceholderToneGenerator
    private let audioDirectory: URL
    private var cursor = 0

    init(audioDirectory: URL = MockTrackProvider.defaultAudioDirectory,
         generator: PlaceholderToneGenerator = PlaceholderToneGenerator()) {
        self.audioDirectory = audioDirectory
        self.generator = generator
    }

    static var defaultAudioDirectory: URL {
        URL.cachesDirectory.appending(path: "PlaceholderAudio", directoryHint: .isDirectory)
    }

    func nextTracks(count: Int) async throws -> [Track] {
        guard count > 0 else { throw TrackProviderError.invalidRequest }
        let tracks = MockCatalog.tracks
        let batch = (0..<count).map { tracks[(cursor + $0) % tracks.count] }
        cursor = (cursor + count) % tracks.count
        return batch
    }

    func playbackSource(for trackID: TrackID) async throws -> PlaybackSource {
        guard let index = MockCatalog.index(of: trackID) else {
            throw TrackProviderError.trackNotFound(trackID)
        }
        let fileURL = audioDirectory.appending(path: "\(trackID.rawValue).wav")
        try generator.writeToneIfMissing(toneIndex: index,
                                         duration: MockCatalog.snippetDuration,
                                         to: fileURL)
        return PlaybackSource(trackID: trackID,
                              audioURL: fileURL,
                              snippet: MockCatalog.tracks[index].snippet)
    }
}
#endif
