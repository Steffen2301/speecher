import AVFoundation
import Foundation

/// Prüft und fordert die Mikrofon-Berechtigung an.
public enum MicrophonePermission {
    public enum Status: Sendable {
        case granted
        case denied
        case notDetermined
    }

    public static var current: Status {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:       return .granted
        case .denied, .restricted: return .denied
        case .notDetermined:    return .notDetermined
        @unknown default:       return .notDetermined
        }
    }

    /// Fordert Berechtigung an. Gibt `true` zurück wenn erteilt.
    public static func request() async -> Bool {
        await AVCaptureDevice.requestAccess(for: .audio)
    }
}
