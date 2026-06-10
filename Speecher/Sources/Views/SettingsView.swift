import SwiftUI
import SpeecherCore

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        TabView {
            GeneralSettingsTab()
                .tabItem { Label("Allgemein", systemImage: "gear") }
            ASRSettingsTab()
                .tabItem { Label("Sprache", systemImage: "waveform") }
            CorrectionSettingsTab()
                .tabItem { Label("Korrektur", systemImage: "text.badge.checkmark") }
            MicrophoneSettingsTab()
                .tabItem { Label("Mikrofon", systemImage: "mic") }
        }
        .frame(width: 560, height: 460)
        .environmentObject(appState)
    }
}

// MARK: - General

private struct GeneralSettingsTab: View {
    @EnvironmentObject private var appState: AppState
    private let uiLanguages = [("de", "Deutsch"), ("en", "English")]

    var body: some View {
        Form {
            Picker("Oberflächen-Sprache", selection: $appState.uiLanguage) {
                ForEach(uiLanguages, id: \.0) { Text($1).tag($0) }
            }
        }
        .padding(20)
    }
}

// MARK: - ASR

private struct ASRSettingsTab: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        Form {
            Section("Spracherkennung") {
                Picker("Backend", selection: $appState.asrMode) {
                    Text("WhisperKit (lokal, on-device)").tag(AppState.ASRMode.whisperKit)
                    Text("Apple Speech (leichtgewichtig)").tag(AppState.ASRMode.appleSpeech)
                }
                .pickerStyle(.radioGroup)
            }

            if appState.asrMode == .whisperKit {
                Section("Whisper-Modell") {
                    Picker("Modell", selection: $appState.whisperModel) {
                        ForEach(WhisperKitService.WhisperModel.allCases, id: \.self) {
                            Text($0.displayName).tag($0)
                        }
                    }
                    HStack {
                        Spacer()
                        ModelActionButton(model: appState.whisperModel)
                            .environmentObject(appState.modelDownloadManager)
                    }
                    Text("Einmalig herunterladen – danach vollständig offline.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
        }
        .padding(20)
    }
}

private struct ModelActionButton: View {
    let model: WhisperKitService.WhisperModel
    @EnvironmentObject private var manager: ModelDownloadManager

    var body: some View {
        switch manager.states[model] ?? .notDownloaded {
        case .notDownloaded:
            Button("Laden (\(model.approximateSizeMB) MB)") { manager.download(model) }
                .buttonStyle(.borderedProminent).controlSize(.small)
        case .downloading:
            HStack(spacing: 8) {
                ProgressView().controlSize(.small)
                Text("Wird geladen …").font(.caption).foregroundStyle(.secondary)
            }
        case .downloaded:
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                Text("Bereit").font(.caption)
                Button("Löschen") { manager.delete(model) }
                    .buttonStyle(.bordered).controlSize(.small)
            }
        case .failed(let msg):
            VStack(alignment: .trailing, spacing: 4) {
                Text(msg).font(.caption).foregroundStyle(.red).lineLimit(2)
                Button("Erneut versuchen") { manager.download(model) }
                    .buttonStyle(.bordered).controlSize(.small)
            }
        }
    }
}

// MARK: - Correction

private struct CorrectionSettingsTab: View {
    @EnvironmentObject private var appState: AppState
    @State private var anthropicKey = ""
    @State private var openAIKey = ""
    @State private var keySaveError: String?
    @State private var ollamaReachable: Bool? = nil

    private let freeOptions   = CorrectionServiceFactory.Mode.allCases.filter {  $0.isFree }
    private let paidOptions   = CorrectionServiceFactory.Mode.allCases.filter { !$0.isFree }

    var body: some View {
        Form {
            Section("Kostenlose Backends") {
                ForEach(freeOptions, id: \.self) { mode in
                    modeRow(mode)
                }
            }

            Section("Kostenpflichtige Backends") {
                ForEach(paidOptions, id: \.self) { mode in
                    modeRow(mode)
                }
            }

            // Ollama-Einstellungen
            if appState.correctionMode == .ollama {
                Section("Ollama-Einstellungen") {
                    HStack {
                        TextField("Modell", text: $appState.ollamaModel)
                            .textFieldStyle(.roundedBorder)
                        TextField("Host", text: $appState.ollamaHost)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 180)
                    }
                    HStack {
                        Button("Verbindung prüfen") { Task { await checkOllama() } }
                            .buttonStyle(.bordered).controlSize(.small)
                        if let ok = ollamaReachable {
                            Image(systemName: ok ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(ok ? .green : .red)
                            Text(ok ? "Erreichbar" : "Nicht erreichbar")
                                .font(.caption)
                        }
                    }
                    Text("Installieren: https://ollama.com  •  Modell laden: ollama pull llama3.2")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }

            // API-Keys
            if appState.correctionMode == .claudeAPI {
                Section("Anthropic API-Key") {
                    SecureField("sk-ant-…", text: $anthropicKey)
                    saveButton { try KeychainManager.save(anthropicKey, for: .anthropic) }
                }
            }
            if appState.correctionMode == .openAI {
                Section("OpenAI API-Key") {
                    SecureField("sk-…", text: $openAIKey)
                    saveButton { try KeychainManager.save(openAIKey, for: .openAI) }
                }
            }

            if let error = keySaveError {
                Text(error).foregroundStyle(.red).font(.caption)
            }
        }
        .padding(20)
        .onAppear {
            anthropicKey = (try? KeychainManager.load(for: .anthropic)) ?? ""
            openAIKey    = (try? KeychainManager.load(for: .openAI))    ?? ""
        }
    }

    private func modeRow(_ mode: CorrectionServiceFactory.Mode) -> some View {
        HStack {
            Image(systemName: appState.correctionMode == mode ? "largecircle.fill.circle" : "circle")
                .foregroundStyle(appState.correctionMode == mode ? .accentColor : .secondary)
            VStack(alignment: .leading, spacing: 1) {
                Text(mode.displayName).font(.body)
            }
            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture { appState.correctionMode = mode }
    }

    private func saveButton(action: @escaping () throws -> Void) -> some View {
        Button("Speichern") {
            do { try action(); keySaveError = nil }
            catch { keySaveError = error.localizedDescription }
        }
        .buttonStyle(.borderedProminent).controlSize(.small)
    }

    private func checkOllama() async {
        let svc = OllamaService(
            model: appState.ollamaModel,
            host: URL(string: appState.ollamaHost) ?? OllamaService.defaultHost
        )
        ollamaReachable = await svc.isReachable()
    }
}

// MARK: - Microphone

private struct MicrophoneSettingsTab: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        Form {
            Section("Eingabegerät") {
                Picker("Mikrofon", selection: $appState.audioDeviceManager.selectedDevice) {
                    ForEach(appState.audioDeviceManager.inputDevices) { device in
                        Text(device.name).tag(device)
                    }
                }
                Button("Geräteliste aktualisieren") { appState.audioDeviceManager.refresh() }
                    .buttonStyle(.link)
            }
        }
        .padding(20)
    }
}
