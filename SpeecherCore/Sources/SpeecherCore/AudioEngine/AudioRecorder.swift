@preconcurrency import AVFoundation
import Foundation

/// Nimmt Live-Audio vom Mikrofon auf und liefert es als 5-Sekunden-Chunks.
///
/// WICHTIG: Diese Klasse ist NICHT @MainActor, weil AVAudioEngine den
/// Tap-Callback auf einem Realtime-Audio-Thread aufruft. @Published-
/// Updates werden explizit per DispatchQueue.main.async versandt.
// @unchecked Sendable: Thread-Safety wird manuell sichergestellt –
// Audio-Thread schreibt ausschließlich in private Vars,
// Main-Thread empfängt via DispatchQueue.main.async.
public final class AudioRecorder: ObservableObject, @unchecked Sendable {
    @Published public private(set) var isRecording = false
    /// Eingangspegel 0.0 – 1.0 für VU-Meter
    @Published public private(set) var inputLevel: Float = 0

    /// Wird für jeden fertigen Chunk aufgerufen (auf dem Main-Thread).
    public var onChunk: (@Sendable (AudioChunk) -> Void)?

    public let chunkDuration: TimeInterval

    private let engine = AVAudioEngine()

    // Folgende Properties werden ausschließlich vom Audio-Thread geschrieben
    // (AVAudioEngine garantiert einen seriellen Tap-Thread → kein Lock nötig).
    private var chunkData = Data()
    private var sequenceNumber = 0
    private var chunkStartTime = Date()
    private var recordingFormat: AVAudioFormat?
    private var smoothedLevel: Float = 0

    private let sampleRate: Double = 16_000
    private let levelSmoothingFactor: Float = 0.3

    public init(chunkDuration: TimeInterval = 5.0) {
        self.chunkDuration = chunkDuration
    }

    // MARK: - Public API (darf vom Main-Thread aufgerufen werden)

    public func start() throws {
        guard !isRecording else { return }

        let inputNode = engine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)

        guard let targetFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: sampleRate,
            channels: 1,
            interleaved: false
        ) else { throw AudioEngineError.formatNotSupported }

        guard let converter = AVAudioConverter(from: inputFormat, to: targetFormat) else {
            throw AudioEngineError.formatConversionFailed
        }

        recordingFormat = targetFormat
        chunkData = Data()
        sequenceNumber = 0
        chunkStartTime = Date()
        smoothedLevel = 0

        let chunkFrameCount = AVAudioFrameCount(sampleRate * chunkDuration)

        // Tap-Closure läuft auf AVAudioEngines internem Audio-Thread (nonisolated).
        inputNode.installTap(onBus: 0, bufferSize: 4096, format: inputFormat) { [weak self] buffer, _ in
            self?.processTap(buffer: buffer, converter: converter,
                             targetFormat: targetFormat, chunkFrameCount: chunkFrameCount)
        }

        try engine.start()

        DispatchQueue.main.async { [weak self] in
            self?.isRecording = true
        }
    }

    public func stop() {
        // removeTap wartet auf laufende Callbacks → danach ist chunkData stabil.
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        flushRemainingChunk()
        DispatchQueue.main.async { [weak self] in
            self?.isRecording = false
            self?.inputLevel = 0
        }
    }

    // MARK: - Audio-Thread (nonisolated)

    private func processTap(
        buffer: AVAudioPCMBuffer,
        converter: AVAudioConverter,
        targetFormat: AVAudioFormat,
        chunkFrameCount: AVAudioFrameCount
    ) {
        // Pegel berechnen und auf Main-Thread aktualisieren
        let rawLevel = computeRMSLevel(from: buffer)
        smoothedLevel = smoothedLevel * (1 - levelSmoothingFactor) + rawLevel * levelSmoothingFactor
        let level = smoothedLevel
        DispatchQueue.main.async { [weak self] in
            self?.inputLevel = level
        }

        // Buffer auf 16 kHz Mono Float32 konvertieren
        let frameCapacity = AVAudioFrameCount(
            Double(buffer.frameLength) * (targetFormat.sampleRate / buffer.format.sampleRate)
        ) + 1
        guard let converted = AVAudioPCMBuffer(pcmFormat: targetFormat,
                                               frameCapacity: frameCapacity) else { return }

        nonisolated(unsafe) var inputConsumed = false
        converter.convert(to: converted, error: nil) { _, outStatus in
            if inputConsumed { outStatus.pointee = .noDataNow; return nil }
            outStatus.pointee = .haveData
            inputConsumed = true
            return buffer
        }

        guard let floatData = converted.floatChannelData else { return }
        let bytes = Data(bytes: floatData[0],
                         count: Int(converted.frameLength) * MemoryLayout<Float>.size)

        chunkData.append(bytes)

        if chunkData.count / MemoryLayout<Float>.size >= Int(chunkFrameCount) {
            emitChunk()
        }
    }

    private func emitChunk() {
        guard !chunkData.isEmpty, let format = recordingFormat else { return }
        let duration = Double(chunkData.count / MemoryLayout<Float>.size) / format.sampleRate

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

        let callback = onChunk
        DispatchQueue.main.async { callback?(chunk) }
    }

    private func flushRemainingChunk() {
        guard !chunkData.isEmpty else { return }
        emitChunk()
    }

    private func computeRMSLevel(from buffer: AVAudioPCMBuffer) -> Float {
        guard let data = buffer.floatChannelData, buffer.frameLength > 0 else { return 0 }
        let ptr = data[0]
        let count = Int(buffer.frameLength)
        var sum: Float = 0
        for i in 0..<count { sum += ptr[i] * ptr[i] }
        let rms = sqrt(sum / Float(count))
        let dB = 20 * log10(max(rms, 1e-7))
        return max(0, min(1, (dB + 60) / 60))
    }
}
