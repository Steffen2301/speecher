import SwiftUI
import SpeecherCore

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var locale: LocalizationManager

    var body: some View {
        TabView {
            GeneralSettingsTab()
                .tabItem { Label(locale.t("settings.tab.general"), systemImage: "gear") }
            ASRSettingsTab()
                .tabItem { Label(locale.t("settings.tab.speech"), systemImage: "waveform") }
            CorrectionSettingsTab()
                .tabItem { Label(locale.t("settings.tab.correction"), systemImage: "text.badge.checkmark") }
            MicrophoneSettingsTab()
                .tabItem { Label(locale.t("settings.tab.microphone"), systemImage: "mic") }
            HotkeySettingsTab()
                .tabItem { Label("Kurzbefehl", systemImage: "keyboard") }
        }
        .frame(width: 560, height: 500)
        .environmentObject(appState)
        .environmentObject(locale)
    }
}

// MARK: - General

private struct GeneralSettingsTab: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var locale: LocalizationManager

    var body: some View {
        Form {
            Picker(locale.t("settings.ui_language"), selection: Binding(
                get: { locale.language },
                set: { locale.setLanguage($0) }
            )) {
                ForEach(LocalizationManager.supported, id: \.code) { lang in
                    Text(lang.name).tag(lang.code)
                }
            }
        }
        .padding(20)
    }
}

// MARK: - ASR

