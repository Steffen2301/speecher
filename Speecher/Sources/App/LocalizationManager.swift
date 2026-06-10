import Foundation

/// Laufzeit-Lokalisierung via eingebetteten Swift-Dictionaries.
/// Kein Bundle-Resource-Loading nötig – funktioniert immer zuverlässig.
@MainActor
final class LocalizationManager: ObservableObject {
    @Published private(set) var language: String

    static let supported: [(code: String, name: String)] = [
        ("de", "Deutsch"),
        ("en", "English"),
    ]

    init() {
        language = UserDefaults.standard.string(forKey: "uiLanguage") ?? "de"
    }

    func setLanguage(_ code: String) {
        guard code != language else { return }
        language = code
        UserDefaults.standard.set(code, forKey: "uiLanguage")
    }

    func t(_ key: String) -> String {
        let table = language == "en" ? Self.en : Self.de
        return table[key] ?? Self.de[key] ?? "[\(key)]"
    }

    func t(_ key: String, _ n: Int) -> String {
        String(format: t(key), n)
    }

    // MARK: - Deutsch

    private static let de: [String: String] = [
        // Toolbar
        "toolbar.input":              "Eingang",
        "toolbar.output":             "Ausgang",
        "toolbar.translation_active": "Übersetzung aktiv",
        // Transcription
        "transcription.placeholder_idle":      "Aufnahme-Button drücken oder ⌘⇧M zum Starten.",
        "transcription.placeholder_recording": "Aufnahme läuft …",
        // Control Bar
        "control.record":      "Aufnahme",
        "control.stop":        "Stopp",
        "control.import_file": "Datei",
        "control.copy":        "Kopieren",
        "control.clear":       "Löschen",
        "control.loading":     "Wird geladen …",
        // File Panel
        "file_panel.title":   "Audiodatei öffnen",
        "file_panel.message": "Unterstützte Formate: MP3, M4A, WAV, AIFF, FLAC, CAF, MP4",
        // Output Badge
        "output.at_cursor":  "An Cursor",
        "output.inserted":   "Eingefügt",
        "output.clipboard":  "Zwischenablage",
        "output.textfield":  "Textfeld",
        // Menu Bar
        "menubar.start_recording": "Aufnahme starten",
        "menubar.stop_recording":  "Aufnahme stoppen",
        "menubar.open_speecher":   "Speecher öffnen",
        "menubar.settings":        "Einstellungen …",
        "menubar.quit":            "Beenden",
        // Onboarding
        "onboarding.title":       "Bedienungshilfen erlauben",
        "onboarding.description": "Speecher benötigt Zugriff auf die Bedienungshilfen, um Text direkt an der Cursor-Position in anderen Apps einzufügen (Mail, Word, Pages …).",
        "onboarding.granted":     "Berechtigung erteilt",
        "onboarding.done":        "Fertig",
        "onboarding.open_settings": "Systemeinstellungen öffnen",
        "onboarding.check":       "Prüfen",
        "onboarding.check_hint":  "Nach dem Erlauben bitte \u{201E}Prüfen\u{201C} drücken.",
        "onboarding.skip":        "Ohne Accessibility fortfahren",
        "onboarding.skip_hint":   "Ohne Berechtigung wird Text in die Zwischenablage kopiert.",
        // Settings Tabs
        "settings.tab.general":    "Allgemein",
        "settings.tab.speech":     "Sprache",
        "settings.tab.correction": "Korrektur",
        "settings.tab.microphone": "Mikrofon",
        "settings.tab.hotkey":     "Kurzbefehl",
        // Settings – General
        "settings.ui_language": "Oberflächen-Sprache",
        // Settings – ASR
        "settings.asr.section":       "Spracherkennung",
        "settings.asr.backend":       "Backend",
        "settings.asr.whisperkit":    "WhisperKit (lokal, on-device)",
        "settings.asr.apple_speech":  "Apple Speech (leichtgewichtig)",
        "settings.asr.model_section": "Whisper-Modell",
        "settings.asr.model_picker":  "Modell",
        "settings.asr.download_hint": "Einmalig herunterladen – danach vollständig offline.",
        "settings.asr.ready":         "Bereit",
        "settings.asr.downloading":   "Wird geladen …",
        "settings.asr.delete":        "Löschen",
        "settings.asr.retry":         "Erneut versuchen",
        "settings.asr.download_btn":  "Laden (%d MB)",
        // Settings – Correction
        "settings.correction.free_section":    "Kostenlose Backends",
        "settings.correction.paid_section":    "Kostenpflichtige Backends",
        "settings.correction.ollama_section":  "Ollama-Einstellungen",
        "settings.correction.ollama_model":    "Modell",
        "settings.correction.ollama_host":     "Host",
        "settings.correction.check_connection":"Verbindung prüfen",
        "settings.correction.reachable":       "Erreichbar",
        "settings.correction.not_reachable":   "Nicht erreichbar",
        "settings.correction.ollama_hint":     "Installieren: https://ollama.com  •  Laden: ollama pull llama3.2",
        "settings.correction.llm_hint":        "Für beste Bereinigung sinnloser Wörter: Ollama (lokal) oder Claude API verwenden.",
        "settings.correction.anthropic_key":   "Anthropic API-Key",
        "settings.correction.openai_key":      "OpenAI API-Key",
        "settings.correction.save":            "Speichern",
        // Settings – Microphone
        "settings.mic.section": "Eingabegerät",
        "settings.mic.picker":  "Mikrofon",
        "settings.mic.refresh": "Geräteliste aktualisieren",
        // App Commands
        "commands.recording_menu": "Aufnahme",
        "commands.toggle":         "Aufnahme starten / stoppen",
        // Status
        "status.loading_model":      "Lade Modell …",
        "status.recording":          "Aufnahme läuft …",
        "status.no_speech":          "Keine Sprache erkannt.",
        "status.inserted_cursor":    "✓ An Cursor eingefügt",
        "status.inserted_paste":     "✓ Eingefügt (Cmd+V)",
        "status.clipboard_hint":     "In Zwischenablage · ⌘V zum Einfügen",
        "status.no_target":          "Kein Ziel gespeichert · Text im Textfeld",
        "status.processing_segment": "Segment %d wird verarbeitet …",
        "status.done_segments":      "%d Segment(e) fertig.",
    ]

