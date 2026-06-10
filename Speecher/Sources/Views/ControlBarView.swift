import SwiftUI
import SpeecherCore

struct ControlBarView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        HStack(spacing: 12) {
            // Aufnahme-Button
            Button {
                appState.toggleRecording()
            } label: {
                Label(
                    appState.isRecording ? "Stopp" : "Aufnahme",
                    systemImage: appState.isRecording ? "stop.circle.fill" : "mic.circle.fill"
                )
                .foregroundStyle(appState.isRecording ? .red : .accentColor)
                .font(.title3)
            }
            .buttonStyle(.plain)
            .keyboardShortcut("m", modifiers: [.command, .shift])

            // VU-Meter (nur während Aufnahme)
            if appState.isRecording {
                LevelMeterView(level: appState.audioRecorder.inputLevel)
                    .frame(width: 80, height: 14)
                    .transition(.opacity)
            }

            // Datei importieren
            Button {
                openFileImport()
            } label: {
                Label("Datei", systemImage: "doc.badge.plus")
            }
            .buttonStyle(.bordered)

            Spacer()

            // Verarbeitungs-Indikator
            if appState.isProcessing {
                ProgressView().scaleEffect(0.7).padding(.trailing, 4)
            }

            // Output-Indikator
            if let result = appState.lastOutputResult, !appState.isRecording {
                OutputResultBadge(result: result)
                    .transition(.opacity)
            }

            // Statusanzeige
            if let error = appState.errorMessage {
                Label(error, systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(.red)
                    .lineLimit(1)
            } else if !appState.statusMessage.isEmpty {
                Text(appState.statusMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Kopieren
            Button {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(appState.transcribedText, forType: .string)
            } label: {
                Label("Kopieren", systemImage: "doc.on.doc")
            }
            .buttonStyle(.bordered)
            .disabled(appState.transcribedText.isEmpty)

            // Löschen
            Button {
                appState.transcribedText = ""
                appState.errorMessage = nil
            } label: {
                Label("Löschen", systemImage: "trash")
            }
            .buttonStyle(.bordered)
            .disabled(appState.transcribedText.isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .animation(.easeInOut(duration: 0.2), value: appState.isRecording)
    }

    private func openFileImport() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = []
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.title = "Audiodatei öffnen"
        panel.message = "Unterstützte Formate: MP3, M4A, WAV, AIFF, FLAC, CAF, MP4"

        if panel.runModal() == .OK, let url = panel.url {
            processAudioFile(url: url)
        }
    }

    private func processAudioFile(url: URL) {
        appState.transcribeFile(url: url)
    }
}

// MARK: - Output-Indikator

private struct OutputResultBadge: View {
    let result: OutputResult

    var body: some View {
        Label(label, systemImage: icon)
            .font(.caption)
            .foregroundStyle(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.12), in: Capsule())
    }

    private var icon: String {
        switch result {
        case .insertedAtCursor:    return "text.cursor"
        case .pastedViaSimulation: return "doc.on.clipboard"
        case .copiedToClipboard:   return "clipboard"
        case .noTargetSaved:       return "textformat"
        }
    }

    private var label: String {
        switch result {
        case .insertedAtCursor:    return "An Cursor"
        case .pastedViaSimulation: return "Eingefügt"
        case .copiedToClipboard:   return "Zwischenablage"
        case .noTargetSaved:       return "Textfeld"
        }
    }

    private var color: Color {
        switch result {
        case .insertedAtCursor, .pastedViaSimulation: return .green
        case .copiedToClipboard:                      return .orange
        case .noTargetSaved:                          return .secondary
        }
    }
}

// MARK: - VU-Meter

private struct LevelMeterView: View {
    let level: Float   // 0.0 – 1.0

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(.quaternary)
                RoundedRectangle(cornerRadius: 3)
                    .fill(meterColor)
                    .frame(width: geo.size.width * CGFloat(level))
            }
        }
    }

    private var meterColor: Color {
        switch level {
        case 0..<0.6:  return .green
        case 0.6..<0.85: return .yellow
        default:       return .red
        }
    }
}
