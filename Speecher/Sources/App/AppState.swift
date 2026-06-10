import SwiftUI
import SpeecherCore

@MainActor
final class AppState: ObservableObject {
    @Published var isRecording = false
    @Published var transcribedText = ""
    @Published var statusMessage = ""
    @Published var errorMessage: String?
    @Published var isProcessing = false

    @AppStorage("inputLanguage") var inputLanguage = "de"
    @AppStorage("outputLanguage") var outputLanguage = "de"
    @AppStorage("uiLanguage") var uiLanguage = "de"
    @AppStorage("asrMode") var asrMode = ASRMode.appleSpeech
    @AppStorage("correctionMode") var correctionMode = CorrectionMode.cloud

    let audioRecorder = AudioRecorder(chunkDuration: 5.0)
    let audioDeviceManager = AudioDeviceManager()
    let audioFileProcessor = AudioFileProcessor()
    let modelDownloadManager = ModelDownloadManager()

    enum ASRMode: String, CaseIterable {
        case whisperAPI  = "whisperAPI"
        case appleSpeech = "appleSpeech"
    }

    enum CorrectionMode: String, CaseIterable {
        case cloud = "cloud"
        case local = "local"
    }

    // MARK: - Recording

    func toggleRecording() {
        isRecording ? stopRecording() : Task { await startRecording() }
    }

    private func startRecording() async {
        guard await ensureMicrophonePermission() else { return }

        let service = makeASRService()
        audioRecorder.onChunk = { [weak self] chunk in
            Task { [weak self] in
                await self?.handleChunk(chunk, service: service)
            }
        }

        do {
            try audioDeviceManager.applySelection()
            try audioRecorder.start()
            isRecording = true
            statusMessage = "Aufnahme läuft …"
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func stopRecording() {
        audioRecorder.stop()
        isRecording = false
        statusMessage = ""
    }

    // MARK: - ASR

    private func handleChunk(_ chunk: AudioChunk, service: any ASRService) async {
        isProcessing = true
        do {
            let result = try await service.transcribe(chunk, language: inputLanguage)
            if !result.isEmpty {
                if !transcribedText.isEmpty { transcribedText += " " }
                transcribedText += result.text
                statusMessage = "Chunk \(result.sequenceNumber + 1) transkribiert"
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isProcessing = false
    }

    func transcribeFile(url: URL) {
        Task {
            isProcessing = true
            statusMessage = "Verarbeite \(url.lastPathComponent) …"
            let service = makeASRService()
            var chunkCount = 0
            do {
                for try await chunk in audioFileProcessor.chunks(from: url) {
                    let result = try await service.transcribe(chunk, language: inputLanguage)
                    if !result.isEmpty {
                        if !transcribedText.isEmpty { transcribedText += " " }
                        transcribedText += result.text
                    }
                    chunkCount += 1
                    statusMessage = "Segment \(chunkCount) verarbeitet …"
                }
                statusMessage = "\(chunkCount) Segment(e) aus \(url.lastPathComponent) fertig."
            } catch {
                errorMessage = error.localizedDescription
                statusMessage = ""
            }
            isProcessing = false
        }
    }

    // MARK: - Helper

    private func makeASRService() -> any ASRService {
        switch asrMode {
        case .whisperAPI:
            let key = (try? KeychainManager.load(for: .openAI)) ?? ""
            return ASRServiceFactory.make(mode: .whisperAPI(apiKey: key))
        case .appleSpeech:
            return ASRServiceFactory.make(mode: .appleSpeech)
        }
    }

    private func ensureMicrophonePermission() async -> Bool {
        switch MicrophonePermission.current {
        case .granted: return true
        case .notDetermined:
            let granted = await MicrophonePermission.request()
            if !granted { errorMessage = AudioEngineError.microphonePermissionDenied.localizedDescription }
            return granted
        case .denied:
            errorMessage = AudioEngineError.microphonePermissionDenied.localizedDescription
            return false
        }
    }
}