    // MARK: - English

    private static let en: [String: String] = [
        // Toolbar
        "toolbar.input":              "Input",
        "toolbar.output":             "Output",
        "toolbar.translation_active": "Translation active",
        // Transcription
        "transcription.placeholder_idle":      "Press the Record button or ⌘⇧M to start.",
        "transcription.placeholder_recording": "Recording…",
        // Control Bar
        "control.record":      "Record",
        "control.stop":        "Stop",
        "control.import_file": "File",
        "control.copy":        "Copy",
        "control.clear":       "Clear",
        "control.loading":     "Loading…",
        // File Panel
        "file_panel.title":   "Open Audio File",
        "file_panel.message": "Supported formats: MP3, M4A, WAV, AIFF, FLAC, CAF, MP4",
        // Output Badge
        "output.at_cursor":  "At Cursor",
        "output.inserted":   "Inserted",
        "output.clipboard":  "Clipboard",
        "output.textfield":  "Text Field",
        // Menu Bar
        "menubar.start_recording": "Start Recording",
        "menubar.stop_recording":  "Stop Recording",
        "menubar.open_speecher":   "Open Speecher",
        "menubar.settings":        "Settings…",
        "menubar.quit":            "Quit",
        // Onboarding
        "onboarding.title":       "Allow Accessibility Access",
        "onboarding.description": "Speecher needs Accessibility access to insert text directly at the cursor position in other apps (Mail, Word, Pages…).",
        "onboarding.granted":     "Permission Granted",
        "onboarding.done":        "Done",
        "onboarding.open_settings": "Open System Settings",
        "onboarding.check":       "Check",
        "onboarding.check_hint":  "After allowing, press \"Check\".",
        "onboarding.skip":        "Continue without Accessibility",
        "onboarding.skip_hint":   "Without permission, text will be copied to the clipboard.",
        // Settings Tabs
        "settings.tab.general":    "General",
        "settings.tab.speech":     "Speech",
        "settings.tab.correction": "Correction",
        "settings.tab.microphone": "Microphone",
        "settings.tab.hotkey":     "Shortcut",
        // Settings – General
        "settings.ui_language": "Interface Language",
        // Settings – ASR
        "settings.asr.section":       "Speech Recognition",
        "settings.asr.backend":       "Backend",
        "settings.asr.whisperkit":    "WhisperKit (local, on-device)",
        "settings.asr.apple_speech":  "Apple Speech (lightweight)",
        "settings.asr.model_section": "Whisper Model",
        "settings.asr.model_picker":  "Model",
        "settings.asr.download_hint": "Download once – then fully offline.",
        "settings.asr.ready":         "Ready",
        "settings.asr.downloading":   "Downloading…",
        "settings.asr.delete":        "Delete",
        "settings.asr.retry":         "Retry",
        "settings.asr.download_btn":  "Download (%d MB)",
        // Settings – Correction
        "settings.correction.free_section":    "Free Backends",
        "settings.correction.paid_section":    "Paid Backends",
        "settings.correction.ollama_section":  "Ollama Settings",
        "settings.correction.ollama_model":    "Model",
        "settings.correction.ollama_host":     "Host",
        "settings.correction.check_connection":"Check Connection",
        "settings.correction.reachable":       "Reachable",
        "settings.correction.not_reachable":   "Not Reachable",
        "settings.correction.ollama_hint":     "Install: https://ollama.com  •  Load: ollama pull llama3.2",
        "settings.correction.llm_hint":        "For best removal of nonsensical words: use Ollama (local) or Claude API.",
        "settings.correction.anthropic_key":   "Anthropic API Key",
        "settings.correction.openai_key":      "OpenAI API Key",
        "settings.correction.save":            "Save",
        // Settings – Microphone
        "settings.mic.section": "Input Device",
        "settings.mic.picker":  "Microphone",
        "settings.mic.refresh": "Refresh Device List",
        // App Commands
        "commands.recording_menu": "Recording",
        "commands.toggle":         "Start / Stop Recording",
        // Status
        "status.loading_model":      "Loading model…",
        "status.recording":          "Recording…",
        "status.no_speech":          "No speech detected.",
        "status.inserted_cursor":    "✓ Inserted at cursor",
        "status.inserted_paste":     "✓ Inserted (Cmd+V)",
        "status.clipboard_hint":     "In Clipboard · ⌘V to Paste",
        "status.no_target":          "No target saved · Text in field",
        "status.processing_segment": "Processing segment %d…",
        "status.done_segments":      "%d segment(s) complete.",
    ]
}
