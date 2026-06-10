import Foundation

/// Kostenlose Grammatik- und Rechtschreibkorrektur via LanguageTool Public API.
/// Kein API-Key erforderlich (20 Anfragen/Minute im Free-Tier).
/// Übersetzung: Apple Translation Framework (macOS 15+) oder Fehler mit Hinweis.
///
/// LanguageTool-Lizenz: LGPL – https://languagetool.org
/// Public API: https://api.languagetool.org/v2/check
public final class LanguageToolService: CorrectionService {
    private let endpoint = URL(string: "https://api.languagetool.org/v2/check")!
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func correct(_ text: String, sourceLang: String, targetLang: String) async throws -> CorrectionResult {
        let corrected = try await languageToolCheck(text, language: sourceLang)
        let needsTranslation = sourceLang != targetLang

        if needsTranslation {
            if #available(macOS 15.0, *) {
                let translated = try await appleTranslate(corrected, from: sourceLang, to: targetLang)
                return CorrectionResult(
                    correctedText: translated,
                    wasTranslated: true,
                    sourceLanguage: sourceLang,
                    targetLanguage: targetLang,
                    backend: "LanguageTool + Apple Übersetzer"
                )
            } else {
                // macOS 14 Fallback: nur korrigierter Text, kein Übersetzen
                return CorrectionResult(
                    correctedText: corrected + "\n\n⚠️ Übersetzung erfordert macOS 15 oder Ollama.",
                    wasTranslated: false,
                    sourceLanguage: sourceLang,
                    targetLanguage: targetLang,
                    backend: "LanguageTool (ohne Übersetzung)"
                )
            }
        }

        return CorrectionResult(
            correctedText: corrected,
            wasTranslated: false,
            sourceLanguage: sourceLang,
            targetLanguage: targetLang,
            backend: "LanguageTool"
        )
    }

    // MARK: - LanguageTool

    private func languageToolCheck(_ text: String, language: String) async throws -> String {
        // Bei zu kurzem Text LanguageTool überspringen
        guard text.split(separator: " ").count >= 3 else { return text }

        var body = URLComponents()
        body.queryItems = [
            URLQueryItem(name: "text", value: text),
            URLQueryItem(name: "language", value: ltLanguageCode(language)),
            URLQueryItem(name: "enabledOnly", value: "false"),
        ]

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("Speecher/1.0", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 10
        request.httpBody = body.percentEncodedQuery?.data(using: .utf8)

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            // Netzwerkfehler: unkorrigierten Text zurückgeben
            return text
        }

        guard let http = response as? HTTPURLResponse else { return text }
        guard http.statusCode == 200 else {
            // Rate-Limit (429) oder Server-Fehler → unkorrigiert zurück
            return text
        }

        return try applyMatches(to: text, data: data)
    }

    private func applyMatches(to original: String, data: Data) throws -> String {
        struct LTResponse: Decodable {
            struct Match: Decodable {
                struct Replacement: Decodable { let value: String }
                struct Context: Decodable { let offset: Int; let length: Int }
                let offset: Int
                let length: Int
                let replacements: [Replacement]
                let context: Context
            }
            let matches: [Match]
        }

        let decoded: LTResponse
        do {
            decoded = try JSONDecoder().decode(LTResponse.self, from: data)
        } catch {
            return original  // Bei Parse-Fehler: unkorrigiert zurück
        }

        guard !decoded.matches.isEmpty else { return original }

        // Matches von hinten anwenden damit Offsets stimmen
        var result = original
        for match in decoded.matches.sorted(by: { $0.offset > $1.offset }) {
            guard let replacement = match.replacements.first?.value else { continue }
            let start = result.index(result.startIndex, offsetBy: match.offset,
                                     limitedBy: result.endIndex) ?? result.endIndex
            let end   = result.index(start, offsetBy: match.length,
                                     limitedBy: result.endIndex) ?? result.endIndex
            result.replaceSubrange(start..<end, with: replacement)
        }
        return result
    }

    // MARK: - Apple Translation (macOS 15+)

    @available(macOS 15.0, *)
    private func appleTranslate(_ text: String, from source: String, to target: String) async throws -> String {
        // Stub: Apple Translation Framework wird direkt in der App-Schicht verwendet.
        // SpeecherCore importiert kein Translation.framework um macOS 14 kompatibel zu bleiben.
        throw CorrectionError.translationNotAvailable(
            reason: "Apple Translation ist in der App-Schicht implementiert (Phase 2)."
        )
    }

    // MARK: - Helper

    /// LanguageTool erwartet IETF-Tags wie „de-DE", „en-US".
    private func ltLanguageCode(_ code: String) -> String {
        let map = [
            "de": "de-DE", "en": "en-US", "fr": "fr-FR",
            "es": "es-ES", "it": "it-IT", "pt": "pt-PT",
            "nl": "nl-NL", "pl": "pl-PL", "ru": "ru-RU",
            "zh": "zh-CN", "ja": "ja-JP", "ar": "ar",
        ]
        return map[code] ?? code
    }
}
