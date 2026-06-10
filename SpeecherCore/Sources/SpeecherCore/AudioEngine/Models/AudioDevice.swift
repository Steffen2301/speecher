import CoreAudio
import Foundation

/// Ein verfügbares Audio-Eingabegerät (Mikrofon).
public struct AudioDevice: Identifiable, Sendable, Hashable {
    public let id: AudioDeviceID   // CoreAudio-ID (UInt32)
    public let name: String
    public let uid: String
    public let inputChannelCount: Int

    public static let `default` = AudioDevice(
        id: kAudioObjectUnknown,
        name: "Systemstandard",
        uid: "default",
        inputChannelCount: 1
    )
}
