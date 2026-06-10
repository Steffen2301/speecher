import Foundation

/// Ergebnis einer Spracherkennungs-Anfrage.
public struct ASRResult: Sendable {
    /// Erkannter / transkribierter Text (noch nicht korrigiert).
    public let text: String
    /// Erkannte Sprache (BCP-47-Code, z. B. „de", „en") – optional je nach Service.
    public let detectedLanguage: String?
    /// Verarbeitete Audiodauer in Sekunden.
    public let audioDuration: TimeInterval
    /// Laufende Nummer des zugehörigen AudioChunk.
    public let sequenceNumber: Int
    /// true = endgültiges Ergebnis, false = Zwischenergebnis (Streaming)
    public let isFinal: Bool

    public var isEmpty: Bool { text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
}
