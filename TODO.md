# Speecher – Todo-Liste

**Letzte Aktualisierung:** 2026-06-10 (ASR-Service fertig)  
Legende: `[ ]` offen · `[~]` in Arbeit · `[x]` erledigt · `[!]` blockiert

---

## Infrastruktur & Setup

- [x] App-Plan erstellen (`Plan/Speecher_App_Plan.md`)
- [x] GitHub-Repository einrichten (`Steffen2301/speecher`)
- [x] Branches `main` und `develop` anlegen
- [x] `.gitignore` für Swift/Xcode/macOS
- [x] `README.md` erstellen
- [x] `CHANGELOG.md` erstellen
- [x] `CLAUDE.md` erstellen
- [x] `SpeecherCore` Swift Package anlegen (Grundstruktur)
- [x] GitHub Actions: Build & Test Workflow
- [x] GitHub Actions: Release Workflow (bei Git-Tag)
- [x] GitHub Actions: SwiftLint Workflow
- [x] Issue-Vorlagen: Bug Report + Feature Request
- [ ] Offene Fragen klären (siehe `Plan/Speecher_App_Plan.md` Abschnitt 9)
  - [ ] F1: Geschäftsmodell (Kaufpreis / Abo / Freemium)?
  - [ ] F2: Bevorzugte Übersetzungs-Engine (DeepL / Claude / GPT)?
  - [ ] F3: Distribution (App Store oder Developer ID)?
  - [ ] F4: Soll es eine Web-App-Version geben?

---

## Phase 1 – macOS MVP

### 1.1 Xcode-Projekt
- [x] Xcode-Projekt `Speecher` anlegen (SwiftUI, macOS 14+)
- [x] SpeecherCore als lokale Package-Abhängigkeit einbinden
- [x] App-Icon und Basis-Assets anlegen
- [x] SwiftLint-Konfiguration (`.swiftlint.yml`) erstellen
- [ ] Xcode-Projekt in CI/CD-Workflow aktivieren

### 1.2 Einstellungen & Datenmodell (`SettingsStore`)
- [ ] `SettingsStore` implementieren (SwiftData oder UserDefaults)
- [ ] Einstellung: Eingangssprache
- [ ] Einstellung: Ausgabesprache
- [ ] Einstellung: ASR-Modell (Cloud / Lokal)
- [ ] Einstellung: Korrektur-Modell (Cloud / Lokal)
- [ ] Einstellung: Mikrofon-Gerät
- [ ] Einstellung: UI-Sprache (Deutsch / Englisch)
- [ ] API-Keys sicher im macOS Keychain speichern

### 1.3 AudioEngine
- [x] Mikrofon-Gerät auflisten und auswählen (CoreAudio)
- [x] Live-Aufnahme starten / stoppen (AVAudioEngine)
- [x] Audio in 5-Sekunden-Chunks für Streaming-ASR aufteilen
- [x] Audiodatei-Import: Datei-Öffnen-Dialog
- [x] Unterstützte Formate: MP3, WAV, M4A, FLAC, AIFF, CAF, MP4 (OGG/OPUS Phase 2)
- [x] Audiodateien in 30-Sekunden-Segmente für Batch-ASR aufteilen
- [x] Aufnahme-Pegel-Anzeige (VU-Meter) im UI

### 1.4 ASR-Service (Spracherkennung)
- [x] `ASRService`-Protokoll definieren + Factory
- [x] Lokal-Implementierung: WhisperKit (Core ML, on-device, kein API-Key)
- [x] Lokal-Fallback: Apple SFSpeechRecognizer (leichtgewichtig)
- [x] Modell-Download-Manager (tiny / base / small / medium / large-v3 / turbo)
- [x] Batch-Modus: Audiodatei-Verarbeitung (AsyncThrowingStream)
- [x] Fehlerbehandlung: Netzwerk, Permission, API-Key, Decoding
- [x] KeychainManager: sichere API-Key-Speicherung
- [ ] Streaming-Modus: Live-Transkription mit < 1,5 s Latenz (kommt mit Phase 1.5)

### 1.5 Korrektur- & Übersetzungs-Service
- [x] `CorrectionService`-Protokoll + Factory mit Mode.isFree-Flag
- [x] Kostenlos: Apple NSSpellChecker + Apple Translation (macOS 15+)
- [x] Kostenlos: LanguageTool Public API (kein Key, 20 req/min)
- [x] Kostenlos: Ollama lokales LLM (llama3.2 / mistral / phi4-mini)
- [x] Kostenpflichtig opt-in: Claude API (Anthropic)
- [x] Kostenpflichtig opt-in: OpenAI GPT
- [x] Übersetzungs-Modus: aktiviert wenn Eingangs- ≠ Ausgabesprache
- [x] Vollständige Pipeline: ASR → Korrektur → Text in AppState
- [ ] Streaming-Antwort (Wort-für-Wort) – Phase 2

