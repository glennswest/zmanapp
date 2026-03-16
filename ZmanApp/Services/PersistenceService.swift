import Foundation
import SwiftUI

@MainActor
final class PersistenceService: ObservableObject, Sendable {
    static let shared = PersistenceService()

    private let defaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private enum Keys {
        static let selectedBuildingId = "selectedBuildingId"
        static let selectedAreaId = "selectedAreaId"
        static let tunnelConfigs = "tunnelConfigs"
        static let serverURL = "serverURL"
        static let accessToken = "accessToken"
        static let refreshToken = "refreshToken"
        static let apiKey = "apiKey"
        static let hubId = "hubId"
        static let hubHostname = "hubHostname"
        static let claimEmail = "claimEmail"
        static let ipadMode = "ipadMode"
        static let ipadAssignedAreaId = "ipadAssignedAreaId"
        static let onboardingComplete = "onboardingComplete"
    }

    // MARK: - Server Config

    var serverURL: String {
        get { defaults.string(forKey: Keys.serverURL) ?? "" }
        set { defaults.set(newValue, forKey: Keys.serverURL) }
    }

    var accessToken: String {
        get { keychain(get: Keys.accessToken) ?? "" }
        set { keychain(set: newValue, forKey: Keys.accessToken) }
    }

    var refreshToken: String {
        get { keychain(get: Keys.refreshToken) ?? "" }
        set { keychain(set: newValue, forKey: Keys.refreshToken) }
    }

    var apiKey: String {
        get { keychain(get: Keys.apiKey) ?? "" }
        set { keychain(set: newValue, forKey: Keys.apiKey) }
    }

    var hubId: String {
        get { defaults.string(forKey: Keys.hubId) ?? "" }
        set { defaults.set(newValue, forKey: Keys.hubId) }
    }

    var hubHostname: String {
        get { defaults.string(forKey: Keys.hubHostname) ?? "" }
        set { defaults.set(newValue, forKey: Keys.hubHostname) }
    }

    var claimEmail: String {
        get { defaults.string(forKey: Keys.claimEmail) ?? "" }
        set { defaults.set(newValue, forKey: Keys.claimEmail) }
    }

    var onboardingComplete: Bool {
        get { defaults.bool(forKey: Keys.onboardingComplete) }
        set { defaults.set(newValue, forKey: Keys.onboardingComplete) }
    }

    // MARK: - Selection State

    var selectedBuildingId: UUID? {
        get {
            guard let str = defaults.string(forKey: Keys.selectedBuildingId) else { return nil }
            return UUID(uuidString: str)
        }
        set { defaults.set(newValue?.uuidString, forKey: Keys.selectedBuildingId) }
    }

    var selectedAreaId: UUID? {
        get {
            guard let str = defaults.string(forKey: Keys.selectedAreaId) else { return nil }
            return UUID(uuidString: str)
        }
        set { defaults.set(newValue?.uuidString, forKey: Keys.selectedAreaId) }
    }

    // MARK: - Display Mode

    enum DisplayMode: String {
        case general
        case room
        case garage
    }

    var displayMode: DisplayMode {
        get {
            guard let raw = defaults.string(forKey: Keys.ipadMode) else { return .general }
            return DisplayMode(rawValue: raw) ?? .general
        }
        set { defaults.set(newValue.rawValue, forKey: Keys.ipadMode) }
    }

    var assignedAreaId: UUID? {
        get {
            guard let str = defaults.string(forKey: Keys.ipadAssignedAreaId) else { return nil }
            return UUID(uuidString: str)
        }
        set { defaults.set(newValue?.uuidString, forKey: Keys.ipadAssignedAreaId) }
    }

    // MARK: - Keychain Helpers

    private func keychain(get key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: "com.zmanapp.app",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func keychain(set value: String, forKey key: String) {
        let data = Data(value.utf8)

        // Delete existing
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: "com.zmanapp.app",
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        guard !value.isEmpty else { return }

        // Add new
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: "com.zmanapp.app",
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
        ]
        SecItemAdd(addQuery as CFDictionary, nil)
    }

    // MARK: - Reset

    func resetAll() {
        serverURL = ""
        accessToken = ""
        refreshToken = ""
        apiKey = ""
        hubId = ""
        hubHostname = ""
        claimEmail = ""
        selectedBuildingId = nil
        selectedAreaId = nil
        displayMode = .general
        assignedAreaId = nil
        onboardingComplete = false
    }
}
