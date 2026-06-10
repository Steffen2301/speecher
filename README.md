# Speecher

> Sprache zu Text – korrigiert, übersetzt, direkt am Cursor.

Speecher wandelt gesprochene Sprache in korrigierten, grammatikalisch einwandfreien Text um und kann diesen gleichzeitig übersetzen. Der Text wird direkt an der aktuellen Cursor-Position in jeder App eingefügt (Mail, Word, Excel, Browser …).

## Features

- **Diktat & Dateien** – Live-Aufnahme über einstellbares Mikrofon oder Import von Audiodateien (MP3, WAV, M4A, FLAC, OGG, AIFF, OPUS, MP4)
- **Korrektur** – Automatische Rechtschreib- und Grammatikkorrektur
- **Übersetzung** – Eingangs- und Ausgabesprache frei wählbar
- **Cursor-Output** – Text wird direkt in die aktive App eingefügt
- **Öffentlich oder privat** – Wahl zwischen Cloud-Modellen (Whisper API, Claude) und lokalen Modellen (Whisper.cpp, Ollama) für vollständigen Datenschutz
- **Echtzeit** – Live-Transkription und Übersetzung während der Aufnahme
- **Mehrsprachige UI** – Oberfläche in Deutsch und Englisch (erweiterbar)

## Plattformen

| Platform | Status |
|----------|--------|
| macOS 14+ | Phase 1 – In Entwicklung |
| iOS / iPadOS | Phase 3 – Geplant |
| Windows | Phase 4 – Geplant |
| Android | Phase 4 – Geplant |

## Tech-Stack

- **Swift 6 / SwiftUI** (macOS)
- **ASR:** Whisper API (Cloud) · Whisper.cpp (lokal)
- **Korrektur & Übersetzung:** Claude API · DeepL · Ollama (lokal)
- **Cursor-Injection:** macOS Accessibility API

## Entwicklung

```bash
# Repository klonen
git clone https://github.com/Steffen2301/speecher.git
cd speecher

# Xcode-Projekt öffnen (nach Erstellung in Phase 1)
open Speecher/Speecher.xcodeproj
```

## Projektstruktur

```
speecher/
├── .github/
│   ├── workflows/          # CI/CD (Build, Release, Lint)
│   └── ISSUE_TEMPLATE/     # Bug- und Feature-Vorlagen
├── Speecher/               # macOS Xcode-App (wird in Phase 1 erstellt)
├── SpeecherCore/           # Swift Package – plattformunabhängige Logik
├── SpeecherTests/          # Tests
├── Plan/                   # App-Plan und Dokumentation
├── CLAUDE.md               # Anweisungen für Claude Code
└── CHANGELOG.md
```

## Roadmap

Siehe [Plan/Speecher_App_Plan.md](Plan/Speecher_App_Plan.md) für den vollständigen Entwicklungsplan.

## Changelog

Siehe [CHANGELOG.md](CHANGELOG.md).

## Lizenz

Wird festgelegt.
