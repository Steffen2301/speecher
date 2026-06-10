import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var locale: LocalizationManager
    @State private var isGranted = AccessibilityPermission.isGranted

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "accessibility")
                .font(.system(size: 56))
                .foregroundStyle(.blue)

            VStack(spacing: 8) {
                Text(locale.t("onboarding.title"))
                    .font(.title2).bold()
                Text(locale.t("onboarding.description"))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }

            if isGranted {
                Label(locale.t("onboarding.granted"), systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.headline)

                Button(locale.t("onboarding.done")) {
                    appState.hasCompletedOnboarding = true
                }
                .buttonStyle(.borderedProminent)
            } else {
                VStack(spacing: 12) {
                    Button(locale.t("onboarding.open_settings")) {
                        AccessibilityPermission.openSystemSettings()
                    }
                    .buttonStyle(.borderedProminent)

                    Button(locale.t("onboarding.check")) {
                        isGranted = AccessibilityPermission.isGranted
                    }
                    .buttonStyle(.bordered)

                    Text(locale.t("onboarding.check_hint"))
                        .font(.caption).foregroundStyle(.secondary)
                }
            }

            Divider()

            Button(locale.t("onboarding.skip")) {
                appState.hasCompletedOnboarding = true
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .font(.caption)

            Text(locale.t("onboarding.skip_hint"))
                .font(.caption2).foregroundStyle(.tertiary)
        }
        .padding(32)
        .frame(width: 420)
        .onReceive(Timer.publish(every: 1.5, on: .main, in: .common).autoconnect()) { _ in
            isGranted = AccessibilityPermission.isGranted
        }
    }
}
