#if DEBUG
import Foundation

/// Minimal encoder for 16-bit mono PCM WAV files.
nonisolated enum WAVWriter {
    static func data(samples: [Int16], sampleRate: Int) -> Data {
        let bytesPerSample = 2
        let dataSize = samples.count * bytesPerSample
        var data = Data(capacity: 44 + dataSize)

        func append(_ string: String) { data.append(contentsOf: Array(string.utf8)) }
        func append32(_ value: UInt32) { withUnsafeBytes(of: value.littleEndian) { data.append(contentsOf: $0) } }
        func append16(_ value: UInt16) { withUnsafeBytes(of: value.littleEndian) { data.append(contentsOf: $0) } }

        append("RIFF")
        append32(UInt32(36 + dataSize))
        append("WAVE")
        append("fmt ")
        append32(16)                                        // fmt chunk size
        append16(1)                                         // PCM
        append16(1)                                         // mono
        append32(UInt32(sampleRate))
        append32(UInt32(sampleRate * bytesPerSample))       // byte rate
        append16(UInt16(bytesPerSample))                    // block align
        append16(16)                                        // bits per sample
        append("data")
        append32(UInt32(dataSize))
        for sample in samples { append16(UInt16(bitPattern: sample)) }
        return data
    }
}
#endif
