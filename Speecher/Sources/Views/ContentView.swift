import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        VStack(spacing: 0) {
            ToolbarView()
            Divider()
            TranscriptionView()
            Divider()
            ControlBarView()
        }
        .frame(minWidth: 600, idealWidth: 700, minHeight: 400, idealHeight: 500)
    }
}
