import Foundation

/// Shared App Group utilities for shield configuration and event storage.
enum AppGroupStore {
    static let defaultIdentifier = "group.com.example.pauza_screen_time"
    static let infoPlistKey = "AppGroupIdentifier"

    private(set) static var currentGroupIdentifier: String = resolveGroupIdentifier(nil)

    static func updateGroupIdentifier(_ override: String?) {
        currentGroupIdentifier = resolveGroupIdentifier(override)
    }

    static func sharedDefaults(groupId: String? = nil) -> UserDefaults? {
        let resolved = effectiveGroupIdentifier(groupId)
        return UserDefaults(suiteName: resolved)
    }

    static func effectiveGroupIdentifier(_ groupId: String? = nil) -> String {
        if groupId == nil {
            return currentGroupIdentifier
        }
        return resolveGroupIdentifier(groupId)
    }

    static func resolveGroupIdentifier(_ override: String?) -> String {
        if let override = override?.trimmingCharacters(in: .whitespacesAndNewlines),
           !override.isEmpty {
            return override
        }
        if let infoValue = Bundle.main.object(forInfoDictionaryKey: infoPlistKey) as? String,
           !infoValue.isEmpty {
            return infoValue
        }
        if let bundleId = Bundle.main.bundleIdentifier,
           !bundleId.isEmpty {
            return "group.\(bundleId)"
        }
        return defaultIdentifier
    }
}
