import Foundation

/// Kostenlose Korrektur + Übersetzung via lokalem LLM (Ollama).
/// Erfordert: Ollama installiert (https://ollama.com) und ein Modell geladen.
///
/// Empfohlene Modelle:
///   ollama pull llama3.2      (3B, schnell, gut)
///   ollama pull mistral       (7B, sehr gut)
///   ollama pull phi4-mini     (3.8B, effizient auf Apple Silicon)
public final class OllamaService: CorrectionService {
    public let model: String
    private let host: URL
    private let session: URLSession

    public static let defaultHost = URL(string: "http://localhost:11434")!

    public init(
        model: String = "llama3.2",
        host: URL = defaultHost,
        session: URLSession = .shared
    ) {
        self.model = model
        self.host = host
        self.session = session
    }

    public func correct(_ text: String, sourceLang: String, targetLang: String) async throws -> CorrectionResult {
        let needsTranslation = sourceLang != targetLang
        let prompt = buildPrompt(text: text, sourceLang: sourceLang,
                                 targetLang: targetLang, translate: needsTranslation)

        let result = try await chat(systemPrompt: systemPrompt(translate: needsTranslation,
                                                               sourceLang: sourceLang,
                                                               targetLang: targetLang),
                                    userMessage: prompt)
        return CorrectionResult(
            correctedText: result,
            wasTranslated: needsTranslation,
            sourceLanguage: sourceLang,
            targetLanguage: targetLang,
            backend: "Ollama (\(model))"
        )
    }

    // MARK: - Ollama Chat API

    private func chat(systemPrompt: String, userMessage: String) async throws -> String {
        let endpoint = host.appendingPathComponent("api/chat")

        struct Request: Encodable {
            struct Message: Encodable { let role: String; let content: String }
            let model: String
            let messages: [Message]
            let stream: Bool
            let options: Options
            struct Options: Encodable { let temperature: Double }
        }

        let body = Request(
            model: model,
            messages: [
                .init(role: "system", content: systemPrompt),
                .init(role: "user", content: userMessage)
            ],
            stream: false,
            options: .init(temperature: 0.1)   // niedrig für konsistente Korrekturen
        )

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)
        request.timeoutInterval = 120

        let (data, response) = try await session.data(for: request)

        if let http = response as? HTTPURLResponse, http.statusCode == 000 {
            // Ollama antwortet nicht auf Port 11434
        }
        guard let http = response as? HTTPURLResponse else {
            throw CorrectionError.ollamaNotRunning
        }
        if http.statusCode == 0 || (http.statusCode >= 400 && http.statusCode < 500) {
            throw CorrectionError.ollamaNotRunning
        }
        guard http.statusCode == 200 else {
            throw CorrectionError.invalidResponse("HTTP \(http.statusCode)")
        }

        struct Response: Decodable {
            struct Message: Decodable { let content: String }
            let message: Message
        }

        do {
            let decoded = try JSONDecoder().decode(Response.self, from: data)
            return decoded.message.content.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            throw CorrectionError.invalidResponse("JSON: \(error.localizedDescription)")
        }
    }

    /// Prüft ob Ollama auf dem konfigurierten Host erreichbar ist.
    public func isReachable() async -> Bool {
        let url = host.appendingPathComponent("api/tags")
        guard let (_, response) = try? await session.data(from: url),
              let http = response as? HTTPURLResponse else { return false }
        return http.statusCode == 200
    }

    /// Gibt die auf dem Ollama-Server verfügbaren Modelle zurück.
    public func availableModels() async throws -> [String] {
        let url = host.appendingPathComponent("api/tags")
        let (data, _) = try await session.data(from: url)

        struct TagsResponse: Decodable {
            struct Model: Decodable { let name: String }
            let models: [Model]
        }
        let decoded = try JSONDecoder().decode(TagsResponse.self, from: data)
        return decoded.models.map(\.name)
    }

    // MARK: - Prompts

    private func systemPrompt(translate: Bool, sourceLang: String, targetLang: String) -> String {
        let srcName = languageName(sourceLang)
        let tgtName = languageName(targetLang)

        if translate {
            return """
            Du bist ein professioneller Übersetzer und Lektor.
            Deine Aufgabe:
            1. Korrigiere Rechtschreib- und Grammatikfehler im \(srcName) Text.
            2. Übersetze den korrigierten Text ins \(tgtName).
            Regeln:
            - Verändere den Inhalt, Stil oder Ton NICHT.
            - Gib NUR den fertigen Text zurück, ohne Erklärungen, Anmerkungen oder Formatierungen.
            - Keine Anführungszeichen um den Text.
            """
        } else {
            return """
            Du bist ein professioneller Lektor für \(srcName).
            Deine Aufgabe: Korrigiere Rechtschreib- und Grammatikfehler im folgenden Text.
            Regeln:
            - Verändere den Inhalt, Stil oder Ton NICHT.
            - Gib NUR den korrigierten Text zurück, ohne Erklärungen.
            - Keine Anführungszeichen um den Text.
            """
        }
    }

    private func buildPrompt(text: String, sourceLang: String, targetLang: String, translate: Bool) -> String {
        translate
            ? "Korrigiere und übersetze (von \(languageName(sourceLang)) nach \(languageName(targetLang))):\n\n\(text)"
            : "Korrigiere:\n\n\(text)"
    }

    private func languageName(_ code: String) -> String {
        let map = [
            "de": "Deutsch", "en": "Englisch", "fr": "Französisch",
            "es": "Spanisch", "it": "Italienisch", "pt": "Portugiesisch",
            "nl": "Niederländisch", "pl": "Polnisch", "ru": "Russisch",
            "zh": "Chinesisch", "ja": "Japanisch", "ar": "Arabisch"
        ]
        return map[code] ?? code
    }
}
