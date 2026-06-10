import Foundation

/// Ergebnis eines Ausgabe-Versuchs.
public enum OutputResult: Sendable {
    case insertedAtCursor               // AXUIElement-Inject erfolgreich
    case pastedViaSimulation            // Clipboard + simuliertes Cmd+V
    case copiedToClipboard              // Nur in Zwischenablage – Nutzer muss selbst einfügen
    case noTargetSaved                  // saveFocus() wurde nicht aufgerufen
}

/// Abstraktion für die Textausgabe (Cursor-Inject oder Fallback-Textfeld).
@MainActor
public protocol OutputService: AnyObject {
    /// Vor Aufnahmestart aufrufen – speichert aktives Fenster und Cursor-Position.
    func saveFocus()
    /// Text an gespeicherter Position einfügen.
    func insert(_ text: String) async -> OutputResult
    /// true wenn Accessibility-Berechtigung vorhanden ist.
    var isAccessibilityGranted: Bool { get }
}

public enum OutputError: LocalizedError {
    case accessibilityDenied
    case insertionFailed(String)

    public var errorDescription: String? {
        switch self {
        case .accessibilityDenied:
            return "Accessibility-Zugriff verweigert. Bitte in Systemeinstellungen → Datenschutz → Bedienungshilfen erlauben."
        case .insertionFailed(let detail):
            return "Text konnte nicht eingefügt werden: \(detail)"
        }
    }
}
