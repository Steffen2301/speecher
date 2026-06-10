import SwiftUI

struct ControlBarView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        HStack(spacing: 12) {
            // Aufnahme-Button
            Button {
                appState.isRecording.toggle()
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

            // Datei importieren
            Button {
                // Wird in Phase 1.3 implementiert
            } label: {
                Label("Datei", systemImage: "doc.badge.plus")
            }
            .buttonStyle(.bordered)

            Spacer()

            // Statusanzeige
            if !appState.statusMessage.isEmpty {
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
            } label: {
                Label("Löschen", systemImage: "trash")
            }
            .buttonStyle(.bordered)
            .disabled(appState.transcribedText.isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}
