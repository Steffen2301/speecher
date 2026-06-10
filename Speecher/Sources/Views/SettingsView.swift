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
        .frame(width: 520, height: 380)
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

    @State private var openAIKey = ""
    @State private var anthropicKey = ""
    @State private var keySaveError: String?

    var body: some View {
        Form {
            Section("Spracherkennung (ASR)") {
                Picker("Modus", selection: $appState.asrMode) {
                    Text("Apple Speech (lokal, kostenlos)").tag(AppState.ASRMode.appleSpeech)
                    Text("Whisper API (OpenAI, Cloud)").tag(AppState.ASRMode.whisperAPI)
                }
                .pickerStyle(.radioGroup)
            }

            if appState.asrMode == .whisperAPI {
                Section("OpenAI API-Key") {
                    SecureField("sk-…", text: $openAIKey)
                    Button("Speichern") { saveKey(.openAI, value: openAIKey) }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                }
            }

            Section("Korrektur & Übersetzung") {
                Picker("Modus", selection: $appState.correctionMode) {
                    Text("Cloud (Claude API)").tag(AppState.CorrectionMode.cloud)
                    Text("Lokal (Ollama) – Phase 2").tag(AppState.CorrectionMode.local)
                }
                .pickerStyle(.radioGroup)
            }

            if appState.correctionMode == .cloud {
                Section("Anthropic API-Key") {
                    SecureField("sk-ant-…", text: $anthropicKey)
                    Button("Speichern") { saveKey(.anthropic, value: anthropicKey) }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                }
            }

            if let error = keySaveError {
                Text(error).foregroundStyle(.red).font(.caption)
            }

            Section("Lokale Whisper-Modelle (Phase 2)") {
                ForEach(ModelDownloadManager.WhisperModel.allCases, id: \.self) { model in
                    ModelRowView(model: model)
                        .environmentObject(appState.modelDownloadManager)
                }
            }
        }
        .padding(20)
        .onAppear { loadKeys() }
    }

    private func loadKeys() {
        openAIKey    = (try? KeychainManager.load(for: .openAI))    ?? ""
        anthropicKey = (try? KeychainManager.load(for: .anthropic)) ?? ""
    }

    private func saveKey(_ key: KeychainManager.Key, value: String) {
        do {
            if value.isEmpty {
                KeychainManager.delete(for: key)
            } else {
                try KeychainManager.save(value, for: key)
            }
            keySaveError = nil
        } catch {
            keySaveError = error.localizedDescription
        }
    }
}

private struct ModelRowView: View {
    let model: ModelDownloadManager.WhisperModel
    @EnvironmentObject private var manager: ModelDownloadManager

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(model.displayName).font(.body)
            }
            Spacer()
            stateView
        }
    }

    @ViewBuilder
    private var stateView: some View {
        switch manager.states[model] ?? .notDownloaded {
        case .notDownloaded:
            Button("Laden") { manager.download(model) }
                .buttonStyle(.bordered).controlSize(.small)
        case .downloading(let progress):
            ProgressView(value: progress)
                .frame(width: 80)
        case .downloaded:
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                Button("Löschen") { manager.delete(model) }
                    .buttonStyle(.bordered).controlSize(.small)
            }
        case .failed(let msg):
            Text(msg).font(.caption).foregroundStyle(.red)
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
