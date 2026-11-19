import Foundation
import Testing
@testable import OFFGRID

struct PlaceholderToneGeneratorTests {
    private let generator = PlaceholderToneGenerator(sampleRate: 8_000)

    @Test func producesTheRequestedLength() {
        #expect(generator.samples(toneIndex: 0, duration: 24).count == 24 * 8_000)
    }

    @Test func isDeterministicAndDiffersPerTrack() {
        let a = generator.samples(toneIndex: 3, duration: 20)
        #expect(a == generator.samples(toneIndex: 3, duration: 20))
        #expect(a != generator.samples(toneIndex: 4, duration: 20))
    }

    @Test func fadesAtBothEndsSoLoopsDoNotClick() {
        let samples = generator.samples(toneIndex: 0, duration: 20)
        #expect(samples.first == 0)
        #expect(abs(Int(samples.last!)) <= 1)
    }

    @Test func wavHeaderDescribesSixteenBitMonoPCM() {
        let data = WAVWriter.data(samples: [0, 1, -1, 100], sampleRate: 8_000)
        func u32(_ offset: Int) -> UInt32 { data[offset..<offset + 4].enumerated().reduce(0) { $0 | UInt32($1.element) << (8 * $1.offset) } }
        func u16(_ offset: Int) -> UInt16 { UInt16(data[offset]) | UInt16(data[offset + 1]) << 8 }

        #expect(data.count == 44 + 8)
        #expect(String(decoding: data[0..<4], as: UTF8.self) == "RIFF")
        #expect(String(decoding: data[8..<12], as: UTF8.self) == "WAVE")
        #expect(u16(20) == 1)       // PCM
        #expect(u16(22) == 1)       // mono
        #expect(u32(24) == 8_000)   // sample rate
        #expect(u16(34) == 16)      // bits per sample
        #expect(u32(40) == 8)       // data bytes
    }

    @Test func doesNotOverwriteAnExistingFile() throws {
        let url = FileManager.default.temporaryDirectory
            .appending(path: "tone-\(UUID().uuidString)/mock_001.wav")
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }

        try generator.writeToneIfMissing(toneIndex: 0, duration: 20, to: url)
        let first = try Data(contentsOf: url)
        try generator.writeToneIfMissing(toneIndex: 5, duration: 25, to: url)
        #expect(try Data(contentsOf: url) == first)
    }
}
