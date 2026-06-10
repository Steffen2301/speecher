# Speecher – App-Plan

**Version:** 1.0  
**Datum:** 2026-06-10  
**Status:** Entwurf

---

## 1. Produktvision

Speecher ist eine plattformübergreifende Anwendung, die gesprochene Sprache in schriftlichen Text umwandelt, dabei automatisch Rechtschreib- und Grammatikfehler korrigiert und den Text auf Wunsch in eine andere Sprache übersetzt. Die Ausgabe erfolgt direkt an der aktuellen Cursor-Position in jeder beliebigen App (Mail, Word, Excel, Browser etc.) oder alternativ in einem eigenen Textfeld.

---

## 2. Anforderungen (Übersicht)

| # | Anforderung | Priorität |
|---|-------------|-----------|
| R1 | Eingabe- und Ausgabesprache wählbar (inkl. Übersetzung) | Hoch |
| R2 | Textausgabe an Cursor-Position oder Fallback-Textfeld | Hoch |
| R3 | macOS zuerst, später Windows / iOS / Android | Hoch |
| R4 | Mikrofon-Diktat + Audiodatei-Import (gängige Formate) | Hoch |
| R5 | Wahl zwischen öffentlichen und privaten Sprachmodellen | Hoch |
| R6 | Mehrsprachige Benutzeroberfläche (UI-Sprache einstellbar) | Mittel |
| R7 | Live-Transkription und Echtzeit-Übersetzung | Hoch |
| R8 | GitHub-Integration | Hoch |

---

## 3. Technologie-Stack

### 3.1 macOS-App (Phase 1)
- **Sprache:** Swift 6 / SwiftUI
- **Ziel:** macOS 14 Sonoma und neuer
- **Cursor-Injection:** macOS Accessibility API (`AXUIElement`) → Text an aktiver Cursor-Position einfügen
- **Fallback:** Eigenes Textfeld mit Kopieren-Button

### 3.2 Spracherkennung (ASR – Automatic Speech Recognition)

| Modus | Technologie | Beschreibung |
|-------|-------------|--------------|
| Öffentlich (Cloud) | OpenAI Whisper API / Google Speech-to-Text / Azure Cognitive Services | Hohe Genauigkeit, keine lokale Rechenleistung |
| Privat (lokal) | Whisper.cpp (C++ Port, läuft on-device) | Datenschutzkonform, keine Cloud-Verbindung |
| Live-Modus | Streaming ASR via Mikrofon-Chunks | Echtzeit-Transkription in unter 1 Sekunde |

### 3.3 Korrrektur & Übersetzung (LLM)

| Modus | Technologie |
|-------|-------------|
| Öffentlich | Claude API (Anthropic) / OpenAI GPT / DeepL API |
| Privat (lokal) | Ollama + lokales LLM (z. B. Mistral, Llama 3) |

**Korrektions-Prompt-Strategie:**
- Rechtschreibung + Grammatik korrigieren
- Stil beibehalten (keine inhaltliche Veränderung)
- Zielsprache anwenden (falls Übersetzung aktiviert)

### 3.4 Mikrofon & Audio-Input
- **Live-Aufnahme:** AVFoundation (macOS), einstellbares Mikrofon-Gerät
- **Datei-Import:** Unterstützte Formate: MP3, M4A, WAV, FLAC, OGG, AIFF, OPUS, MP4 (Audio)
- **Chunking:** Audiodateien werden in 30-Sekunden-Segmente aufgeteilt für optimale ASR-Verarbeitung

### 3.5 Cross-Platform (Phase 2+)
- **Windows:** Electron + Web-Technologien ODER .NET MAUI
- **iOS / iPadOS:** SwiftUI (Code-Sharing mit macOS-App via Swift Packages)
- **Android:** Kotlin + Jetpack Compose

---

## 4. App-Architektur

```
Speecher
├── AudioEngine          → Mikrofon-Input, Datei-Import, Chunking
├── ASRService           → Spracherkennung (Cloud oder lokal)
├── CorrectionService    → Korrektur + Übersetzung (LLM-Aufruf)
├── OutputService        → Cursor-Injection (Accessibility API) + Fallback-Textfeld
├── ModelManager         → Verwaltung öffentl./priv. Modelle, API-Keys
├── SettingsStore        → Einstellungen (Sprache, Mikrofon, Modell, UI-Sprache)
└── UI (SwiftUI)
    ├── MainView         → Start/Stop, Sprach-Auswahl, Live-Vorschau
    ├── SettingsView     → Mikrofon, Modelle, Sprache der Oberfläche
    ├── FileImportView   → Audiodatei-Import
    └── OutputView       → Fallback-Textfeld
```

---

## 5. Kernfunktionen im Detail

