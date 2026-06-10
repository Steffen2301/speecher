import CoreAudio
import Foundation

/// Listet verfügbare Mikrofone via CoreAudio auf und erlaubt die Auswahl.
@MainActor
public final class AudioDeviceManager: ObservableObject {
    @Published public private(set) var inputDevices: [AudioDevice] = []
    @Published public var selectedDevice: AudioDevice = .default

    public init() {
        refresh()
    }

    public func refresh() {
        inputDevices = [.default] + fetchInputDevices()
    }

    /// Setzt das gewählte Gerät als Standard-Eingabe für AVAudioEngine.
    public func applySelection() throws {
        guard selectedDevice.id != kAudioObjectUnknown else { return }
        var deviceID = selectedDevice.id
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        let status = AudioObjectSetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0, nil,
            UInt32(MemoryLayout<AudioDeviceID>.size),
            &deviceID
        )
        if status != noErr {
            throw AudioEngineError.deviceSelectionFailed(status)
        }
    }

    // MARK: - Private

    private func fetchInputDevices() -> [AudioDevice] {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var dataSize: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(
            AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &dataSize
        ) == noErr else { return [] }

        let deviceCount = Int(dataSize) / MemoryLayout<AudioDeviceID>.size
        var deviceIDs = [AudioDeviceID](repeating: 0, count: deviceCount)
        guard AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject), &address,
            0, nil, &dataSize, &deviceIDs
        ) == noErr else { return [] }

        return deviceIDs.compactMap { deviceID in
            guard inputChannelCount(for: deviceID) > 0 else { return nil }
            return AudioDevice(
                id: deviceID,
                name: deviceName(for: deviceID),
                uid: deviceUID(for: deviceID),
                inputChannelCount: inputChannelCount(for: deviceID)
            )
        }
    }

    private func deviceName(for deviceID: AudioDeviceID) -> String {
        stringProperty(kAudioObjectPropertyName, for: deviceID) ?? "Unbekanntes Gerät"
    }

    private func deviceUID(for deviceID: AudioDeviceID) -> String {
        stringProperty(kAudioDevicePropertyDeviceUID, for: deviceID) ?? "\(deviceID)"
    }

    private func inputChannelCount(for deviceID: AudioDeviceID) -> Int {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStreamConfiguration,
            mScope: kAudioDevicePropertyScopeInput,
            mElement: kAudioObjectPropertyElementMain
        )
        var dataSize: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(deviceID, &address, 0, nil, &dataSize) == noErr,
              dataSize > 0 else { return 0 }

        let bufferListPtr = UnsafeMutableRawPointer.allocate(byteCount: Int(dataSize), alignment: MemoryLayout<AudioBufferList>.alignment)
        defer { bufferListPtr.deallocate() }
        guard AudioObjectGetPropertyData(deviceID, &address, 0, nil, &dataSize, bufferListPtr) == noErr else { return 0 }

        let bufferList = bufferListPtr.bindMemory(to: AudioBufferList.self, capacity: 1)
        let bufferCount = Int(bufferList.pointee.mNumberBuffers)
        return withUnsafePointer(to: bufferList.pointee.mBuffers) { ptr in
            let buffers = UnsafeBufferPointer<AudioBuffer>(start: ptr, count: bufferCount)
            return buffers.reduce(0) { $0 + Int($1.mNumberChannels) }
        }
    }

    private func stringProperty(_ selector: AudioObjectPropertySelector, for deviceID: AudioDeviceID) -> String? {
        var address = AudioObjectPropertyAddress(
            mSelector: selector,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var dataSize = UInt32(MemoryLayout<Unmanaged<CFString>>.size)
        var value: Unmanaged<CFString>? = nil
        guard AudioObjectGetPropertyData(deviceID, &address, 0, nil, &dataSize, &value) == noErr,
              let retained = value else { return nil }
        return retained.takeRetainedValue() as String
    }
}
