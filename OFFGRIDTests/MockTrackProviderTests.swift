import AVFoundation
import Foundation
import Testing
@testable import OFFGRID

struct MockCatalogTests {
    @Test func everyIDHasTheMockPrefixAndIsUnique() {
        let ids = MockCatalog.tracks.map(\.id.rawValue)
        #expect(ids.count == MockCatalog.trackCount)
        #expect(ids.allSatisfy { $0.hasPrefix("mock_") })
        #expect(Set(ids).count == ids.count)
    }

    @Test func tracksAreObviouslyFakeAndCarryNoLinks() {
        for track in MockCatalog.tracks {
            #expect(track.title.hasPrefix("Placeholder Tone"))
            #expect(track.artistName.hasPrefix("Test Signal"))
            #expect(track.artworkURL == nil)
            #expect(track.sourcePageURL == nil)
            #expect(Snippet.allowedDuration.contains(track.snippet.duration))
        }
    }
}

struct MockTrackProviderTests {
    private func makeProvider() -> (MockTrackProvider, URL) {
        let directory = FileManager.default.temporaryDirectory
            .appending(path: "MockTrackProviderTests-\(UUID().uuidString)", directoryHint: .isDirectory)
        return (MockTrackProvider(audioDirectory: directory), directory)
    }

    @Test func returnsBatchesOfTheRequestedSize() async throws {
        let (provider, _) = makeProvider()
        #expect(try await provider.nextTracks(count: 1).count == 1)
        #expect(try await provider.nextTracks(count: 5).count == 5)
    }

    @Test func streamContinuesInOrderAndWrapsAround() async throws {
        let (provider, _) = makeProvider()
        let all = MockCatalog.tracks
        let first = try await provider.nextTracks(count: all.count - 2)
        let second = try await provider.nextTracks(count: 4)
        #expect(first == Array(all.prefix(all.count - 2)))
        #expect(second == Array(all.suffix(2)) + Array(all.prefix(2)))
    }

    @Test(arguments: [0, -3])
    func rejectsNonPositiveCounts(count: Int) async {
        let (provider, _) = makeProvider()
        await #expect(throws: TrackProviderError.invalidRequest) {
            try await provider.nextTracks(count: count)
        }
    }

    @Test func unknownTrackIsReported() async {
        let (provider, _) = makeProvider()
        await #expect(throws: TrackProviderError.trackNotFound(TrackID("mock_999"))) {
            try await provider.playbackSource(for: TrackID("mock_999"))
        }
    }

    @Test func everyTrackResolvesToDecodableAudioInsideItsDirectory() async throws {
        let (provider, directory) = makeProvider()
        defer { try? FileManager.default.removeItem(at: directory) }

        for track in MockCatalog.tracks {
            let source = try await provider.playbackSource(for: track.id)
            #expect(source.trackID == track.id)
            #expect(source.snippet == track.snippet)
            #expect(source.audioURL.isFileURL)
            #expect(source.audioURL.deletingLastPathComponent().standardizedFileURL
                    == directory.standardizedFileURL)

            // AVFoundation can open it, and it is as long as the snippet.
            let file = try AVAudioFile(forReading: source.audioURL)
            let seconds = Double(file.length) / file.fileFormat.sampleRate
            #expect(abs(seconds - track.snippet.duration) < 0.01)
        }
        let written = try FileManager.default.contentsOfDirectory(atPath: directory.path(percentEncoded: false))
        #expect(written.count == MockCatalog.trackCount)
    }
}
