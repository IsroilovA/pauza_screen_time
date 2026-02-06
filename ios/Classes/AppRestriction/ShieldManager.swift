import Foundation
import FamilyControls
import ManagedSettings

/// Wrapper around ManagedSettingsStore for app restriction management.
@available(iOS 16.0, *)
final class ShieldManager {
    static let shared = ShieldManager()
    private let store = ManagedSettingsStore()

    private init() {}

    func setRestrictedApps(_ tokens: Set<ApplicationToken>) {
        store.shield.applications = tokens
    }

    /// Decodes base64-encoded `ApplicationToken`s, preserving input order and de-duplicating by
    /// the original base64 strings.
    ///
    /// This does **not** mutate the current restrictions. Callers can decide whether to apply
    /// changes (e.g., fail-fast if any token is invalid).
    func decodeTokens(base64Tokens: [String]) -> TokenDecodeResult {
        var uniqueBase64Tokens: [String] = []
        uniqueBase64Tokens.reserveCapacity(base64Tokens.count)
        var seen = Set<String>()

        for value in base64Tokens {
            if seen.insert(value).inserted {
                uniqueBase64Tokens.append(value)
            }
        }

        var tokens = Set<ApplicationToken>()
        var invalidTokens: [String] = []
        invalidTokens.reserveCapacity(0)

        for tokenValue in uniqueBase64Tokens {
            if let token = decodeToken(tokenValue) {
                tokens.insert(token)
            } else {
                invalidTokens.append(tokenValue)
            }
        }

        return TokenDecodeResult(
            tokens: tokens,
            appliedBase64Tokens: invalidTokens.isEmpty ? uniqueBase64Tokens : [],
            invalidTokens: invalidTokens
        )
    }

    @discardableResult
    func addRestrictedApp(base64Token: String) -> Bool? {
        guard let token = decodeToken(base64Token) else { return nil }
        var current = store.shield.applications ?? Set<ApplicationToken>()
        let inserted = current.insert(token).inserted
        store.shield.applications = current
        return inserted
    }

    @discardableResult
    func removeRestrictedApp(base64Token: String) -> Bool? {
        guard let token = decodeToken(base64Token) else { return nil }
        var current = store.shield.applications ?? Set<ApplicationToken>()
        let removed = current.remove(token) != nil
        store.shield.applications = current
        return removed
    }

    func isRestricted(base64Token: String) -> Bool? {
        guard let token = decodeToken(base64Token) else { return nil }
        let current = store.shield.applications ?? Set<ApplicationToken>()
        return current.contains(token)
    }

    func clearRestrictions() {
        store.shield.applications = nil
        store.shield.webDomains = nil
    }

    func getRestrictedApps() -> [String] {
        guard let tokens = store.shield.applications else {
            return []
        }
        return tokens.compactMap { encodeToken($0) }
    }

    struct TokenDecodeResult {
        let tokens: Set<ApplicationToken>
        /// The base64 token strings that are valid and were intended to be applied, in input order,
        /// de-duplicated by base64 string.
        ///
        /// If `invalidTokens` is not empty, this will be an empty list to support fail-fast callers.
        let appliedBase64Tokens: [String]
        let invalidTokens: [String]
    }

    private func decodeToken(_ base64Token: String) -> ApplicationToken? {
        guard let data = Data(base64Encoded: base64Token) else {
            return nil
        }
        return try? JSONDecoder().decode(ApplicationToken.self, from: data)
    }

    private func encodeToken(_ token: ApplicationToken) -> String? {
        guard let data = try? JSONEncoder().encode(token) else {
            return nil
        }
        return data.base64EncodedString()
    }
}
