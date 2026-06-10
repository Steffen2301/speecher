import SwiftUI

struct TranscriptionView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: $appState.transcribedText)
                .font(.body)
                .padding(12)

            if appState.transcribedText.isEmpty {
                Text(appState.isRecording
                     ? "Aufnahme läuft …"
                     : "Drücken Sie den Aufnahme-Button oder ⌘⇧M zum Starten.")
                    .foregroundStyle(.tertiary)
                    .font(.body)
                    .padding(16)
                    .allowsHitTesting(false)
            }
        }
    }
}