### 5.1 Sprach-Auswahl (R1)
- Dropdown: Eingangssprache (z. B. Deutsch, Englisch, Französisch, Spanisch, …)
- Dropdown: Ausgabesprache (gleiche Liste + „Automatisch erkennen")
- Wenn Eingangs- ≠ Ausgabesprache → Übersetzung automatisch aktiviert

### 5.2 Cursor-Injection (R2)
- Beim Drücken des Aufnahme-Shortcuts: aktives Fenster + Cursor-Position merken
- Nach Verarbeitung: Text via Accessibility API einfügen
- Fallback (App unterstützt keine Accessibility): Text in Speecher-Textfeld ausgeben mit „Kopieren"-Button

### 5.3 Mikrofon-Diktat (R4, R7)
- Statusleiste-Icon oder globaler Tastatur-Shortcut (z. B. `⌘ + Shift + M`) startet Aufnahme
- Audiodaten werden in 5-Sekunden-Chunks an ASR geschickt
- Transkribierter Text erscheint live im UI (Streaming)
- Nach Abschluss: Korrektur + ggf. Übersetzung → Ausgabe

### 5.4 Audiodatei-Verarbeitung (R4)
- Datei-Öffnen-Dialog (Drag & Drop oder File-Picker)
- Fortschrittsanzeige bei langer Verarbeitung
- Ergebnis im Fallback-Textfeld + Export als TXT/DOCX/PDF

### 5.5 Modell-Auswahl (R5)
- **Einstellungen → Modelle:**
  - ASR-Modell: Öffentlich (Whisper API, Google, Azure) oder Privat (Whisper.cpp lokal)
  - Korrektur-Modell: Öffentlich (Claude, GPT-4, DeepL) oder Privat (Ollama)
  - API-Keys: sicher gespeichert in macOS Keychain
  - Lokale Modelle: Download-Manager mit Fortschrittsanzeige

### 5.6 Mehrsprachige UI (R6)
- Unterstützte UI-Sprachen (Phase 1): Deutsch, Englisch
- Erweiterbar via `.xcstrings` (Apple Localizations)
- Einstellung: Einstellungen → Oberfläche → Sprache

### 5.7 Live-Transkription (R7)
- Streaming-Modus: Text wird Wort für Wort ausgegeben
- Latenz-Ziel: < 1,5 Sekunden Ende-zu-Ende
- Zwischen-Korrektur: Wird nach vollständigen Sätzen angewandt

---

## 6. Datenschutz & Sicherheit

- API-Keys werden ausschließlich im macOS Keychain gespeichert (nie im Klartext)
- Im privaten Modus verlassen keine Audio- oder Textdaten das Gerät
- Klare Kennzeichnung im UI: „Cloud-Modus" vs. „Privat-Modus"
- Keine Telemetrie ohne ausdrückliche Zustimmung

---

## 7. GitHub-Integration (R8)

### Repository-Struktur
```
speecher/
├── .github/
│   ├── workflows/
│   │   ├── build.yml          → CI: Build & Tests bei jedem Push
│   │   ├── release.yml        → CD: Automatischer Release bei Git-Tag
│   │   └── swiftlint.yml      → Code-Qualitätsprüfung
│   └── ISSUE_TEMPLATE/
│       ├── bug_report.md
│       └── feature_request.md
├── Speecher/                  → Xcode-Projekt (macOS App)
├── SpeecherCore/              → Swift Package (plattformunabhängige Logik)
├── SpeecherTests/
├── Plan/                      → Dieser Plan
├── CLAUDE.md                  → Anweisungen für Claude Code
├── README.md
└── CHANGELOG.md
```

### Branches & Workflow
- `main` → stabile, freigegebene Version
- `develop` → aktive Entwicklung
- Feature-Branches: `feature/<name>`
- Releases: semantische Versionierung (v1.0.0, v1.1.0, …)

### CI/CD (GitHub Actions)
- Automatischer Build bei jedem Push auf `develop` und `main`
- Automatische Tests (Unit + Integration)
- SwiftLint für Code-Qualität
- Release-Build + notarisiertes .dmg bei Git-Tag

---

## 8. Phasen & Roadmap

### Phase 1 – macOS MVP (ca. 8–12 Wochen)
- [ ] Xcode-Projekt + GitHub-Repository einrichten
- [ ] AudioEngine: Mikrofon-Input + Datei-Import
- [ ] ASR-Integration: Whisper API (Cloud) + Whisper.cpp (lokal)
- [ ] Korrektur-Service: Claude API
- [ ] Cursor-Injection via Accessibility API
- [ ] Grundlegendes SwiftUI-UI (Start/Stop, Sprach-Auswahl)
- [ ] Einstellungen: Mikrofon, Modell, API-Key
- [ ] Mehrsprachig: Deutsch + Englisch
- [ ] CI/CD mit GitHub Actions

### Phase 2 – macOS Vollversion (ca. 6–8 Wochen nach Phase 1)
- [ ] Live-Streaming-Transkription (Echtzeit)
- [ ] Vollständige Modellauswahl (Google, Azure, DeepL, Ollama)
- [ ] Audiodatei-Export (TXT, DOCX, PDF)
- [ ] Statusleisten-App + globaler Shortcut
- [ ] Weitere UI-Sprachen

### Phase 3 – iOS / iPadOS (ca. 6 Wochen nach Phase 2)
- [ ] SwiftUI-App mit geteiltem SpeecherCore-Package
- [ ] Mikrofon-Diktat + Dateiimport (Files-App)

### Phase 4 – Windows & Android (nach Phase 3)
- [ ] Technologie-Entscheidung (Electron vs. .NET MAUI / Flutter)
- [ ] Feature-Parität mit macOS

---

## 9. Offene Fragen / Entscheidungen

| # | Frage | Status |
|---|-------|--------|
| F1 | Soll die App kostenpflichtig sein? (Kaufpreis / Abo / Freemium) | Offen |
| F2 | Welche Übersetzungs-Engine bevorzugt? (DeepL vs. Claude vs. GPT) | Offen |
| F3 | App Store Distribution oder direkt (Developer ID)? | Offen |
| F4 | Soll es eine Web-App-Version geben? | Offen |
| F5 | Welche Sprachen soll die UI in Phase 1 unterstützen? | Deutsch + Englisch vorgeschlagen |

---

## 10. Nächste Schritte (sofort)

1. GitHub-Repository `speecher` erstellen und Grundstruktur anlegen
2. Xcode-Projekt mit SwiftUI initialisieren
3. Offene Fragen klären (Abschnitt 9)
4. Mit Phase 1 beginnen: AudioEngine + Whisper-Integration
