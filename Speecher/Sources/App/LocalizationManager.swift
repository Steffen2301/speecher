import Foundation

/// Lädt Übersetzungen zur Laufzeit aus dem gewählten .lproj-Bundle.
/// Sprachumschaltung funktioniert ohne App-Neustart.
@MainActor
final class LocalizationManager: ObservableObject {
    @Published private(set) var language: String
    private var bundle: Bundle = .main

    static let supported: [(code: String, name: String)] = [
        ("de", "Deutsch"),
        ("en", "English"),
    ]

    init() {
        let saved = UserDefaults.standard.string(forKey: "uiLanguage") ?? "de"
        language = saved
        loadBundle(for: saved)
    }

    func setLanguage(_ code: String) {
        guard code != language else { return }
        language = code
        UserDefaults.standard.set(code, forKey: "uiLanguage")
        loadBundle(for: code)
    }

    /// Übersetzt einen Schlüssel in die aktuelle Sprache.
    func t(_ key: String) -> String {
        bundle.localizedString(forKey: key, value: "[\(key)]", table: "Localizable")
    }

    /// Übersetzt einen Schlüssel mit einem Integer-Argument (für %d-Formate).
    func t(_ key: String, _ n: Int) -> String {
        String(format: t(key), n)
    }

    private func loadBundle(for code: String) {
        if let path = Bundle.main.path(forResource: code, ofType: "lproj"),
           let b = Bundle(path: path) {
            bundle = b
        } else {
            bundle = .main
        }
    }
}
