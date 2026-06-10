import AppKit
import Carbon.HIToolbox

/// Verwaltet den globalen Tastaturkurzbefehl für Speecher.
/// Wirkt systemweit – auch wenn Speecher im Hintergrund läuft.
/// Erfordert Accessibility-Berechtigung (wird im Onboarding erklärt).
@MainActor
final class GlobalHotkeyManager: ObservableObject {
    @Published private(set) var shortcut: HotkeyShortcut

    private var globalMonitor: Any?
    private var localMonitor: Any?
    var onTrigger: (() -> Void)?

    // UserDefaults-Schlüssel
    private static let keyCodeKey   = "hotkeyKeyCode"
    private static let modifiersKey = "hotkeyModifiers"

    // Standard: ⌘⇧M (keyCode 46 = M)
    private static let defaultShortcut = HotkeyShortcut(keyCode: 46, modifiers: [.command, .shift])

    init() {
        let saved = GlobalHotkeyManager.loadFromDefaults()
        shortcut = saved
        startListening()
    }

    // Monitor-Cleanup via NotificationCenter beim App-Terminate
    func cleanup() {
        if let g = globalMonitor { NSEvent.removeMonitor(g); globalMonitor = nil }
        if let l = localMonitor  { NSEvent.removeMonitor(l); localMonitor = nil }
    }

    // MARK: - Shortcut ändern

    func update(shortcut new: HotkeyShortcut) {
        shortcut = new
        GlobalHotkeyManager.saveToDefaults(new)
        restartListening()
    }

    func resetToDefault() {
        update(shortcut: GlobalHotkeyManager.defaultShortcut)
    }

    // MARK: - Event-Monitor

    private func startListening() {
        let mask: NSEvent.EventTypeMask = .keyDown

        // Global: wirkt in anderen Apps (braucht Accessibility)
        if AccessibilityPermission.isGranted {
            globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: mask) { [weak self] event in
                Task { @MainActor [weak self] in
                    self?.handleEvent(event)
                }
            }
        }

        // Lokal: wirkt wenn Speecher selbst aktiv ist
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: mask) { [weak self] event in
            Task { @MainActor [weak self] in
                self?.handleEvent(event)
            }
            return event
        }
    }

    private func restartListening() {
        if let g = globalMonitor { NSEvent.removeMonitor(g); globalMonitor = nil }
        if let l = localMonitor  { NSEvent.removeMonitor(l); localMonitor = nil }
        startListening()
    }

    private func handleEvent(_ event: NSEvent) {
        guard event.keyCode == shortcut.keyCode,
              event.modifierFlags.intersection(.deviceIndependentFlagsMask) == shortcut.modifiers
        else { return }
        onTrigger?()
    }

    // MARK: - Persistence

    private static func saveToDefaults(_ shortcut: HotkeyShortcut) {
        UserDefaults.standard.set(Int(shortcut.keyCode), forKey: keyCodeKey)
        UserDefaults.standard.set(shortcut.modifiers.rawValue, forKey: modifiersKey)
    }

    private static func loadFromDefaults() -> HotkeyShortcut {
        guard UserDefaults.standard.object(forKey: keyCodeKey) != nil else {
            return defaultShortcut
        }
        let keyCode  = UInt16(UserDefaults.standard.integer(forKey: keyCodeKey))
        let rawMods  = UInt(UserDefaults.standard.integer(forKey: modifiersKey))
        return HotkeyShortcut(keyCode: keyCode, modifiers: NSEvent.ModifierFlags(rawValue: rawMods))
    }
}

// MARK: - Datenmodell

struct HotkeyShortcut: Equatable {
    let keyCode: UInt16
    let modifiers: NSEvent.ModifierFlags

    /// Lesbare Darstellung, z. B. „⌘⇧M"
    var displayString: String {
        var parts = ""
        if modifiers.contains(.control)  { parts += "⌃" }
        if modifiers.contains(.option)   { parts += "⌥" }
        if modifiers.contains(.shift)    { parts += "⇧" }
        if modifiers.contains(.command)  { parts += "⌘" }
        parts += keyCodeToString(keyCode)
        return parts
    }

    private func keyCodeToString(_ code: UInt16) -> String {
        // Häufige Tasten direkt mappen
        let map: [UInt16: String] = [
            36: "↩", 48: "⇥", 49: "Space", 51: "⌫", 53: "Esc",
            122: "F1", 120: "F2", 99: "F3", 118: "F4", 96: "F5",
            97: "F6", 98: "F7", 100: "F8",
        ]
        if let special = map[code] { return special }
        // Buchstaben über CGEventSource
        var deadKey: UInt32 = 0
        var chars = [UniChar](repeating: 0, count: 4)
        var length = 0
        if let kbd = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue(),
           let layoutData = TISGetInputSourceProperty(kbd, kTISPropertyUnicodeKeyLayoutData) {
            let layout = Unmanaged<CFData>.fromOpaque(layoutData).takeUnretainedValue() as Data
            layout.withUnsafeBytes { ptr in
                let layoutPtr = ptr.bindMemory(to: UCKeyboardLayout.self).baseAddress
                UCKeyTranslate(layoutPtr, code, UInt16(kUCKeyActionDisplay),
                               0, UInt32(LMGetKbdType()),
                               OptionBits(kUCKeyTranslateNoDeadKeysBit),
                               &deadKey, 4, &length, &chars)
            }
        }
        let char = String(utf16CodeUnits: chars, count: length).uppercased()
        return char.isEmpty ? "?\(code)" : char
    }
}
