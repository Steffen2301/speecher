import Foundation

/// Kostenpflichtig: Korrektur + Übersetzung via OpenAI Chat Completions API.
/// Erfordert einen API-Key von https://platform.openai.com
public final class OpenAIService: CorrectionService {
    private let apiKey: String
    private let model: String
    private let endpoint = URL(string: "https://api.openai.com/v1/chat/completions")!
    private let session: URLSession

    public init(
        apiKey: String,
        model: String = "gpt-4o-mini",
        session: URLSession = .shared
    ) {
        self.apiKey = apiKey
        self.model = model
        self.session = session
    }

    public func correct(_ text: String, sourceLang: String, targetLang: String) async throws -> CorrectionResult {
        guard !apiKey.isEmpty else { throw CorrectionError.apiKeyMissing(service: "OpenAI") }

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
            backend: "OpenAI (\(model))"
        )
    }

    private func callAPI(text: String, sourceLang: String, targetLang: String, translate: Bool) async throws -> String {
        struct Body: Encodable {
            struct Message: Encodable { let role: String; let content: String }
            let model: String
            let messages: [Message]
            let temperature: Double
        }

        let system = translate
            ? "You are a professional editor and translator. Correct grammar and spelling errors, then translate from \(sourceLang) to \(targetLang). Return ONLY the final text, no comments."
            : "You are a professional editor. Correct grammar and spelling errors. Do not change content or style. Return ONLY the corrected text, no comments."

        let body = Body(
            model: model,
            messages: [
                .init(role: "system", content: system),
                .init(role: "user", content: text)
            ],
            temperature: 0.1
        )

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw CorrectionError.invalidResponse("OpenAI HTTP \(code)")
        }

        struct Response: Decodable {
            struct Choice: Decodable {
                struct Message: Decodable { let content: String }
                let message: Message
            }
            let choices: [Choice]
        }
        let decoded = try JSONDecoder().decode(Response.self, from: data)
        return decoded.choices.first?.message.content.trimmingCharacters(in: .whitespacesAndNewlines) ?? text
    }
}
