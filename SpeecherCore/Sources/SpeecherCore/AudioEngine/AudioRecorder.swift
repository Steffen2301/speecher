@preconcurrency import AVFoundation
import Foundation

/// Nimmt Live-Audio vom Mikrofon auf und liefert es als 5-Sekunden-Chunks.
@MainActor
public final class AudioRecorder: ObservableObject {
    @Published public private(set) var isRecording = false
    /// Eingangspegel 0.0 – 1.0 für VU-Meter
    @Published public private(set) var inputLevel: Float = 0

    /// Wird für jeden fertigen Chunk aufgerufen (auf dem MainActor).
    public var onChunk: ((AudioChunk) -> Void)?

    // Chunk-Länge in Sekunden
    public let chunkDuration: TimeInterval

    private let engine = AVAudioEngine()
    private var chunkData = Data()
    private var sequenceNumber = 0
    private var chunkStartTime = Date()
    private var recordingFormat: AVAudioFormat?

    private let sampleRate: Double = 16_000   // Whisper bevorzugt 16 kHz
    private let levelSmoothingFactor: Float = 0.3

    public init(chunkDuration: TimeInterval = 5.0) {
        self.chunkDuration = chunkDuration
    }

    // MARK: - Public API

    public func start() throws {
        guard !isRecording else { return }

        let inputNode = engine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)

        guard let targetFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: sampleRate,
            channels: 1,
            interleaved: false
        ) else {
            throw AudioEngineError.formatNotSupported
        }

        guard let converter = AVAudioConverter(from: inputFormat, to: targetFormat) else {
            throw AudioEngineError.formatConversionFailed
        }

        recordingFormat = targetFormat
        chunkData = Data()
        sequenceNumber = 0
        chunkStartTime = Date()

        let chunkFrameCount = AVAudioFrameCount(sampleRate * chunkDuration)

        inputNode.installTap(onBus: 0, bufferSize: 4096, format: inputFormat) { [weak self] buffer, _ in
            self?.processTap(buffer: buffer, converter: converter, targetFormat: targetFormat, chunkFrameCount: chunkFrameCount)
        }

        try engine.start()
        isRecording = true
    }

    public func stop() {
        guard isRecording else { return }
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        flushRemainingChunk()
        isRecording = false
        inputLevel = 0
    }

    // MARK: - Private

    private func processTap(
        buffer: AVAudioPCMBuffer,
        converter: AVAudioConverter,
        targetFormat: AVAudioFormat,
        chunkFrameCount: AVAudioFrameCount
    ) {
        updateLevel(from: buffer)

        // Konvertierung auf 16 kHz Mono Float32
        let frameCapacity = AVAudioFrameCount(
            Double(buffer.frameLength) * (targetFormat.sampleRate / buffer.format.sampleRate)
        ) + 1

        guard let converted = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: frameCapacity) else { return }

        // AVAudioConverter.convert ruft den Block synchron auf – kein echtes Concurrency-Problem.
        nonisolated(unsafe) var inputConsumed = false
        converter.convert(to: converted, error: nil) { _, outStatus in
            if inputConsumed {
                outStatus.pointee = .noDataNow
                return nil
            }
            outStatus.pointee = .haveData
            inputConsumed = true
            return buffer
        }

        guard let floatData = converted.floatChannelData else { return }
        let bytes = Data(
            bytes: floatData[0],
            count: Int(converted.frameLength) * MemoryLayout<Float>.size
        )

        // Thread-sicherer Zugriff auf chunkData über MainActor
        Task { @MainActor [weak self] in
            guard let self else { return }
            self.chunkData.append(bytes)

            let framesAccumulated = self.chunkData.count / MemoryLayout<Float>.size
            if framesAccumulated >= Int(chunkFrameCount) {
                self.emitChunk()
            }
        }
    }

    private func emitChunk() {
        guard !chunkData.isEmpty, let format = recordingFormat else { return }
        let frameCount = chunkData.count / MemoryLayout<Float>.size
        let duration = Double(frameCount) / format.sampleRate

        let chunk = AudioChunk(
            data: chunkData,
            sampleRate: format.sampleRate,
            channelCount: Int(format.channelCount),
            sequenceNumber: sequenceNumber,
            timestamp: chunkStartTime,
            duration: duration
        )
        sequenceNumber += 1
        chunkStartTime = Date()
        chunkData = Data()
        onChunk?(chunk)
    }

    private func flushRemainingChunk() {
        guard !chunkData.isEmpty else { return }
        emitChunk()
    }

    private func updateLevel(from buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData else { return }
        let frameLength = Int(buffer.frameLength)
        guard frameLength > 0 else { return }

        let channelPtr = channelData[0]
        var sumSquares: Float = 0
        for i in 0..<frameLength {
            let sample = channelPtr[i]
            sumSquares += sample * sample
        }
        let rms = sqrt(sumSquares / Float(frameLength))
        let dB = 20 * log10(max(rms, 1e-7))
        // -60 dB → 0.0, 0 dB → 1.0
        let normalized = max(0, min(1, (dB + 60) / 60))

        Task { @MainActor [weak self] in
            guard let self else { return }
            // Glättung für ruhige VU-Meter-Anzeige
            self.inputLevel = self.inputLevel * (1 - self.levelSmoothingFactor) + normalized * self.levelSmoothingFactor
        }
    }
}
