import Foundation

/// Abstraktion für alle Spracherkennungs-Backends.
public protocol ASRService: Sendable {
    func transcribe(_ chunk: AudioChunk, language: String) async throws -> ASRResult
}

/// Wählt den passenden ASRService anhand der Einstellung.
public enum ASRServiceFactory {
    public enum Mode: Sendable {
        /// Lokale Inferenz via WhisperKit (Core ML, on-device, kein Internet)
        case whisperKit(model: WhisperKitService.WhisperModel)
        /// Apples eingebaute Spracherkennung (leichtgewichtig, begrenzte Sprachen)
        case appleSpeech
    }

    public static func make(mode: Mode) -> any ASRService {
        switch mode {
        case .whisperKit(let model):
            return WhisperKitService(model: model)
        case .appleSpeech:
            return AppleSpeechService()
        }
    }
}
