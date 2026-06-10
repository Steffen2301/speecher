import Foundation
#if canImport(AppKit)
import AppKit
#endif

/// Kostenlos, null Setup: NSSpellChecker für Rechtschreibung.
/// Übersetzung: Apple Translation Framework (macOS 15+), sonst kein Übersetzen.
public final class AppleBuiltinService: CorrectionService {
    public init() {}

    public func correct(_ text: String, sourceLang: String, targetLang: String) async throws -> CorrectionResult {
        let corrected = spellCheck(text, language: sourceLang)
        let needsTranslation = sourceLang != targetLang

        if needsTranslation {
            let translated = try await translate(corrected, from: sourceLang, to: targetLang)
            return CorrectionResult(
                correctedText: translated,
                wasTranslated: true,
                sourceLanguage: sourceLang,
                targetLanguage: targetLang,
                backend: "Apple (NSSpellChecker + Übersetzer)"
            )
        }

        return CorrectionResult(
            correctedText: corrected,
            wasTranslated: false,
            sourceLanguage: sourceLang,
            targetLanguage: targetLang,
            backend: "Apple NSSpellChecker"
        )
    }

    // MARK: - Spell Check (NSSpellChecker)

    private func spellCheck(_ text: String, language: String) -> String {
#if canImport(AppKit)
        let checker = NSSpellChecker.shared
        let locale = bcp47ToLocale(language)
        checker.setLanguage(locale)

        var result = text
        var offset = 0

        while true {
            let range = NSRange(location: offset, length: result.utf16.count - offset)
            let misspelled = checker.checkSpelling(of: result, startingAt: offset,
                                                    language: locale, wrap: false,
                                                    inSpellDocumentWithTag: 0, wordCount: nil)
            guard misspelled.location != NSNotFound else { break }

            if let guesses = checker.guesses(forWordRange: misspelled, in: result,
                                              language: locale, inSpellDocumentWithTag: 0),
               let best = guesses.first {
                let nsResult = result as NSString
                result = nsResult.replacingCharacters(in: misspelled, with: best)
                offset = misspelled.location + best.utf16.count
            } else {
                offset = misspelled.location + misspelled.length
            }

            if offset >= result.utf16.count { break }
        }
        return result
#else
        return text
#endif
    }

    // MARK: - Translation (Apple Translation Framework, macOS 15+)

    private func translate(_ text: String, from source: String, to target: String) async throws -> String {
        if #available(macOS 15.0, *) {
            return try await appleTranslate(text, from: source, to: target)
        } else {
            // macOS 14: kein Apple Translation Framework → Text unverändert zurückgeben
            throw CorrectionError.translationNotAvailable(
                reason: "Apple Translation erfordert macOS 15. Bitte Ollama oder eine API verwenden."
            )
        }
    }

    @available(macOS 15.0, *)
    private func appleTranslate(_ text: String, from source: String, to target: String) async throws -> String {
        // Apple Translation Framework (Translation.framework)
        // Dynamisch geladen um macOS 14-Kompatibilität zu erhalten
        guard let translationClass = NSClassFromString("TLTranslationSession") as? NSObject.Type else {
            throw CorrectionError.translationNotAvailable(reason: "Translation.framework nicht verfügbar.")
        }
        _ = translationClass   // verhindert unused-Warnung
        // Vollständige Integration erfolgt in der App-Schicht via @available-Guard.
        // Hier nur Stub – in Phase 2 wird Translation.framework direkt eingebunden.
        throw CorrectionError.translationNotAvailable(
            reason: "Apple Translation Swift-Integration erfolgt in Phase 2."
        )
    }

    private func bcp47ToLocale(_ code: String) -> String {
        let map = [
            "de": "de", "en": "en", "fr": "fr", "es": "es",
            "it": "it", "pt": "pt", "nl": "nl", "pl": "pl",
            "ru": "ru", "zh": "zh-Hans", "ja": "ja", "ar": "ar"
        ]
        return map[code] ?? code
    }
}
