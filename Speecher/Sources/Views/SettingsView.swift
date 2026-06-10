import SwiftUI
import SpeecherCore

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        TabView {
            GeneralSettingsTab()
                .tabItem { Label("Allgemein", systemImage: "gear") }
            ModelsSettingsTab()
                .tabItem { Label("Modelle", systemImage: "cpu") }
            MicrophoneSettingsTab()
                .tabItem { Label("Mikrofon", systemImage: "mic") }
        }
        .frame(width: 540, height: 420)
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
                ForEach(uiLanguages, id: \.0) { code, name in
                    Text(name).tag(code)
                }
            }
        }
        .padding(20)
    }
}

// MARK: - Models

private struct ModelsSettingsTab: View {
    @EnvironmentObject private var appState: AppState
    @State private var anthropicKey = ""
    @State private var keySaveError: String?

    var body: some View {
        Form {
            // ASR
            Section("Spracherkennung (ASR)") {
                Picker("Backend", selection: $appState.asrMode) {
                    Text("WhisperKit (lokal, on-device)").tag(AppState.ASRMode.whisperKit)
                    Text("Apple Speech (leichtgewichtig)").tag(AppState.ASRMode.appleSpeech)
                }
                .pickerStyle(.radioGroup)
            }

            if appState.asrMode == .whisperKit {
                Section("Whisper-Modell") {
                    Picker("Modell", selection: $appState.whisperModel) {
                        ForEach(WhisperKitService.WhisperModel.allCases, id: \.self) { model in
                            Text(model.displayName).tag(model)
                        }
                    }

                    HStack {
                        Spacer()
                        ModelActionButton(model: appState.whisperModel)
                            .environmentObject(appState.modelDownloadManager)
                    }

                    Text("Modelle werden einmalig heruntergeladen und lokal gespeichert. Danach kein Internet erforderlich.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Korrektur & Übersetzung
            Section("Korrektur & Übersetzung") {
                Picker("Backend", selection: $appState.correctionMode) {
                    Text("Cloud (Claude API)").tag(AppState.CorrectionMode.cloud)
                    Text("Lokal (Ollama) – Phase 2").tag(AppState.CorrectionMode.local)
                }
                .pickerStyle(.radioGroup)
            }

            if appState.correctionMode == .cloud {
                Section("Anthropic API-Key") {
                    SecureField("sk-ant-…", text: $anthropicKey)
                    Button("Speichern") { saveAnthropicKey() }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    if let error = keySaveError {
                        Text(error).foregroundStyle(.red).font(.caption)
                    }
                }
            }
        }
        .padding(20)
        .onAppear { anthropicKey = (try? KeychainManager.load(for: .anthropic)) ?? "" }
    }

    private func saveAnthropicKey() {
        do {
            if anthropicKey.isEmpty {
                KeychainManager.delete(for: .anthropic)
            } else {
                try KeychainManager.save(anthropicKey, for: .anthropic)
            }
            keySaveError = nil
        } catch {
            keySaveError = error.localizedDescription
        }
    }
}

private struct ModelActionButton: View {
    let model: WhisperKitService.WhisperModel
    @EnvironmentObject private var manager: ModelDownloadManager

    var body: some View {
        switch manager.states[model] ?? .notDownloaded {
        case .notDownloaded:
            Button("Herunterladen (\(model.approximateSizeMB) MB)") {
                manager.download(model)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)

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
                Text(msg).font(.caption).foregroundStyle(.red)
                Button("Erneut versuchen") { manager.download(model) }
                    .buttonStyle(.bordered).controlSize(.small)
            }
        }
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
                Button("Geräteliste aktualisieren") {
                    appState.audioDeviceManager.refresh()
                }
                .buttonStyle(.link)
            }
        }
        .padding(20)
    }
}
