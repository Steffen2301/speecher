import Foundation

public enum ASRError: LocalizedError {
    case apiKeyMissing
    case networkError(Error)
    case invalidResponse(Int)
    case decodingFailed(String)
    case permissionDenied
    case serviceUnavailable
    case audioConversionFailed

    public var errorDescription: String? {
        switch self {
        case .apiKeyMissing:
            return "Kein API-Key hinterlegt. Bitte in den Einstellungen → Modelle eintragen."
        case .networkError(let error):
            return "Netzwerkfehler: \(error.localizedDescription)"
        case .invalidResponse(let code):
            return "Ungültige API-Antwort (HTTP \(code))."
        case .decodingFailed(let detail):
            return "Antwort konnte nicht gelesen werden: \(detail)"
        case .permissionDenied:
            return "Spracherkennungs-Berechtigung verweigert."
        case .serviceUnavailable:
            return "Spracherkennungs-Dienst ist nicht verfügbar."
        case .audioConversionFailed:
            return "Audiodaten konnten nicht konvertiert werden."
        }
    }
}
