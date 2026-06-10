import SwiftUI
import Combine

@MainActor
final class AppState: ObservableObject {
    @Published var isRecording = false
    @Published var transcribedText = ""
    @Published var statusMessage = ""

    @AppStorage("inputLanguage") var inputLanguage = "de"
    @AppStorage("outputLanguage") var outputLanguage = "de"
    @AppStorage("uiLanguage") var uiLanguage = "de"
    @AppStorage("asrMode") var asrMode = ASRMode.cloud
    @AppStorage("correctionMode") var correctionMode = CorrectionMode.cloud

    enum ASRMode: String, CaseIterable {
        case cloud = "cloud"
        case local = "local"
    }

    enum CorrectionMode: String, CaseIterable {
        case cloud = "cloud"
        case local = "local"
    }
}