private struct ASRSettingsTab: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var locale: LocalizationManager

    private var whisperKitLabel: String {
        WhisperKitService.isSupported
            ? locale.t("settings.asr.whisperkit")
            : locale.t("settings.asr.whisperkit") + " (Apple Silicon)"
    }

    var body: some View {
        Form {
            Section(locale.t("settings.asr.section")) {
                Picker(locale.t("settings.asr.backend"), selection: $appState.asrMode) {
                    Text(locale.t("settings.asr.apple_speech")).tag(AppState.ASRMode.appleSpeech)
                    Text(whisperKitLabel).tag(AppState.ASRMode.whisperKit)
                }
                .pickerStyle(.radioGroup)

                if appState.asrMode == .whisperKit && !WhisperKitService.isSupported {
                    Label("WhisperKit erfordert Apple Silicon (M1+). Auf Intel-Macs bitte Apple Speech verwenden.",
                          systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                        .font(.caption)
                }
            }

            if appState.asrMode == .whisperKit {
                Section(locale.t("settings.asr.model_section")) {
                    Picker(locale.t("settings.asr.model_picker"), selection: $appState.whisperModel) {
                        ForEach(WhisperKitService.WhisperModel.allCases, id: \.self) {
                            Text($0.displayName).tag($0)
                        }
                    }
                    HStack {
                        Spacer()
                        ModelActionButton(model: appState.whisperModel)
                            .environmentObject(appState.modelDownloadManager)
                            .environmentObject(locale)
                    }
                    Text(locale.t("settings.asr.download_hint"))
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
    @EnvironmentObject private var locale: LocalizationManager

    var body: some View {
        switch manager.states[model] ?? .notDownloaded {
        case .notDownloaded:
            Button(locale.t("settings.asr.download_btn", model.approximateSizeMB)) {
                manager.download(model)
            }
            .buttonStyle(.borderedProminent).controlSize(.small)

        case .downloading:
            HStack(spacing: 8) {
                ProgressView().controlSize(.small)
                Text(locale.t("settings.asr.downloading")).font(.caption).foregroundStyle(.secondary)
            }

        case .downloaded:
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                Text(locale.t("settings.asr.ready")).font(.caption)
                Button(locale.t("settings.asr.delete")) { manager.delete(model) }
                    .buttonStyle(.bordered).controlSize(.small)
            }

        case .failed(let msg):
            VStack(alignment: .trailing, spacing: 4) {
                Text(msg).font(.caption).foregroundStyle(.red).lineLimit(2)
                Button(locale.t("settings.asr.retry")) { manager.download(model) }
                    .buttonStyle(.bordered).controlSize(.small)
            }
        }
    }
}

// MARK: - Correction

private struct CorrectionSettingsTab: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var locale: LocalizationManager
    @State private var anthropicKey = ""
    @State private var openAIKey = ""
    @State private var keySaveError: String?
    @State private var ollamaReachable: Bool?

    private let freeOptions = CorrectionServiceFactory.Mode.allCases.filter {  $0.isFree }
    private let paidOptions = CorrectionServiceFactory.Mode.allCases.filter { !$0.isFree }

    var body: some View {
        Form {
            Section(locale.t("settings.correction.free_section")) {
                ForEach(freeOptions, id: \.self) { modeRow($0) }
            }

            Section(locale.t("settings.correction.paid_section")) {
                ForEach(paidOptions, id: \.self) { modeRow($0) }
            }

            if appState.correctionMode == .languageTool || appState.correctionMode == .appleBuiltin {
                Text(locale.t("settings.correction.llm_hint"))
                    .font(.caption).foregroundStyle(.secondary)
                    .padding(.top, 2)
            }

            if appState.correctionMode == .ollama {
                Section(locale.t("settings.correction.ollama_section")) {
                    HStack {
                        TextField(locale.t("settings.correction.ollama_model"), text: $appState.ollamaModel)
                            .textFieldStyle(.roundedBorder)
                        TextField(locale.t("settings.correction.ollama_host"), text: $appState.ollamaHost)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 180)
                    }
                    HStack {
                        Button(locale.t("settings.correction.check_connection")) {
                            Task { await checkOllama() }
                        }
                        .buttonStyle(.bordered).controlSize(.small)

                        if let ok = ollamaReachable {
                            Image(systemName: ok ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(ok ? .green : .red)
                            Text(ok ? locale.t("settings.correction.reachable")
                                    : locale.t("settings.correction.not_reachable"))
                                .font(.caption)
                        }
                    }
                    Text(locale.t("settings.correction.ollama_hint"))
                        .font(.caption).foregroundStyle(.secondary)
                }
            }

            if appState.correctionMode == .claudeAPI {
                Section(locale.t("settings.correction.anthropic_key")) {
                    SecureField("sk-ant-…", text: $anthropicKey)
                    saveButton { try KeychainManager.save(anthropicKey, for: .anthropic) }
                }
            }

            if appState.correctionMode == .openAI {
                Section(locale.t("settings.correction.openai_key")) {
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
                .foregroundStyle(appState.correctionMode == mode ? Color.accentColor : Color.secondary)
            Text(mode.displayName).font(.body)
            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture { appState.correctionMode = mode }
    }

    private func saveButton(action: @escaping () throws -> Void) -> some View {
        Button(locale.t("settings.correction.save")) {
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

// MARK: - Hotkey

private struct HotkeySettingsTab: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        Form {
            Section("Globaler Kurzbefehl") {
                HStack {
                    Text("Aufnahme starten / stoppen")
                    Spacer()
                    HotkeyRecorderView(manager: appState.hotkeyManager)
                }

                Text("Der Kurzbefehl wirkt systemweit – auch wenn Speecher im Hintergrund läuft. Dazu ist die Accessibility-Berechtigung erforderlich.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if !AccessibilityPermission.isGranted {
                Section {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text("Accessibility-Berechtigung fehlt – globaler Kurzbefehl nicht aktiv.")
                            .font(.caption)
                        Spacer()
                        Button("Einstellungen öffnen") {
                            AccessibilityPermission.openSystemSettings()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
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
    @EnvironmentObject private var locale: LocalizationManager

    var body: some View {
        Form {
            Section(locale.t("settings.mic.section")) {
                Picker(locale.t("settings.mic.picker"), selection: Binding(
                    get: { appState.audioDeviceManager.selectedDevice },
                    set: { appState.audioDeviceManager.selectedDevice = $0 }
                )) {
                    ForEach(appState.audioDeviceManager.inputDevices) { device in
                        Text(device.name).tag(device)
                    }
                }
                Button(locale.t("settings.mic.refresh")) {
                    appState.audioDeviceManager.refresh()
                }
                .buttonStyle(.link)
            }
        }
        .padding(20)
    }
}
