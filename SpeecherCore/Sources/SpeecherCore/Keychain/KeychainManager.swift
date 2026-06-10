import Foundation
import Security

/// Speichert und liest API-Keys sicher im macOS Keychain.
public enum KeychainManager {
    public enum Key: String {
        case openAI    = "com.steffen2301.speecher.apikey.openai"
        case anthropic = "com.steffen2301.speecher.apikey.anthropic"
        case deepl     = "com.steffen2301.speecher.apikey.deepl"
    }

    public static func save(_ value: String, for key: Key) throws {
        let data = Data(value.utf8)
        let query: [CFString: Any] = [
            kSecClass:            kSecClassGenericPassword,
            kSecAttrAccount:      key.rawValue,
            kSecValueData:        data,
            kSecAttrAccessible:   kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
        ]

        SecItemDelete(query as CFDictionary)

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
    }

    public static func load(for key: Key) throws -> String? {
        let query: [CFString: Any] = [
            kSecClass:            kSecClassGenericPassword,
            kSecAttrAccount:      key.rawValue,
            kSecReturnData:       true,
            kSecMatchLimit:       kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess else { throw KeychainError.loadFailed(status) }
        guard let data = result as? Data else { return nil }
        return String(decoding: data, as: UTF8.self)
    }

    public static func delete(for key: Key) {
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrAccount: key.rawValue,
        ]
        SecItemDelete(query as CFDictionary)
    }
}

public enum KeychainError: LocalizedError {
    case saveFailed(OSStatus)
    case loadFailed(OSStatus)

    public var errorDescription: String? {
        switch self {
        case .saveFailed(let s):  return "API-Key konnte nicht gespeichert werden (OSStatus \(s))."
        case .loadFailed(let s):  return "API-Key konnte nicht gelesen werden (OSStatus \(s))."
        }
    }
}
