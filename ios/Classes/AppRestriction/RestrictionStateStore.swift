import Foundation

/// Shared app-group-backed storage for restriction session state.
enum RestrictionStateStore {
    static let desiredRestrictedAppsKey = "desiredRestrictedApps"
    static let pausedUntilEpochMsKey = "pausedUntilEpochMs"

    enum StoreResult {
        case success
        case appGroupUnavailable(resolvedGroupId: String)
    }

    static func loadDesiredRestrictedApps() -> [String] {
        guard let defaults = AppGroupStore.sharedDefaults() else {
            return []
        }
        let values = defaults.array(forKey: desiredRestrictedAppsKey) as? [String] ?? []
        var unique: [String] = []
        var seen = Set<String>()
        unique.reserveCapacity(values.count)
        for token in values {
            if seen.insert(token).inserted {
                unique.append(token)
            }
        }
        return unique
    }

    @discardableResult
    static func storeDesiredRestrictedApps(_ tokens: [String]) -> StoreResult {
        let resolvedGroupId = AppGroupStore.effectiveGroupIdentifier()
        guard let defaults = UserDefaults(suiteName: resolvedGroupId) else {
            return .appGroupUnavailable(resolvedGroupId: resolvedGroupId)
        }
        defaults.set(tokens, forKey: desiredRestrictedAppsKey)
        return .success
    }

    static func loadPausedUntilEpochMs(nowEpochMs: Int64 = currentEpochMs()) -> Int64 {
        guard let defaults = AppGroupStore.sharedDefaults() else {
            return 0
        }
        let pausedUntil: Int64
        if let number = defaults.object(forKey: pausedUntilEpochMsKey) as? NSNumber {
            pausedUntil = number.int64Value
        } else if let raw = defaults.object(forKey: pausedUntilEpochMsKey) as? Int64 {
            pausedUntil = raw
        } else {
            pausedUntil = 0
        }
        if pausedUntil <= nowEpochMs {
            defaults.set(Int64(0), forKey: pausedUntilEpochMsKey)
            return 0
        }
        return pausedUntil
    }

    @discardableResult
    static func storePausedUntilEpochMs(_ epochMs: Int64) -> StoreResult {
        let resolvedGroupId = AppGroupStore.effectiveGroupIdentifier()
        guard let defaults = UserDefaults(suiteName: resolvedGroupId) else {
            return .appGroupUnavailable(resolvedGroupId: resolvedGroupId)
        }
        defaults.set(epochMs, forKey: pausedUntilEpochMsKey)
        return .success
    }

    static func currentEpochMs() -> Int64 {
        Int64(Date().timeIntervalSince1970 * 1000)
    }
}
