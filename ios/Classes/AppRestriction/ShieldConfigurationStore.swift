import Foundation

/// Stores shield configuration for the ShieldConfiguration extension.
enum ShieldConfigurationStore {
    static let configurationKey = "shieldConfiguration"

    enum StoreResult {
        case success
        case appGroupUnavailable(resolvedGroupId: String)
    }

    @discardableResult
    static func storeConfiguration(_ configuration: [String: Any], appGroupId: String? = nil) -> StoreResult {
        let resolvedGroupId = AppGroupStore.resolveGroupIdentifier(appGroupId)
        guard let defaults = UserDefaults(suiteName: resolvedGroupId) else {
            return .appGroupUnavailable(resolvedGroupId: resolvedGroupId)
        }
        defaults.set(configuration, forKey: configurationKey)
        return .success
    }

    static func loadConfiguration(appGroupId: String? = nil) -> [String: Any]? {
        guard let defaults = AppGroupStore.sharedDefaults(groupId: appGroupId) else {
            return nil
        }
        return defaults.dictionary(forKey: configurationKey)
    }
}
