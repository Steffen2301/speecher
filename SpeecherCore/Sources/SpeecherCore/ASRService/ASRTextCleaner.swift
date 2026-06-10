import Foundation
import NaturalLanguage

/// Bereinigt rohen ASR-Text vor der Grammatikkorrektur:
/// - Entfernt Füllwörter ("äh", "ähm", …)
/// - Entfernt direkt aufeinanderfolgende Wortwiederholungen
/// - Entfernt einzeln stehende Nicht-Wörter (zu kurz / kein Buchstabe)
/// - Stellt satzabschließende Großschreibung sicher
public enum ASRTextCleaner {

    // Füllwörter die SFSpeechRecognizer häufig transkribiert
    private static let fillerWords: Set<String> = [
        // Deutsch
        "äh", "ähm", "hmm", "hm", "mhm", "ähh", "öhm", "öh", "ne", "ja",
        // Englisch (gemischte Aufnahmen)
        "ah", "oh", "eh", "um", "uhm", "uh", "hmm",
    ]

    // Maximale Länge für einen "sinnlosen" Token ohne echte Buchstaben
    private static let minTokenLetterCount = 2

    public static func clean(_ text: String, language: String = "de") -> String {
        guard !text.trimmingCharacters(in: .whitespaces).isEmpty else { return text }

        var tokens = tokenize(text)
        tokens = removeFillerWords(tokens)
        tokens = removeConsecutiveDuplicates(tokens)
        tokens = removeNonWords(tokens)

        var result = tokens.joined(separator: " ")
        result = result.trimmingCharacters(in: .whitespaces)
        result = capitalizeFirstLetter(result)
        return result
    }

    // MARK: - Private

    private static func tokenize(_ text: String) -> [String] {
        // Erhalte Satzzeichen als eigene Token
        text.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
    }

    private static func removeFillerWords(_ tokens: [String]) -> [String] {
        tokens.filter { token in
            let lower = token.lowercased()
                            .trimmingCharacters(in: .punctuationCharacters)
            return !fillerWords.contains(lower)
        }
    }

    /// Entfernt direkt aufeinanderfolgende identische Tokens (case-insensitive).
    private static func removeConsecutiveDuplicates(_ tokens: [String]) -> [String] {
        var result: [String] = []
        var previousNormalized = ""
        for token in tokens {
            let normalized = token.lowercased()
                                  .trimmingCharacters(in: .punctuationCharacters)
            if normalized != previousNormalized {
                result.append(token)
            }
            previousNormalized = normalized
        }
        return result
    }

    /// Entfernt Token die keine sinnvollen Wörter sein können:
    /// - Weniger als 2 Buchstaben (außer "I", "a", "o" etc. in bekannten Sprachen)
    /// - Nur Sonderzeichen
    private static func removeNonWords(_ tokens: [String]) -> [String] {
        tokens.filter { token in
            let letters = token.unicodeScalars.filter { CharacterSet.letters.contains($0) }
            return letters.count >= minTokenLetterCount || isKnownShortWord(token)
        }
    }

    private static func isKnownShortWord(_ token: String) -> Bool {
        let short: Set<String> = ["a", "o", "i", "in", "an", "am", "im", "ob",
                                   "da", "so", "wo", "ja", "nein", "ich", "du"]
        return short.contains(token.lowercased())
    }

    private static func capitalizeFirstLetter(_ text: String) -> String {
        guard let first = text.first else { return text }
        return first.uppercased() + text.dropFirst()
    }
}
