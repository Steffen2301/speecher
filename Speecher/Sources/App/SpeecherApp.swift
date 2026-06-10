import SwiftUI

@main
struct SpeecherApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var locale   = LocalizationManager()

    var body: some Scene {
        WindowGroup {
            Group {
                if !appState.hasCompletedOnboarding {
                    OnboardingView()
                } else {
                    ContentView()
                }
            }
            .environmentObject(appState)
            .environmentObject(locale)
            .onAppear {
                appState.locale = locale
                appState.setupHotkey()
            }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .commands { AppCommands(locale: locale) }

        MenuBarExtra("Speecher", systemImage: appState.isRecording ? "mic.circle.fill" : "mic.circle") {
            MenuBarView()
                .environmentObject(appState)
                .environmentObject(locale)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environmentObject(appState)
                .environmentObject(locale)
        }
    }
}
