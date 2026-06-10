import SwiftUI
import SpeecherCore

@MainActor
final class AppState: ObservableObject {
    @Published var isRecording = false
    @Published var transcribedText = ""
    @Published var statusMessage = ""
    @Published var errorMessage: String?
    @Published var isProcessing = false

    @AppStorage("inputLanguage")        var inputLanguage        = "de"
    @AppStorage("outputLanguage")       var outputLanguage       = "de"
    @AppStorage("uiLanguage")           var uiLanguage           = "de"
    @AppStorage("asrMode")              var asrMode              = ASRMode.whisperKit
    @AppStorage("whisperModel")         var whisperModelRaw      = WhisperKitService.WhisperModel.base.rawValue
    @AppStorage("correctionMode")       var correctionModeRaw    = CorrectionServiceFactory.Mode.appleBuiltin.rawValue
    @AppStorage("ollamaModel")          var ollamaModel          = "llama3.2"
    @AppStorage("ollamaHost")           var ollamaHost           = "http://localhost:11434"

    var whisperModel: WhisperKitService.WhisperModel {
        get { .init(rawValue: whisperModelRaw) ?? .base }
        set { whisperModelRaw = newValue.rawValue }
    }

    var correctionMode: CorrectionServiceFactory.Mode {
        get { .init(rawValue: correctionModeRaw) ?? .appleBuiltin }
        set { correctionModeRaw = newValue.rawValue }
    }

    let audioRecorder        = AudioRecorder(chunkDuration: 5.0)
    let audioDeviceManager   = AudioDeviceManager()
    let audioFileProcessor   = AudioFileProcessor()
    let modelDownloadManager = ModelDownloadManager()

    enum ASRMode: String, CaseIterable {
        case whisperKit  = "whisperKit"
        case appleSpeech = "appleSpeech"
    }

    // MARK: - Recording

    func toggleRecording() {
        isRecording ? stopRecording() : Task { await startRecording() }
    }

    private func startRecording() async {
        guard await ensureMicrophonePermission() else { return }

        statusMessage = "Lade Modell …"
        let asrService         = makeASRService()
        let correctionService  = makeCorrectionService()

        audioRecorder.onChunk = { [weak self] chunk in
            Task { [weak self] in
                await self?.handleChunk(chunk, asr: asrService, correction: correctionService)
            }
        }

        do {
            try audioDeviceManager.applySelection()
            try audioRecorder.start()
            isRecording = true
            statusMessage = "Aufnahme läuft …"
        } catch {
            errorMessage = error.localizedDescription
            statusMessage = ""
        }
    }

    private func stopRecording() {
        audioRecorder.stop()
        isRecording = false
        statusMessage = ""
    }

    // MARK: - Pipeline: Chunk → ASR → Korrektur → Text

    private func handleChunk(
        _ chunk: AudioChunk,
        asr: any ASRService,
        correction: any CorrectionService
    ) async {
        isProcessing = true
        do {
            let asrResult = try await asr.transcribe(chunk, language: inputLanguage)
            guard !asrResult.isEmpty else { isProcessing = false; return }

            let corrResult = try await correction.correct(
                asrResult.text,
                sourceLang: inputLanguage,
                targetLang: outputLanguage
            )

            if !transcribedText.isEmpty { transcribedText += " " }
            transcribedText += corrResult.correctedText
            statusMessage = corrResult.backend
        } catch {
            errorMessage = error.localizedDescription
        }
        isProcessing = false
    }

    func transcribeFile(url: URL) {
        Task {
            isProcessing = true
            statusMessage = "Lade Modell …"
            let asrService        = makeASRService()
            let correctionService = makeCorrectionService()
            var count = 0
            do {
                for try await chunk in audioFileProcessor.chunks(from: url) {
                    let asr = try await asrService.transcribe(chunk, language: inputLanguage)
                    if asr.isEmpty { continue }
                    let corr = try await correctionService.correct(
                        asr.text, sourceLang: inputLanguage, targetLang: outputLanguage
                    )
                    if !transcribedText.isEmpty { transcribedText += " " }
                    transcribedText += corr.correctedText
                    count += 1
                    statusMessage = "Segment \(count) – \(corr.backend)"
                }
                statusMessage = "\(count) Segment(e) fertig."
            } catch {
                errorMessage = error.localizedDescription
                statusMessage = ""
            }
            isProcessing = false
        }
    }

    // MARK: - Factory

    func makeASRService() -> any ASRService {
        switch asrMode {
        case .whisperKit:
            return ASRServiceFactory.make(mode: .whisperKit(model: whisperModel))
        case .appleSpeech:
            return ASRServiceFactory.make(mode: .appleSpeech)
        }
    }

    func makeCorrectionService() -> any CorrectionService {
        let ollamaURL = URL(string: ollamaHost) ?? OllamaService.defaultHost
        return CorrectionServiceFactory.make(
            mode: correctionMode,
            ollamaModel: ollamaModel,
            ollamaHost: ollamaURL,
            claudeKey: (try? KeychainManager.load(for: .anthropic)) ?? "",
            openAIKey: (try? KeychainManager.load(for: .openAI)) ?? ""
        )
    }

    // MARK: - Permission

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
