import AppKit
import ApplicationServices
import SpeecherCore

/// Fügt Text per Accessibility-API direkt an der gespeicherten Cursor-Position ein.
///
/// Strategie (in dieser Reihenfolge):
///   1. AXUIElement kAXSelectedTextAttribute  → direkte Injection, kein App-Wechsel nötig
///   2. CGEvent Cmd+V an gespeicherte PID    → benötigt dass App noch läuft
///   3. Nur in Zwischenablage kopieren        → Nutzer muss selbst einfügen
@MainActor
final class AccessibilityOutputService: OutputService {
    private var savedElement: AXUIElement?
    private var savedApp: NSRunningApplication?

    nonisolated var isAccessibilityGranted: Bool {
        AccessibilityPermission.isGranted
    }

    // MARK: - saveFocus

    /// Sofort beim Start der Aufnahme aufrufen – vor jedem App-Wechsel.
    func saveFocus() {
        savedApp = NSWorkspace.shared.frontmostApplication
        guard let pid = savedApp?.processIdentifier else { return }

        let appElement = AXUIElementCreateApplication(pid)
        var focused: CFTypeRef?
        let status = AXUIElementCopyAttributeValue(
            appElement,
            kAXFocusedUIElementAttribute as CFString,
            &focused
        )
        guard status == .success, CFGetTypeID(focused as CFTypeRef? ?? kCFNull) == AXUIElementGetTypeID() else {
            savedElement = nil
            return
        }
        // swiftlint:disable:next force_cast
        savedElement = (focused as! AXUIElement)
    }

    // MARK: - insert

    func insert(_ text: String) async -> OutputResult {
        guard savedApp != nil || savedElement != nil else { return .noTargetSaved }

        // Strategie 1: AXUIElement kAXSelectedTextAttribute
        if let element = savedElement, AccessibilityPermission.isGranted {
            let status = AXUIElementSetAttributeValue(
                element,
                kAXSelectedTextAttribute as CFString,
                text as CFTypeRef
            )
            if status == .success { return .insertedAtCursor }
        }

        // Strategie 2: Clipboard + simuliertes Cmd+V an die gespeicherte App
        if let app = savedApp, AccessibilityPermission.isGranted {
            let pasted = await pasteViaSimulation(text: text, to: app)
            if pasted { return .pastedViaSimulation }
        }

        // Strategie 3: Nur Clipboard – Nutzer muss selbst einfügen
        copyToClipboard(text)
        return .copiedToClipboard
    }

    // MARK: - Private: CGEvent Simulation

    private func pasteViaSimulation(text: String, to app: NSRunningApplication) async -> Bool {
        let pasteboard = NSPasteboard.general
        let previousString = pasteboard.string(forType: .string)
        let previousTypes  = pasteboard.types ?? []

        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        let pid = app.processIdentifier
        let source = CGEventSource(stateID: .combinedSessionState)

        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(9), keyDown: true),
              let keyUp   = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(9), keyDown: false) else {
            restoreClipboard(previousString, previousTypes: previousTypes)
            return false
        }
        keyDown.flags = .maskCommand
        keyUp.flags   = .maskCommand

        // Events an die gespeicherte App senden (nicht an Speecher)
        keyDown.postToPid(pid)
        keyUp.postToPid(pid)

        // Zwischenablage nach kurzem Delay wiederherstellen
        try? await Task.sleep(for: .milliseconds(600))
        restoreClipboard(previousString, previousTypes: previousTypes)
        return true
    }

    private func copyToClipboard(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }

    private func restoreClipboard(_ previous: String?, previousTypes: [NSPasteboard.PasteboardType]) {
        guard let text = previous, !previousTypes.isEmpty else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }

    // MARK: - Diagnose

    /// Gibt alle AX-Attribute des gespeicherten Elements zurück (für Debugging).
    func diagnosticAttributes() -> [String] {
        guard let element = savedElement else { return ["kein Element gespeichert"] }
        var names: CFArray?
        guard AXUIElementCopyAttributeNames(element, &names) == .success,
              let arr = names as? [String] else { return ["Attribute nicht lesbar"] }
        return arr
    }

    /// Gibt true zurück wenn das gespeicherte Element beschreibbar ist.
    var canInsertAtCursor: Bool {
        guard let element = savedElement else { return false }
        var settable: DarwinBoolean = false
        AXUIElementIsAttributeSettable(element, kAXSelectedTextAttribute as CFString, &settable)
        return settable.boolValue
    }
}
