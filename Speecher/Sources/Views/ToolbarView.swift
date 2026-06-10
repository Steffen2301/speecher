import SwiftUI

struct ToolbarView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var locale: LocalizationManager

    private let languages = [
        ("de", "Deutsch"), ("en", "English"), ("fr", "Français"),
        ("es", "Español"), ("it", "Italiano"), ("pt", "Português"),
        ("nl", "Nederlands"), ("pl", "Polski"), ("ru", "Русский"),
        ("zh", "中文"), ("ja", "日本語"), ("ar", "العربية"),
    ]

    var body: some View {
        HStack(spacing: 16) {
            Label(locale.t("toolbar.input"), systemImage: "mic")
                .foregroundStyle(.secondary)
                .font(.caption)

            Picker("", selection: $appState.inputLanguage) {
                ForEach(languages, id: \.0) { code, name in
                    Text(name).tag(code)
                }
            }
            .frame(width: 130)
            .labelsHidden()

            Image(systemName: "arrow.right")
                .foregroundStyle(.secondary)

            Label(locale.t("toolbar.output"), systemImage: "text.bubble")
                .foregroundStyle(.secondary)
                .font(.caption)

            Picker("", selection: $appState.outputLanguage) {
                ForEach(languages, id: \.0) { code, name in
                    Text(name).tag(code)
                }
            }
            .frame(width: 130)
            .labelsHidden()

            Spacer()

            if appState.inputLanguage != appState.outputLanguage {
                Label(locale.t("toolbar.translation_active"), systemImage: "globe")
                    .font(.caption)
                    .foregroundStyle(.blue)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}
