import XCTest
import Foundation
@testable import SpeecherCore

// MARK: - PCMToWAV

final class PCMToWAVTests: XCTestCase {
    func testWAVHeaderSize() {
        let pcm = Data(repeating: 0, count: 3200)
        let wav = PCMToWAV.convert(pcmData: pcm)
        XCTAssertGreaterThan(wav.count, 44)
    }

    func testWAVStartsWithRIFF() {
        let wav = PCMToWAV.convert(pcmData: Data(repeating: 0, count: 64))
        XCTAssertEqual(String(bytes: wav.prefix(4), encoding: .ascii), "RIFF")
    }

    func testWAVContainsWAVEMarker() {
        let wav = PCMToWAV.convert(pcmData: Data(repeating: 0, count: 64))
        XCTAssertEqual(String(bytes: wav[8..<12], encoding: .ascii), "WAVE")
    }

    func testEmptyPCMProducesHeaderOnly() {
        let wav = PCMToWAV.convert(pcmData: Data())
        XCTAssertEqual(wav.count, 44)
    }
}

// MARK: - ASRResult

final class ASRResultTests: XCTestCase {
    func testWhitespaceOnlyIsEmpty() {
        let r = ASRResult(text: "   ", detectedLanguage: nil,
                          audioDuration: 5, sequenceNumber: 0, isFinal: true)
        XCTAssertTrue(r.isEmpty)
    }

    func testNonEmptyText() {
        let r = ASRResult(text: "Hallo Welt", detectedLanguage: "de",
                          audioDuration: 5, sequenceNumber: 0, isFinal: true)
        XCTAssertFalse(r.isEmpty)
    }
}

// MARK: - ASRError

final class ASRErrorTests: XCTestCase {
    func testAllErrorsHaveDescriptions() {
        let errors: [ASRError] = [
            .modelNotLoaded("openai_whisper-base"),
            .networkError(URLError(.notConnectedToInternet)),
            .inferenceError("timeout"),
            .permissionDenied,
            .serviceUnavailable,
            .audioConversionFailed,
        ]
        for e in errors {
            XCTAssertFalse(e.errorDescription?.isEmpty ?? true, "Missing description for \(e)")
        }
    }
}

// MARK: - WhisperModel

final class WhisperModelTests: XCTestCase {
    func testAllModelsHaveIdentifiers() {
        for model in WhisperKitService.WhisperModel.allCases {
            XCTAssertTrue(model.identifier.hasPrefix("openai_whisper-"))
        }
    }

    func testAllModelsHavePositiveSize() {
        for model in WhisperKitService.WhisperModel.allCases {
            XCTAssertGreaterThan(model.approximateSizeMB, 0)
        }
    }

    func testBaseModelIdentifier() {
        XCTAssertEqual(WhisperKitService.WhisperModel.base.identifier, "openai_whisper-base")
    }
}

// MARK: - ASRServiceFactory

final class ASRServiceFactoryTests: XCTestCase {
    func testWhisperKitServiceIsCreated() {
        let service = ASRServiceFactory.make(mode: .whisperKit(model: .base))
        XCTAssertTrue(service is WhisperKitService)
    }

    func testAppleSpeechServiceIsCreated() {
        let service = ASRServiceFactory.make(mode: .appleSpeech)
        XCTAssertTrue(service is AppleSpeechService)
    }
}

// MARK: - KeychainManager

final class KeychainManagerTests: XCTestCase {
    override func tearDown() { KeychainManager.delete(for: .anthropic) }

    func testSaveAndLoad() throws {
        try KeychainManager.save("test-key-99", for: .anthropic)
        XCTAssertEqual(try KeychainManager.load(for: .anthropic), "test-key-99")
    }

    func testMissingKeyReturnsNil() throws {
        KeychainManager.delete(for: .anthropic)
        XCTAssertNil(try KeychainManager.load(for: .anthropic))
    }

    func testDeleteRemovesKey() throws {
        try KeychainManager.save("temp", for: .anthropic)
        KeychainManager.delete(for: .anthropic)
        XCTAssertNil(try KeychainManager.load(for: .anthropic))
    }
}
