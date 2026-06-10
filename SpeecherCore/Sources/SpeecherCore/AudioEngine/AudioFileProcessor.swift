@preconcurrency import AVFoundation
import Foundation

/// Importiert Audiodateien und zerlegt sie in 30-Sekunden-Segmente für den ASR-Service.
public final class AudioFileProcessor: Sendable {
    public static let segmentDuration: TimeInterval = 30.0

    /// Nativ von AVFoundation unterstützte Formate (macOS 14+).
    /// OGG und OPUS erfordern externe Bibliotheken – werden in Phase 2 ergänzt.
    public static let supportedExtensions: Set<String> = [
        "mp3", "m4a", "aac", "wav", "wave",
        "aiff", "aif", "aifc",
        "flac", "caf", "mp4"
    ]

    public init() {}

    /// Verarbeitet eine Audiodatei und liefert Chunks via AsyncStream.
    /// - Parameter url: Pfad zur Audiodatei
    /// - Returns: AsyncStream von AudioChunks
    public func chunks(from url: URL) -> AsyncThrowingStream<AudioChunk, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    try await self.processFile(at: url, continuation: continuation)
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    // MARK: - Private

    private func processFile(
        at url: URL,
        continuation: AsyncThrowingStream<AudioChunk, Error>.Continuation
    ) async throws {
        let ext = url.pathExtension.lowercased()
        guard AudioFileProcessor.supportedExtensions.contains(ext) else {
            throw AudioEngineError.unsupportedFileFormat(ext)
        }

        let audioFile = try AVAudioFile(forReading: url)
        guard let targetFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: 16_000,
            channels: 1,
            interleaved: false
        ) else {
            throw AudioEngineError.formatNotSupported
        }

        guard let converter = AVAudioConverter(from: audioFile.processingFormat, to: targetFormat) else {
            throw AudioEngineError.formatConversionFailed
        }

        let segmentFrames = AVAudioFrameCount(targetFormat.sampleRate * Self.segmentDuration)
        let readBufferSize = AVAudioFrameCount(audioFile.processingFormat.sampleRate * Self.segmentDuration)

        var sequenceNumber = 0
        var offset: AVAudioFramePosition = 0

        while offset < audioFile.length {
            try Task.checkCancellation()

            let framesToRead = AVAudioFrameCount(min(
                Int64(readBufferSize),
                audioFile.length - offset
            ))

            guard let inputBuffer = AVAudioPCMBuffer(
                pcmFormat: audioFile.processingFormat,
                frameCapacity: framesToRead
            ) else { break }

            try audioFile.read(into: inputBuffer, frameCount: framesToRead)

            guard let outputBuffer = AVAudioPCMBuffer(
                pcmFormat: targetFormat,
                frameCapacity: segmentFrames
            ) else { break }

            // AVAudioConverter.convert ruft den Block synchron auf – kein echtes Concurrency-Problem.
            nonisolated(unsafe) var inputConsumed = false
            converter.convert(to: outputBuffer, error: nil) { _, outStatus in
                if inputConsumed {
                    outStatus.pointee = .noDataNow
                    return nil
                }
                outStatus.pointee = .haveData
                inputConsumed = true
                return inputBuffer
            }

            guard outputBuffer.frameLength > 0,
                  let floatData = outputBuffer.floatChannelData else {
                offset += AVAudioFramePosition(framesToRead)
                continue
            }

            let data = Data(
                bytes: floatData[0],
                count: Int(outputBuffer.frameLength) * MemoryLayout<Float>.size
            )
            let duration = Double(outputBuffer.frameLength) / targetFormat.sampleRate

            let chunk = AudioChunk(
                data: data,
                sampleRate: targetFormat.sampleRate,
                channelCount: 1,
                sequenceNumber: sequenceNumber,
                timestamp: Date(),
                duration: duration
            )
            continuation.yield(chunk)

            sequenceNumber += 1
            offset += AVAudioFramePosition(framesToRead)
        }
    }
}
