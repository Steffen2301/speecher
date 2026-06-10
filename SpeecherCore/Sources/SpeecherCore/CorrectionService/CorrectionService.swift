import Foundation

/// Abstraktion für Korrektur- und Übersetzungs-Backends.
public protocol CorrectionService: Sendable {
    /// Korrigiert und übersetzt `text`.
    /// - Parameters:
    ///   - text: Rohtext aus der Transkription
    ///   - sourceLang: BCP-47-Code der Eingangssprache (z. B. „de")
    ///   - targetLang: BCP-47-Code der Ausgabesprache (gleich = nur Korrektur)
    func correct(_ text: String, sourceLang: String, targetLang: String) async throws -> CorrectionResult
}

// MARK: - Factory

public enum CorrectionServiceFactory {
    /// Alle verfügbaren Backends mit ihrer Kategorie.
    public enum Mode: String, CaseIterable, Sendable {
        // Kostenlos
        case appleBuiltin     = "appleBuiltin"
        case languageTool     = "languageTool"
        case ollama           = "ollama"
        // Kostenpflichtig
        case claudeAPI        = "claudeAPI"
        case openAI           = "openAI"

        public var displayName: String {
            switch self {
            case .appleBuiltin:  return "Apple (eingebaut) – kostenlos"
            case .languageTool:  return "LanguageTool + Apple Übersetzer – kostenlos"
            case .ollama:        return "Ollama (lokal) – kostenlos"
            case .claudeAPI:     return "Claude API (Anthropic) – kostenpflichtig"
            case .openAI:        return "OpenAI GPT – kostenpflichtig"
            }
        }

        public var isFree: Bool {
            switch self {
            case .appleBuiltin, .languageTool, .ollama: return true
            case .claudeAPI, .openAI: return false
            }
        }
    }

    public static func make(
        mode: Mode,
        ollamaModel: String = "llama3.2",
        ollamaHost: URL = URL(string: "http://localhost:11434")!,
        claudeKey: String = "",
        openAIKey: String = ""
    ) -> any CorrectionService {
        switch mode {
        case .appleBuiltin:  return AppleBuiltinService()
        case .languageTool:  return LanguageToolService()
        case .ollama:        return OllamaService(model: ollamaModel, host: ollamaHost)
        case .claudeAPI:     return ClaudeAPIService(apiKey: claudeKey)
        case .openAI:        return OpenAIService(apiKey: openAIKey)
        }
    }
}
