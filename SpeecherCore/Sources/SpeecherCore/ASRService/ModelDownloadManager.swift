@preconcurrency import WhisperKit
import Foundation

/// Verwaltet den Download und Status lokaler WhisperKit-Modelle.
@MainActor
public final class ModelDownloadManager: ObservableObject {
    public typealias WhisperModel = WhisperKitService.WhisperModel

    public enum DownloadState: Sendable {
        case notDownloaded
        case downloading        // unbestimmter Fortschritt (WhisperKit-Callback nicht Sendable)
        case downloaded
        case failed(String)
    }

    @Published public private(set) var states: [WhisperModel: DownloadState] = {
        Dictionary(uniqueKeysWithValues: WhisperModel.allCases.map { ($0, DownloadState.notDownloaded) })
    }()

    @Published public var selectedModel: WhisperModel = .base

    public init() {
        Task { await refreshStates() }
    }

    // MARK: - Public API

    public func download(_ model: WhisperModel) {
        guard case .notDownloaded = states[model] else { return }
        states[model] = .downloading

        Task { @MainActor in
            do {
                _ = try await WhisperKit.download(variant: model.identifier)
                self.states[model] = .downloaded
            } catch {
                self.states[model] = .failed(error.localizedDescription)
            }
        }
    }

    public func delete(_ model: WhisperModel) {
        let cacheBase = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("huggingface/models/argmaxinc/whisperkit-coreml")
        try? FileManager.default.removeItem(at: cacheBase.appendingPathComponent(model.identifier))
        states[model] = .notDownloaded
    }

    public func isDownloaded(_ model: WhisperModel) -> Bool {
        if case .downloaded = states[model] { return true }
        return false
    }

    // MARK: - Private

    private func refreshStates() async {
        let cacheBase = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("huggingface/models/argmaxinc/whisperkit-coreml")
        for model in WhisperModel.allCases {
            let exists = FileManager.default.fileExists(
                atPath: cacheBase.appendingPathComponent(model.identifier).path
            )
            states[model] = exists ? .downloaded : .notDownloaded
        }
    }
}
