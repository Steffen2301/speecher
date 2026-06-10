import SwiftUI

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
        .frame(width: 480, height: 320)
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

    var body: some View {
        Form {
            Section("Spracherkennung (ASR)") {
                Picker("Modus", selection: $appState.asrMode) {
                    Text("Cloud (Whisper API)").tag(AppState.ASRMode.cloud)
                    Text("Lokal (Whisper.cpp)").tag(AppState.ASRMode.local)
                }
                .pickerStyle(.radioGroup)
            }

            Section("Korrektur & Übersetzung") {
                Picker("Modus", selection: $appState.correctionMode) {
                    Text("Cloud (Claude API)").tag(AppState.CorrectionMode.cloud)
                    Text("Lokal (Ollama)").tag(AppState.CorrectionMode.local)
                }
                .pickerStyle(.radioGroup)
            }

            if appState.asrMode == .cloud || appState.correctionMode == .cloud {
                Section("API-Keys") {
                    if appState.asrMode == .cloud {
                        SecureField("OpenAI API-Key (Whisper)", text: .constant(""))
                    }
                    if appState.correctionMode == .cloud {
                        SecureField("Anthropic API-Key (Claude)", text: .constant(""))
                    }
                }
            }
        }
        .padding(20)
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
