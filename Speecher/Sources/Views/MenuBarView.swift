import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var locale: LocalizationManager

    var body: some View {
        VStack(spacing: 4) {
            Button {
                appState.toggleRecording()
            } label: {
                Label(
                    appState.isRecording
                        ? locale.t("menubar.stop_recording")
                        : locale.t("menubar.start_recording"),
                    systemImage: appState.isRecording ? "stop.circle" : "mic.circle"
                )
            }

            Divider()

            Button(locale.t("menubar.open_speecher")) {
                NSApp.activate(ignoringOtherApps: true)
            }

            Button(locale.t("menubar.settings")) {
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            }
            .keyboardShortcut(",", modifiers: .command)

            Divider()

            Button(locale.t("menubar.quit")) {
                NSApp.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: .command)
        }
        .padding(8)
        .frame(width: 200)
    }
}
