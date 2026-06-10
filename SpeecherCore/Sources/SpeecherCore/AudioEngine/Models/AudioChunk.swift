import Foundation

/// Ein Audiodaten-Segment, das zur Transkription an den ASR-Service übergeben wird.
public struct AudioChunk: Sendable {
    /// Rohe PCM-Audiodaten (Float32, interleaved)
    public let data: Data
    public let sampleRate: Double
    public let channelCount: Int
    public let sequenceNumber: Int
    public let timestamp: Date
    /// Tatsächliche Länge in Sekunden
    public let duration: TimeInterval

    public var isEmpty: Bool { data.isEmpty }
}
