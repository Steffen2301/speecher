import Speech
import AVFoundation
import Foundation

/// Lokale Spracherkennung über Apples SFSpeechRecognizer (on-device, kein Internet).
/// Dient als lokale Alternative zu Whisper API in Phase 1.
/// Phase 2: Wird durch Whisper.cpp ersetzt für höhere Genauigkeit und Offline-Unterstützung
/// in mehr Sprachen.
public final class AppleSpeechService: ASRService {
    public init() {}

    public func transcribe(_ chunk: AudioChunk, language: String) async throws -> ASRResult {
        let locale = Locale(identifier: appleLocale(for: language))

        guard let recognizer = SFSpeechRecognizer(locale: locale),
              recognizer.isAvailable else {
            throw ASRError.serviceUnavailable
        }

        let permission = await SFSpeechRecognizer.requestAuthorization()
        guard permission == .authorized else {
            throw ASRError.permissionDenied
        }

        guard let format = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: chunk.sampleRate,
            channels: AVAudioChannelCount(chunk.channelCount),
            interleaved: false
        ) else {
            throw ASRError.audioConversionFailed
        }

        let frameCount = AVAudioFrameCount(chunk.data.count / MemoryLayout<Float>.size)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            throw ASRError.audioConversionFailed
        }
        buffer.frameLength = frameCount

        chunk.data.withUnsafeBytes { raw in
            if let floatPtr = buffer.floatChannelData?[0],
               let source = raw.bindMemory(to: Float.self).baseAddress {
                floatPtr.initialize(from: source, count: Int(frameCount))
            }
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = SFSpeechAudioBufferRecognitionRequest()
            request.shouldReportPartialResults = false
            request.addsPunctuation = true
            request.append(buffer)
            request.endAudio()

            recognizer.recognitionTask(with: request) { result, error in
                if let error {
                    continuation.resume(throwing: ASRError.networkError(error))
                    return
                }
                guard let result, result.isFinal else { return }
                let raw = result.bestTranscription.formattedString
                let cleaned = ASRTextCleaner.clean(raw, language: language)
                continuation.resume(returning: ASRResult(
                    text: cleaned,
                    detectedLanguage: language,
                    audioDuration: chunk.duration,
                    sequenceNumber: chunk.sequenceNumber,
                    isFinal: true
                ))
            }
        }
    }

    /// Wandelt BCP-47-Kurzcode in vollständigen Apple-Locale-Identifier um.
    private func appleLocale(for language: String) -> String {
        let map: [String: String] = [
            "de": "de-DE",
            "en": "en-US",
            "fr": "fr-FR",
            "es": "es-ES",
            "it": "it-IT",
            "pt": "pt-PT",
            "nl": "nl-NL",
            "pl": "pl-PL",
            "ru": "ru-RU",
            "zh": "zh-Hans",
            "ja": "ja-JP",
            "ar": "ar-SA",
        ]
        return map[language] ?? language
    }
}

private extension SFSpeechRecognizer {
    static func requestAuthorization() async -> SFSpeechRecognizerAuthorizationStatus {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
    }
}
