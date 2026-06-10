import SwiftUI

struct TranscriptionView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var locale: LocalizationManager

    var body: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: $appState.transcribedText)
                .font(.body)
                .padding(12)

            if appState.transcribedText.isEmpty {
                Text(appState.isRecording
                     ? locale.t("transcription.placeholder_recording")
                     : locale.t("transcription.placeholder_idle"))
                    .foregroundStyle(.tertiary)
                    .font(.body)
                    .padding(16)
                    .allowsHitTesting(false)
            }
        }
    }
}
