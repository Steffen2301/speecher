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
        Task {
            appState.statusMessage = "Verarbeite \(url.lastPathComponent) …"
            var chunkCount = 0
            do {
                for try await chunk in appState.audioFileProcessor.chunks(from: url) {
                    chunkCount += 1
                    appState.statusMessage = "Segment \(chunkCount) (\(String(format: "%.0f", chunk.duration))s) verarbeitet …"
                    // Wird in Phase 1.4 an ASRService weitergegeben
                }
                appState.statusMessage = "\(chunkCount) Segment(e) aus \(url.lastPathComponent) verarbeitet."
            } catch {
                appState.errorMessage = error.localizedDescription
                appState.statusMessage = ""
            }
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
