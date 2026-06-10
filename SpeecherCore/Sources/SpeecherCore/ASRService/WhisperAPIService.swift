import Foundation

/// Transkribiert Audio über die OpenAI Whisper API (cloud).
/// Endpunkt: POST https://api.openai.com/v1/audio/transcriptions
public final class WhisperAPIService: ASRService {
    private let apiKey: String
    private let session: URLSession
    private let endpoint = URL(string: "https://api.openai.com/v1/audio/transcriptions")!

    public init(apiKey: String, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.session = session
    }

    public func transcribe(_ chunk: AudioChunk, language: String) async throws -> ASRResult {
        guard !apiKey.isEmpty else { throw ASRError.apiKeyMissing }

        let wavData = PCMToWAV.convert(
            pcmData: chunk.data,
            sampleRate: Int(chunk.sampleRate),
            channels: chunk.channelCount
        )

        let boundary = "SpeecherBoundary-\(UUID().uuidString)"
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = buildMultipartBody(
            wavData: wavData,
            language: language,
            boundary: boundary
        )

        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw ASRError.networkError(URLError(.badServerResponse))
        }
        guard http.statusCode == 200 else {
            throw ASRError.invalidResponse(http.statusCode)
        }

        return try parseResponse(data: data, chunk: chunk)
    }

    // MARK: - Private

    private func buildMultipartBody(wavData: Data, language: String, boundary: String) -> Data {
        var body = Data()
        let crlf = "\r\n"
        let dash = "--"

        func field(_ name: String, value: String) {
            body += "\(dash)\(boundary)\(crlf)".data(using: .utf8)!
            body += "Content-Disposition: form-data; name=\"\(name)\"\(crlf)\(crlf)".data(using: .utf8)!
            body += "\(value)\(crlf)".data(using: .utf8)!
        }

        // audio file
        body += "\(dash)\(boundary)\(crlf)".data(using: .utf8)!
        body += "Content-Disposition: form-data; name=\"file\"; filename=\"audio.wav\"\(crlf)".data(using: .utf8)!
        body += "Content-Type: audio/wav\(crlf)\(crlf)".data(using: .utf8)!
        body += wavData
        body += crlf.data(using: .utf8)!

        field("model", value: "whisper-1")
        field("language", value: normalizeLanguageCode(language))
        field("response_format", value: "verbose_json")

        body += "\(dash)\(boundary)\(dash)\(crlf)".data(using: .utf8)!
        return body
    }

    private func parseResponse(data: Data, chunk: AudioChunk) throws -> ASRResult {
        struct Response: Decodable {
            let text: String
            let language: String?
            let duration: Double?
        }

        do {
            let decoded = try JSONDecoder().decode(Response.self, from: data)
            return ASRResult(
                text: decoded.text.trimmingCharacters(in: .whitespacesAndNewlines),
                detectedLanguage: decoded.language,
                audioDuration: decoded.duration ?? chunk.duration,
                sequenceNumber: chunk.sequenceNumber,
                isFinal: true
            )
        } catch {
            let raw = String(data: data, encoding: .utf8) ?? "<binary>"
            throw ASRError.decodingFailed(raw.prefix(200).description)
        }
    }

    /// Whisper erwartet ISO-639-1-Codes (zweistellig, z. B. „de", „en").
    private func normalizeLanguageCode(_ code: String) -> String {
        code.components(separatedBy: "-").first ?? code
    }
}
