import ApplicationServices
import AppKit

/// Wrapper für die macOS Accessibility-Berechtigung.
enum AccessibilityPermission {
    /// Gibt an ob Speecher bereits Accessibility-Zugriff hat.
    static var isGranted: Bool {
        AXIsProcessTrusted()
    }

    /// Öffnet den System-Dialog zur Berechtigung (falls noch nicht erteilt).
    /// Gibt true zurück wenn bereits berechtigt.
    @discardableResult
    static func requestIfNeeded() -> Bool {
        if isGranted { return true }
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        return AXIsProcessTrustedWithOptions(options as CFDictionary)
    }

    /// Öffnet die Systemeinstellungen direkt auf der Bedienungshilfen-Seite.
    static func openSystemSettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }
}
