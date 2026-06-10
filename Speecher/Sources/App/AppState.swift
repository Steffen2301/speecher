import SwiftUI
import SpeecherCore

@MainActor
final class AppState: ObservableObject {
    @Published var isRecording = false
    @Published var transcribedText = ""
    @Published var statusMessage = ""
    @Published var errorMessage: String?

    @AppStorage("inputLanguage") var inputLanguage = "de"
    @AppStorage("outputLanguage") var outputLanguage = "de"
    @AppStorage("uiLanguage") var uiLanguage = "de"
    @AppStorage("asrMode") var asrMode = ASRMode.cloud
    @AppStorage("correctionMode") var correctionMode = CorrectionMode.cloud

    let audioRecorder = AudioRecorder(chunkDuration: 5.0)
    let audioDeviceManager = AudioDeviceManager()
    let audioFileProcessor = AudioFileProcessor()

    enum ASRMode: String, CaseIterable {
        case cloud = "cloud"
        case local = "local"
    }

    enum CorrectionMode: String, CaseIterable {
        case cloud = "cloud"
        case local = "local"
    }

    func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            Task { await startRecording() }
        }
    }

    private func startRecording() async {
        let permission = MicrophonePermission.current
        if permission == .notDetermined {
            let granted = await MicrophonePermission.request()
            guard granted else {
                errorMessage = AudioEngineError.microphonePermissionDenied.localizedDescription
                return
            }
        } else if permission == .denied {
            errorMessage = AudioEngineError.microphonePermissionDenied.localizedDescription
            return
        }

        audioRecorder.onChunk = { [weak self] chunk in
            // Wird später an ASRService weitergegeben (Phase 1.4)
            _ = chunk
            self?.statusMessage = "Chunk \(chunk.sequenceNumber) empfangen (\(String(format: "%.1f", chunk.duration))s)"
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
}
