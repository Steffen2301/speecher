import XCTest
@testable import SpeecherCore

final class CorrectionResultTests: XCTestCase {
    func testHasChanges() {
        let r = CorrectionResult(correctedText: "Hallo", wasTranslated: false,
                                 sourceLanguage: "de", targetLanguage: "de", backend: "Test")
        XCTAssertTrue(r.hasChanges)
    }
}

final class CorrectionErrorTests: XCTestCase {
    func testAllErrorsHaveDescriptions() {
        let errors: [CorrectionError] = [
            .apiKeyMissing(service: "Claude"),
            .networkError(URLError(.notConnectedToInternet)),
            .invalidResponse("bad json"),
            .ollamaNotRunning,
            .translationNotAvailable(reason: "macOS 14"),
            .unsupportedLanguagePair("de", "xx"),
        ]
        for e in errors {
            XCTAssertFalse(e.errorDescription?.isEmpty ?? true)
        }
    }
}

final class CorrectionServiceFactoryTests: XCTestCase {
    func testAllModesHaveDisplayNames() {
        for mode in CorrectionServiceFactory.Mode.allCases {
            XCTAssertFalse(mode.displayName.isEmpty)
        }
    }

    func testFreeModesAreFree() {
        let free: [CorrectionServiceFactory.Mode] = [.appleBuiltin, .languageTool, .ollama]
        for mode in free { XCTAssertTrue(mode.isFree) }
    }

    func testPaidModesAreNotFree() {
        let paid: [CorrectionServiceFactory.Mode] = [.claudeAPI, .openAI]
        for mode in paid { XCTAssertFalse(mode.isFree) }
    }

    func testFactoryCreatesCorrectTypes() {
        XCTAssertTrue(CorrectionServiceFactory.make(mode: .appleBuiltin)  is AppleBuiltinService)
        XCTAssertTrue(CorrectionServiceFactory.make(mode: .languageTool)  is LanguageToolService)
        XCTAssertTrue(CorrectionServiceFactory.make(mode: .ollama)        is OllamaService)
        XCTAssertTrue(CorrectionServiceFactory.make(mode: .claudeAPI)     is ClaudeAPIService)
        XCTAssertTrue(CorrectionServiceFactory.make(mode: .openAI)        is OpenAIService)
    }
}

final class OllamaServiceTests: XCTestCase {
    func testDefaultHost() {
        XCTAssertEqual(OllamaService.defaultHost.host, "localhost")
        XCTAssertEqual(OllamaService.defaultHost.port, 11434)
    }

    func testApiKeyMissingForClaude() async {
        let svc = ClaudeAPIService(apiKey: "")
        do {
            _ = try await svc.correct("Test", sourceLang: "de", targetLang: "de")
            XCTFail("Sollte CorrectionError.apiKeyMissing werfen")
        } catch CorrectionError.apiKeyMissing {
            // erwartet
        } catch {
            XCTFail("Unerwarteter Fehler: \(error)")
        }
    }

    func testApiKeyMissingForOpenAI() async {
        let svc = OpenAIService(apiKey: "")
        do {
            _ = try await svc.correct("Test", sourceLang: "de", targetLang: "de")
            XCTFail("Sollte CorrectionError.apiKeyMissing werfen")
        } catch CorrectionError.apiKeyMissing {
            // erwartet
        } catch {
            XCTFail("Unerwarteter Fehler: \(error)")
        }
    }
}
