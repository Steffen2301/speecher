import XCTest
import Foundation
@testable import SpeecherCore

// MARK: - PCMToWAV

final class PCMToWAVTests: XCTestCase {
    func testWAVHeaderSize() {
        let pcm = Data(repeating: 0, count: 3200)   // 100ms bei 16kHz Float32
        let wav = PCMToWAV.convert(pcmData: pcm)
        XCTAssertGreaterThan(wav.count, 44)          // mindestens WAV-Header
    }

    func testWAVStartsWithRIFF() {
        let wav = PCMToWAV.convert(pcmData: Data(repeating: 0, count: 64))
        let header = String(bytes: wav.prefix(4), encoding: .ascii)
        XCTAssertEqual(header, "RIFF")
    }

    func testWAVContainsWAVEMarker() {
        let wav = PCMToWAV.convert(pcmData: Data(repeating: 0, count: 64))
        let marker = String(bytes: wav[8..<12], encoding: .ascii)
        XCTAssertEqual(marker, "WAVE")
    }

    func testEmptyPCMProducesValidHeader() {
        let wav = PCMToWAV.convert(pcmData: Data())
        XCTAssertEqual(wav.count, 44)   // Nur Header, keine Samples
    }
}

// MARK: - ASRResult

final class ASRResultTests: XCTestCase {
    func testEmptyTextIsEmpty() {
        let result = ASRResult(text: "   ", detectedLanguage: nil,
                               audioDuration: 5, sequenceNumber: 0, isFinal: true)
        XCTAssertTrue(result.isEmpty)
    }

    func testNonEmptyText() {
        let result = ASRResult(text: "Hallo Welt", detectedLanguage: "de",
                               audioDuration: 5, sequenceNumber: 0, isFinal: true)
        XCTAssertFalse(result.isEmpty)
    }
}

// MARK: - ASRError

final class ASRErrorTests: XCTestCase {
    func testAllErrorsHaveDescriptions() {
        let errors: [ASRError] = [
            .apiKeyMissing,
            .networkError(URLError(.notConnectedToInternet)),
            .invalidResponse(429),
            .decodingFailed("bad json"),
            .permissionDenied,
            .serviceUnavailable,
            .audioConversionFailed,
        ]
        for error in errors {
            XCTAssertFalse(error.errorDescription?.isEmpty ?? true, "Missing description for \(error)")
        }
    }
}

// MARK: - KeychainManager

final class KeychainManagerTests: XCTestCase {
    private let testKey = KeychainManager.Key.openAI

    override func tearDown() {
        KeychainManager.delete(for: testKey)
    }

    func testSaveAndLoad() throws {
        try KeychainManager.save("test-key-12345", for: testKey)
        let loaded = try KeychainManager.load(for: testKey)
        XCTAssertEqual(loaded, "test-key-12345")
    }

    func testLoadMissingKeyReturnsNil() throws {
        KeychainManager.delete(for: testKey)
        let loaded = try KeychainManager.load(for: testKey)
        XCTAssertNil(loaded)
    }

    func testDeleteRemovesKey() throws {
        try KeychainManager.save("temp", for: testKey)
        KeychainManager.delete(for: testKey)
        let loaded = try KeychainManager.load(for: testKey)
        XCTAssertNil(loaded)
    }
}

// MARK: - ASRServiceFactory

final class ASRServiceFactoryTests: XCTestCase {
    func testWhisperAPIServiceIsCreated() {
        let service = ASRServiceFactory.make(mode: .whisperAPI(apiKey: "key"))
        XCTAssertTrue(service is WhisperAPIService)
    }

    func testAppleSpeechServiceIsCreated() {
        let service = ASRServiceFactory.make(mode: .appleSpeech)
        XCTAssertTrue(service is AppleSpeechService)
    }
}

// MARK: - WhisperAPIService (ohne Netzwerk)

final class WhisperAPIServiceTests: XCTestCase {
    func testMissingKeyThrows() async {
        let service = WhisperAPIService(apiKey: "")
        let chunk = AudioChunk(data: Data(repeating: 0, count: 64), sampleRate: 16000,
                               channelCount: 1, sequenceNumber: 0, timestamp: Date(), duration: 0.002)
        do {
            _ = try await service.transcribe(chunk, language: "de")
            XCTFail("Sollte ASRError.apiKeyMissing werfen")
        } catch ASRError.apiKeyMissing {
            // erwartet
        } catch {
            XCTFail("Unerwarteter Fehler: \(error)")
        }
    }
}
