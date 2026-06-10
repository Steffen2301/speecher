# CLAUDE.md – Speecher

## Projektübersicht

Speecher ist eine macOS-App (Swift 6 / SwiftUI), die Sprache in korrigierten, übersetzten Text umwandelt.  
Vollständiger Plan: `Plan/Speecher_App_Plan.md`

## Architektur

```
SpeecherCore/          → Plattformunabhängige Swift-Package-Logik
  AudioEngine          → Mikrofon-Input, Datei-Import, Chunking
  ASRService           → Spracherkennung (Whisper API / Whisper.cpp)
  CorrectionService    → Korrektur + Übersetzung (Claude API / Ollama)
  OutputService        → Cursor-Injection + Fallback-Textfeld
  ModelManager         → Modell-Verwaltung, API-Keys (Keychain)
  SettingsStore        → Einstellungen

Speecher/              → macOS SwiftUI App Target
SpeecherTests/         → Unit- und Integrationstests
```

## Entwicklungsregeln

- Swift 6, async/await (kein Combine/DispatchQueue außer wo nötig)
- API-Keys **nur** im macOS Keychain speichern – niemals in Code oder .env
- Modelle und Services über Protokolle abstrahieren (für einfaches Testing und Austausch)
- Keine Telemetrie ohne explizite Nutzer-Zustimmung
- Privat-Modus: **kein** Netzwerkzugriff wenn lokale Modelle aktiv sind

## Branches

- `main` – stabile Releases
- `develop` – aktive Entwicklung
- `feature/<name>` – Feature-Branches

## Tests

```bash
swift test
```

## Build

```bash
xcodebuild -scheme Speecher -destination 'platform=macOS' build
```

## Wichtige Entscheidungen

- Cursor-Injection über macOS Accessibility API (`AXUIElement`)
- Audiodatei-Chunking: 30-Sekunden-Segmente für ASR
- Live-Modus: 5-Sekunden-Chunks, Latenz-Ziel < 1,5 Sekunden
