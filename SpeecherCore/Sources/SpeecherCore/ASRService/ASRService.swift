import Foundation

/// Abstraktion für alle Spracherkennungs-Backends (Cloud + Lokal).
public protocol ASRService: Sendable {
    /// Transkribiert einen einzelnen AudioChunk (Batch-Modus).
    func transcribe(_ chunk: AudioChunk, language: String) async throws -> ASRResult
}

/// Wählt den passenden ASRService anhand der Einstellung.
public enum ASRServiceFactory {
    public enum Mode: Sendable {
        case whisperAPI(apiKey: String)
        case appleSpeech
    }

    public static func make(mode: Mode) -> any ASRService {
        switch mode {
        case .whisperAPI(let apiKey):
            return WhisperAPIService(apiKey: apiKey)
        case .appleSpeech:
            return AppleSpeechService()
        }
    }
}
