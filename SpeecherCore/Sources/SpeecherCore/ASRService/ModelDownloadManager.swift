import Foundation

/// Verwaltet lokale Whisper.cpp-Modelle (Download, Status, Löschung).
/// Wird aktiv wenn die Whisper.cpp-Integration in Phase 2 ergänzt wird.
@MainActor
public final class ModelDownloadManager: ObservableObject {
    public enum WhisperModel: String, CaseIterable, Sendable {
        case tiny   = "tiny"
        case base   = "base"
        case small  = "small"
        case medium = "medium"
        case large  = "large-v3"

        public var displayName: String {
            switch self {
            case .tiny:   return "Tiny (74 MB) – schnell, weniger genau"
            case .base:   return "Base (141 MB) – ausgewogen"
            case .small:  return "Small (466 MB) – gut"
            case .medium: return "Medium (1,5 GB) – sehr gut"
            case .large:  return "Large v3 (3,1 GB) – beste Qualität"
            }
        }

        public var sizeInBytes: Int64 {
            switch self {
            case .tiny:   return 74_000_000
            case .base:   return 141_000_000
            case .small:  return 466_000_000
            case .medium: return 1_528_000_000
            case .large:  return 3_100_000_000
            }
        }

        var downloadURL: URL {
            URL(string: "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-\(rawValue).bin")!
        }

        var localFileName: String { "ggml-\(rawValue).bin" }
    }

    public enum DownloadState: Sendable {
        case notDownloaded
        case downloading(progress: Double)
        case downloaded
        case failed(String)
    }

    @Published public private(set) var states: [WhisperModel: DownloadState] = {
        Dictionary(uniqueKeysWithValues: WhisperModel.allCases.map { ($0, .notDownloaded) })
    }()

    private var activeTasks: [WhisperModel: URLSessionDownloadTask] = [:]
    private let modelsDirectory: URL

    public init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        modelsDirectory = appSupport.appendingPathComponent("Speecher/WhisperModels", isDirectory: true)
        try? FileManager.default.createDirectory(at: modelsDirectory, withIntermediateDirectories: true)
        refreshStates()
    }

    public func isDownloaded(_ model: WhisperModel) -> Bool {
        FileManager.default.fileExists(atPath: localURL(for: model).path)
    }

    public func localURL(for model: WhisperModel) -> URL {
        modelsDirectory.appendingPathComponent(model.localFileName)
    }

    public func download(_ model: WhisperModel) {
        guard !isDownloaded(model) else {
            states[model] = .downloaded
            return
        }
        states[model] = .downloading(progress: 0)

        let task = URLSession.shared.downloadTask(with: model.downloadURL) { [weak self] tempURL, _, error in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if let error {
                    self.states[model] = .failed(error.localizedDescription)
                    return
                }
                guard let tempURL else { return }
                do {
                    let dest = self.localURL(for: model)
                    try? FileManager.default.removeItem(at: dest)
                    try FileManager.default.moveItem(at: tempURL, to: dest)
                    self.states[model] = .downloaded
                } catch {
                    self.states[model] = .failed(error.localizedDescription)
                }
                self.activeTasks.removeValue(forKey: model)
            }
        }
        activeTasks[model] = task
        task.resume()
    }

    public func cancel(_ model: WhisperModel) {
        activeTasks[model]?.cancel()
        activeTasks.removeValue(forKey: model)
        states[model] = .notDownloaded
    }

    public func delete(_ model: WhisperModel) {
        try? FileManager.default.removeItem(at: localURL(for: model))
        states[model] = .notDownloaded
    }

    private func refreshStates() {
        for model in WhisperModel.allCases {
            states[model] = isDownloaded(model) ? .downloaded : .notDownloaded
        }
    }
}
