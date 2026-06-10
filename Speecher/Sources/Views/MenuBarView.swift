import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        VStack(spacing: 4) {
            Button {
                appState.isRecording.toggle()
            } label: {
                Label(
                    appState.isRecording ? "Aufnahme stoppen" : "Aufnahme starten",
                    systemImage: appState.isRecording ? "stop.circle" : "mic.circle"
                )
            }

            Divider()

            Button("Speecher öffnen") {
                NSApp.activate(ignoringOtherApps: true)
            }

            Button("Einstellungen …") {
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            }
            .keyboardShortcut(",", modifiers: .command)

            Divider()

            Button("Beenden") {
                NSApp.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: .command)
        }
        .padding(8)
        .frame(width: 200)
    }
}
