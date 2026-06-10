import Foundation

/// Kostenpflichtig: Korrektur + Übersetzung via Anthropic Claude API.
/// Erfordert einen API-Key von https://console.anthropic.com
public final class ClaudeAPIService: CorrectionService {
    private let apiKey: String
    private let model: String
    private let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!
    private let session: URLSession

    public init(
        apiKey: String,
        model: String = "claude-haiku-4-5-20251001",
        session: URLSession = .shared
    ) {
        self.apiKey = apiKey
        self.model = model
        self.session = session
    }

    public func correct(_ text: String, sourceLang: String, targetLang: String) async throws -> CorrectionResult {
        guard !apiKey.isEmpty else { throw CorrectionError.apiKeyMissing(service: "Claude API") }

        let needsTranslation = sourceLang != targetLang
        let result = try await callAPI(text: text,
                                       sourceLang: sourceLang,
                                       targetLang: targetLang,
                                       translate: needsTranslation)
        return CorrectionResult(
            correctedText: result,
            wasTranslated: needsTranslation,
            sourceLanguage: sourceLang,
            targetLanguage: targetLang,
            backend: "Claude (\(model))"
        )
    }

    private func callAPI(text: String, sourceLang: String, targetLang: String, translate: Bool) async throws -> String {
        struct Body: Encodable {
            struct Message: Encodable { let role: String; let content: String }
            let model: String
            let max_tokens: Int
            let system: String
            let messages: [Message]
        }

        let body = Body(
            model: model,
            max_tokens: 2048,
            system: systemPrompt(translate: translate, sourceLang: sourceLang, targetLang: targetLang),
            messages: [.init(role: "user", content: text)]
        )

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw CorrectionError.invalidResponse("Claude API HTTP \(code)")
        }

        struct Response: Decodable {
            struct Content: Decodable { let text: String }
            let content: [Content]
        }
        let decoded = try JSONDecoder().decode(Response.self, from: data)
        return decoded.content.first?.text.trimmingCharacters(in: .whitespacesAndNewlines) ?? text
    }

    private func systemPrompt(translate: Bool, sourceLang: String, targetLang: String) -> String {
        if translate {
            let prompt = "Du bist ein professioneller Lektor und Übersetzer. "
            let correction = "Korrigiere Rechtschreib- und Grammatikfehler "
            let translation = "und übersetze von \(sourceLang) nach \(targetLang). "
            let instruction = "Gib NUR den fertigen Text zurück, ohne Kommentare."
            return prompt + correction + translation + instruction
        }
        let prompt = "Du bist ein professioneller Lektor. "
        let correction = "Korrigiere Rechtschreib- und Grammatikfehler. "
        let style = "Verändere Inhalt und Stil nicht. "
        let instruction = "Gib NUR den korrigierten Text zurück, ohne Kommentare."
        return prompt + correction + style + instruction
    }
}
