import XCTest
import Foundation
@testable import SpeecherCore

final class AudioChunkTests: XCTestCase {
    func testEmptyDetection() {
        let chunk = AudioChunk(data: Data(), sampleRate: 16000, channelCount: 1,
                               sequenceNumber: 0, timestamp: Date(), duration: 0)
        XCTAssertTrue(chunk.isEmpty)
    }

    func testNonEmptyDetection() {
        let chunk = AudioChunk(data: Data(repeating: 0, count: 64), sampleRate: 16000,
                               channelCount: 1, sequenceNumber: 0, timestamp: Date(), duration: 0.002)
        XCTAssertFalse(chunk.isEmpty)
    }
}

final class AudioFileProcessorTests: XCTestCase {
    func testSupportedExtensions() {
        let supported = AudioFileProcessor.supportedExtensions
        XCTAssertTrue(supported.contains("mp3"))
        XCTAssertTrue(supported.contains("wav"))
        XCTAssertTrue(supported.contains("m4a"))
        XCTAssertTrue(supported.contains("flac"))
    }

    func testSegmentDurationIs30Seconds() {
        XCTAssertEqual(AudioFileProcessor.segmentDuration, 30.0)
    }

    func testUnsupportedExtensionThrows() async {
        let processor = AudioFileProcessor()
        let fakeURL = URL(fileURLWithPath: "/tmp/test.xyz")
        var didThrow = false
        do {
            for try await _ in processor.chunks(from: fakeURL) {}
        } catch {
            didThrow = true
            XCTAssertTrue(error is AudioEngineError)
        }
        XCTAssertTrue(didThrow)
    }
}

final class AudioDeviceTests: XCTestCase {
    func testDefaultDeviceUID() {
        XCTAssertEqual(AudioDevice.default.uid, "default")
    }
}

final class AudioEngineErrorTests: XCTestCase {
    func testErrorDescriptionsNonEmpty() {
        let errors: [AudioEngineError] = [
            .formatNotSupported,
            .formatConversionFailed,
            .unsupportedFileFormat("xyz"),
            .microphonePermissionDenied,
            .deviceSelectionFailed(-1),
        ]
        for error in errors {
            XCTAssertFalse(error.errorDescription?.isEmpty ?? true)
        }
    }
}
