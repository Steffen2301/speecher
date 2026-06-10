import SwiftUI

struct AppCommands: Commands {
    var body: some Commands {
        CommandGroup(replacing: .newItem) {}

        CommandMenu("Aufnahme") {
            Button("Aufnahme starten / stoppen") {}
                .keyboardShortcut("m", modifiers: [.command, .shift])
        }
    }
}
