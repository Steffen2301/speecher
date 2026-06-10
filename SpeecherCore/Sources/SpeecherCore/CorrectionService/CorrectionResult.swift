import Foundation

public struct CorrectionResult: Sendable {
    public let correctedText: String
    public let wasTranslated: Bool
    public let sourceLanguage: String
    public let targetLanguage: String
    public let backend: String        // z. B. „Ollama (llama3.2)", „LanguageTool"

    public var hasChanges: Bool { correctedText != "" }
}
