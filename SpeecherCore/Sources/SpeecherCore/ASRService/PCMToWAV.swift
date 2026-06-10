import Foundation

/// Wandelt rohe Float32-PCM-Daten (16 kHz, Mono) in eine WAV-Datei (Int16 PCM) um.
/// WAV ist das universell akzeptierte Format für die Whisper API.
enum PCMToWAV {
    static func convert(pcmData: Data, sampleRate: Int = 16_000, channels: Int = 1) -> Data {
        let floatCount = pcmData.count / MemoryLayout<Float>.size
        var int16Samples = [Int16](repeating: 0, count: floatCount)

        pcmData.withUnsafeBytes { raw in
            let floats = raw.bindMemory(to: Float.self)
            for i in 0..<floatCount {
                let clamped = max(-1.0, min(1.0, floats[i]))
                int16Samples[i] = Int16(clamped * 32_767)
            }
        }

        let dataSize = int16Samples.count * MemoryLayout<Int16>.size
        let byteRate = sampleRate * channels * 2     // 16-bit → 2 Bytes
        let blockAlign = channels * 2

        var wav = Data()
        wav.reserveCapacity(44 + dataSize)

        // RIFF Header
        wav += "RIFF".data(using: .ascii)!
        wav.appendLE(UInt32(36 + dataSize))
        wav += "WAVE".data(using: .ascii)!

        // fmt  Subchunk
        wav += "fmt ".data(using: .ascii)!
        wav.appendLE(UInt32(16))              // Subchunk size
        wav.appendLE(UInt16(1))               // PCM = 1
        wav.appendLE(UInt16(channels))
        wav.appendLE(UInt32(sampleRate))
        wav.appendLE(UInt32(byteRate))
        wav.appendLE(UInt16(blockAlign))
        wav.appendLE(UInt16(16))              // BitsPerSample

        // data Subchunk
        wav += "data".data(using: .ascii)!
        wav.appendLE(UInt32(dataSize))

        int16Samples.withUnsafeBytes { wav += $0 }

        return wav
    }
}

private extension Data {
    mutating func appendLE<T: FixedWidthInteger>(_ value: T) {
        var le = value.littleEndian
        self += Swift.withUnsafeBytes(of: &le) { Data($0) }
    }
}
