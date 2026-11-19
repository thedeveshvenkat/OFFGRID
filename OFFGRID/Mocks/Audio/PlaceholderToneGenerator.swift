#if DEBUG
import Foundation

/// Temporary test audio: one plain sine tone per mock track, generated at
/// runtime (mock-data-policy rule 3). Not meant to sound like music.
nonisolated struct PlaceholderToneGenerator: Sendable {
    let sampleRate: Int
    /// Short fade at each end so the tone starts and stops without a click.
    let edgeFade: TimeInterval

    init(sampleRate: Int = 22_050, edgeFade: TimeInterval = 0.05) {
        self.sampleRate = sampleRate
        self.edgeFade = edgeFade
    }

    /// Tone pitch for a track: a whole step apart per index, starting at A3.
    func frequency(forToneIndex index: Int) -> Double {
        220 * pow(2, Double(index % 12) * 2 / 12)
    }

    func samples(toneIndex: Int, duration: TimeInterval) -> [Int16] {
        let count = Int(duration * Double(sampleRate))
        let fadeCount = max(1, Int(edgeFade * Double(sampleRate)))
        let step = 2 * Double.pi * frequency(forToneIndex: toneIndex) / Double(sampleRate)
        let amplitude = 0.25 * Double(Int16.max)
        return (0..<count).map { i in
            let fade = min(1, Double(min(i, count - 1 - i)) / Double(fadeCount))
            return Int16(sin(Double(i) * step) * amplitude * fade)
        }
    }

    /// Writes the tone as a WAV file unless one already exists at `url`.
    func writeToneIfMissing(toneIndex: Int, duration: TimeInterval, to url: URL) throws {
        let fileManager = FileManager.default
        guard !fileManager.fileExists(atPath: url.path(percentEncoded: false)) else { return }
        try fileManager.createDirectory(at: url.deletingLastPathComponent(),
                                        withIntermediateDirectories: true)
        let data = WAVWriter.data(samples: samples(toneIndex: toneIndex, duration: duration),
                                  sampleRate: sampleRate)
        try data.write(to: url, options: .atomic)
    }
}
#endif
