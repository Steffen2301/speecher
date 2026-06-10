import CoreAudio
import Foundation

public enum AudioEngineError: LocalizedError {
    case deviceSelectionFailed(OSStatus)
    case formatNotSupported
    case formatConversionFailed
    case unsupportedFileFormat(String)
    case microphonePermissionDenied
    case engineStartFailed(Error)

    public var errorDescription: String? {
        switch self {
        case .deviceSelectionFailed(let status):
            return "Mikrofon konnte nicht ausgewählt werden (OSStatus: \(status))."
        case .formatNotSupported:
            return "Das Audioformat wird nicht unterstützt."
        case .formatConversionFailed:
            return "Audioformat-Konvertierung fehlgeschlagen."
        case .unsupportedFileFormat(let ext):
            return "Dateiformat '.\(ext)' wird nicht unterstützt. Unterstützt: \(AudioFileProcessor.supportedExtensions.sorted().joined(separator: ", "))."
        case .microphonePermissionDenied:
            return "Zugriff auf das Mikrofon wurde verweigert. Bitte in den Systemeinstellungen erlauben."
        case .engineStartFailed(let error):
            return "Audio-Engine konnte nicht gestartet werden: \(error.localizedDescription)"
        }
    }
}
