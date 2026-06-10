import Foundation

public enum CorrectionError: LocalizedError {
    case apiKeyMissing(service: String)
    case networkError(Error)
    case invalidResponse(String)
    case ollamaNotRunning
    case translationNotAvailable(reason: String)
    case unsupportedLanguagePair(String, String)

    public var errorDescription: String? {
        switch self {
        case .apiKeyMissing(let s):
            return "\(s): Kein API-Key hinterlegt. Bitte in den Einstellungen → Modelle eintragen."
        case .networkError(let e):
            return "Netzwerkfehler: \(e.localizedDescription)"
        case .invalidResponse(let d):
            return "Ungültige Antwort: \(d)"
        case .ollamaNotRunning:
            return "Ollama läuft nicht. Bitte Ollama starten (ollama serve) und ein Modell laden."
        case .translationNotAvailable(let r):
            return "Übersetzung nicht verfügbar: \(r)"
        case .unsupportedLanguagePair(let src, let tgt):
            return "Sprachpaar \(src) → \(tgt) wird nicht unterstützt."
        }
    }
}