### 1.6 OutputService (Textausgabe)
- [x] `OutputService`-Protokoll + `OutputResult`-Enum
- [x] `AccessibilityOutputService`: saveFocus() vor Aufnahmestart
- [x] Strategie 1: AXUIElement kAXSelectedTextAttribute (direkte Injection)
- [x] Strategie 2: CGEvent Cmd+V an gespeicherte PID (postToPid)
- [x] Strategie 3: Clipboard-Fallback mit Statusanzeige
- [x] `AccessibilityPermission`: AXIsProcessTrusted + Systemeinstellungen-Link
- [x] `OnboardingView`: Berechtigung erklären, prüfen, verlinken
- [x] `OutputResultBadge` in ControlBar (grün/orange je nach Methode)
- [x] Fallback-Textfeld immer als Protokoll sichtbar

### 1.7 Benutzeroberfläche (SwiftUI)
- [x] `MainView`: Start/Stop-Button, Sprach-Auswahl, Live-Vorschau
- [x] `SettingsView`: Mikrofon, Modelle, API-Keys, UI-Sprache
- [ ] `FileImportView`: Audiodatei-Import mit Fortschrittsanzeige
- [x] `OutputView`: Fallback-Textfeld mit Kopieren-Button
- [x] Statusleisten-App (Menu Bar) mit Start/Stop-Icon
- [x] Globaler Tastatur-Shortcut (`⌘⇧M`)
- [ ] Onboarding: Accessibility-Berechtigung erklären + anfragen

### 1.8 Mehrsprachige UI (Lokalisierung)
- [ ] `.xcstrings`-Datei anlegen
- [ ] Alle UI-Texte lokalisieren: Deutsch
- [ ] Alle UI-Texte lokalisieren: Englisch
- [ ] Sprach-Auswahl in Einstellungen verknüpfen

### 1.9 Tests
- [ ] Unit-Tests: `SettingsStore`
- [ ] Unit-Tests: `ASRService` (Mock-Implementierung)
- [ ] Unit-Tests: `CorrectionService` (Mock-Implementierung)
- [ ] Unit-Tests: Sprachenerkennung und Routing (Übersetzung aktiv/inaktiv)
- [ ] Integrations-Tests: Audio-Chunk-Verarbeitung
- [ ] UI-Tests: Grundfluss (Aufnahme starten → Text erscheint)

### 1.10 Release vorbereiten
- [ ] App-Signierung konfigurieren (Apple Developer Account)
- [ ] Notarisierung in CI/CD einbauen
- [ ] `.dmg`-Build automatisieren
- [ ] Release-Notes für v1.0.0 schreiben
- [ ] `v1.0.0` Tag setzen → automatischer GitHub Release

---

## Phase 2 – macOS Vollversion

- [ ] Google Speech-to-Text als ASR-Option integrieren
- [ ] Azure Cognitive Services als ASR-Option integrieren
- [ ] DeepL API als Übersetzungs-Option integrieren
- [ ] Audiodatei-Export: TXT, DOCX, PDF
- [ ] Verlaufs-Ansicht: letzte Transkriptionen
- [ ] Weitere UI-Sprachen hinzufügen (FR, ES, IT, …)
- [ ] Automatische Sprach-Erkennung (Eingangssprache = „Auto")
- [ ] Erweitertes Einstellungs-Panel

---

## Phase 3 – iOS / iPadOS

- [ ] iOS-App-Target in Xcode anlegen
- [ ] SpeecherCore Package für iOS testen und anpassen
- [ ] SwiftUI-UI für iPhone / iPad anpassen
- [ ] Mikrofon-Diktat (AVFoundation iOS)
- [ ] Datei-Import über Files-App
- [ ] App Store Submission

---

## Phase 4 – Windows & Android

- [ ] Technologie-Entscheidung (Electron / .NET MAUI / Flutter)
- [ ] Plattform-spezifische Audio-Implementierung
- [ ] Feature-Parität mit macOS-Version
- [ ] Cursor-Injection für Windows (UI Automation API)

---

## Offene Fragen (Entscheidungen ausstehend)

| # | Frage | Entschieden am | Entscheidung |
|---|-------|---------------|--------------|
| F1 | Geschäftsmodell (Kaufpreis / Abo / Freemium)? | – | – |
| F2 | Übersetzungs-Engine (DeepL / Claude / GPT)? | – | – |
| F3 | Distribution (App Store / Developer ID)? | – | – |
| F4 | Web-App-Version? | – | – |
| F5 | UI-Sprachen in Phase 1? | 2026-06-10 | Deutsch + Englisch |
