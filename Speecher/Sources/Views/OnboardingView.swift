import SwiftUI

/// Erklärt die Accessibility-Berechtigung und führt den Nutzer zur Systemeinstellung.
struct OnboardingView: View {
    @EnvironmentObject private var appState: AppState
    @State private var isGranted = AccessibilityPermission.isGranted

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "accessibility")
                .font(.system(size: 56))
                .foregroundStyle(.blue)

            VStack(spacing: 8) {
                Text("Bedienungshilfen erlauben")
                    .font(.title2).bold()
                Text("Speecher benötigt Zugriff auf die Bedienungshilfen, um Text direkt an der Cursor-Position in anderen Apps einzufügen (Mail, Word, Pages …).")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }

            if isGranted {
                Label("Berechtigung erteilt", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.headline)

                Button("Fertig") { appState.hasCompletedOnboarding = true }
                    .buttonStyle(.borderedProminent)
            } else {
                VStack(spacing: 12) {
                    Button("Systemeinstellungen öffnen") {
                        AccessibilityPermission.openSystemSettings()
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Prüfen") {
                        isGranted = AccessibilityPermission.isGranted
                    }
                    .buttonStyle(.bordered)

                    Text("Nach dem Erlauben bitte „Prüfen" drücken.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }

            Divider()

            Button("Ohne Accessibility fortfahren") {
                appState.hasCompletedOnboarding = true
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .font(.caption)

            Text("Ohne Berechtigung wird Text in die Zwischenablage kopiert.")
                .font(.caption2).foregroundStyle(.tertiary)
        }
        .padding(32)
        .frame(width: 420)
        .onReceive(Timer.publish(every: 1.5, on: .main, in: .common).autoconnect()) { _ in
            isGranted = AccessibilityPermission.isGranted
        }
    }
}
