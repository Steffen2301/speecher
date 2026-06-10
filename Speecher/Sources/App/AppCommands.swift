import SwiftUI

struct AppCommands: Commands {
    let locale: LocalizationManager

    var body: some Commands {
        CommandGroup(replacing: .newItem) {}

        CommandMenu(locale.t("commands.recording_menu")) {
            Button(locale.t("commands.toggle")) {}
                .keyboardShortcut("m", modifiers: [.command, .shift])
        }
    }
}
