import Foundation

public enum ASRError: LocalizedError {
    case modelNotLoaded(String)
    case networkError(Error)
    case inferenceError(String)
    case permissionDenied
    case serviceUnavailable
    case audioConversionFailed

    public var errorDescription: String? {
        switch self {
        case .modelNotLoaded(let name):
            return "Modell '\(name)' konnte nicht geladen werden. Bitte in den Einstellungen herunterladen."
        case .networkError(let error):
            return "Spracherkennung fehlgeschlagen: \(error.localizedDescription)"
        case .inferenceError(let detail):
            return "Transkription fehlgeschlagen: \(detail)"
        case .permissionDenied:
            return "Spracherkennungs-Berechtigung verweigert."
        case .serviceUnavailable:
            return "Spracherkennungs-Dienst ist nicht verfügbar."
        case .audioConversionFailed:
            return "Audiodaten konnten nicht konvertiert werden."
        }
    }
}
