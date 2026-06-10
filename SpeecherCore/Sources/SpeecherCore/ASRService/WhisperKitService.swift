@preconcurrency import WhisperKit
import Foundation

/// Lokale Spracherkennung via WhisperKit (Core ML, on-device, kein API-Key).
/// Unterstützt dieselben Modelle wie OpenAI Whisper (tiny → large-v3).
public actor WhisperKitService: ASRService {
    private var kit: WhisperKit?
    public let modelName: String

    public init(model: WhisperModel = .base) {
        self.modelName = model.identifier
    }

    // MARK: - Platform Check

    /// WhisperKit nutzt Core ML mit Neural Engine – primär Apple Silicon.
    /// Auf Intel (x86_64) wird Apple Speech als Fallback empfohlen.
    public static var isSupported: Bool {
        #if arch(arm64)
        return true
        #else
        return false   // Intel: Core ML-Inferenz kann crashen
        #endif
    }

    // MARK: - ASRService

    public func transcribe(_ chunk: AudioChunk, language: String) async throws -> ASRResult {
        guard Self.isSupported else {
            throw ASRError.inferenceError("WhisperKit erfordert Apple Silicon (M1+). Bitte Apple Speech in den Einstellungen wählen.")
        }
        let whisper = try await loadKit()

        let samples = chunk.data.withUnsafeBytes {
            Array($0.bindMemory(to: Float.self))
        }

        let options = DecodingOptions(
            task: .transcribe,
            language: language == "auto" ? nil : language,
            temperatureFallbackCount: 3
        )

        let results = try await whisper.transcribe(audioArray: samples, decodeOptions: options)
        let text = results
            .compactMap(\.text)
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return ASRResult(
            text: text,
            detectedLanguage: results.first?.language,
            audioDuration: chunk.duration,
            sequenceNumber: chunk.sequenceNumber,
            isFinal: true
        )
    }

    /// Gibt true zurück wenn das Modell bereits geladen ist.
    public var isLoaded: Bool { kit != nil }

    /// Lädt das Modell vorab (z. B. beim App-Start im Hintergrund).
    public func preload() async throws {
        _ = try await loadKit()
    }

    // MARK: - Private

    private func loadKit() async throws -> WhisperKit {
        if let existing = kit { return existing }
        let loaded = try await WhisperKit(model: modelName, verbose: false)
        kit = loaded
        return loaded
    }
}

// MARK: - Modell-Auswahl

public extension WhisperKitService {
    enum WhisperModel: String, CaseIterable, Sendable {
        case tiny       = "tiny"
        case base       = "base"
        case small      = "small"
        case medium     = "medium"
        case largeV3    = "large-v3"
        case largeTurbo = "large-v3-turbo"

        public var identifier: String { "openai_whisper-\(rawValue)" }

        public var displayName: String {
            switch self {
            case .tiny:       return "Tiny (~39 MB) – sehr schnell"
            case .base:       return "Base (~74 MB) – schnell, gut (Standard)"
            case .small:      return "Small (~244 MB) – sehr gut"
            case .medium:     return "Medium (~769 MB) – exzellent"
            case .largeV3:    return "Large v3 (~1,5 GB) – beste Qualität"
            case .largeTurbo: return "Large v3 Turbo (~809 MB) – schnell & präzise"
            }
        }

        public var approximateSizeMB: Int {
            switch self {
            case .tiny: return 39; case .base: return 74; case .small: return 244
            case .medium: return 769; case .largeV3: return 1500; case .largeTurbo: return 809
            }
        }
    }
}
