import SwiftUI
import AppKit

/// Zeigt den aktuellen Kurzbefehl und ermöglicht per Klick die Neubelegung.
struct HotkeyRecorderView: View {
    @ObservedObject var manager: GlobalHotkeyManager
    @State private var isRecording = false
    @State private var localMonitor: Any?

    var body: some View {
        HStack(spacing: 10) {
            // Shortcut-Badge
            Text(isRecording ? "Taste drücken …" : manager.shortcut.displayString)
                .font(.system(.body, design: .monospaced))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(isRecording ? Color.accentColor.opacity(0.15) : Color.secondary.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isRecording ? Color.accentColor : Color.secondary.opacity(0.3), lineWidth: 1)
                )
                .onTapGesture { startRecording() }

            if isRecording {
                Button("Abbrechen") { stopRecording() }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            } else {
                Button("Ändern") { startRecording() }
                    .buttonStyle(.bordered)
                    .controlSize(.small)

                Button("Zurücksetzen") {
                    manager.resetToDefault()
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .font(.caption)
            }
        }
    }

    // MARK: - Recording

    private func startRecording() {
        isRecording = true
        // Lokalen Monitor installieren der die nächste Taste aufzeichnet
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [self] event in
            Task { @MainActor in
                recordShortcut(from: event)
            }
            return nil   // Taste schlucken
        }
    }

    private func stopRecording() {
        isRecording = false
        if let m = localMonitor { NSEvent.removeMonitor(m); localMonitor = nil }
    }

    private func recordShortcut(from event: NSEvent) {
        // Esc → Abbrechen
        if event.keyCode == 53 { stopRecording(); return }

        // Mindestens eine Modifier-Taste erforderlich
        let mods = event.modifierFlags.intersection([.command, .control, .option, .shift])
        guard !mods.isEmpty else { return }

        let new = HotkeyShortcut(keyCode: event.keyCode, modifiers: mods)
        manager.update(shortcut: new)
        stopRecording()
    }
}
