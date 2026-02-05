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

    @discardableResult
    func setRestrictedApps(base64Tokens: [String]) -> [String] {
        let decodeResult = decodeTokens(base64Tokens)
        setRestrictedApps(decodeResult.tokens)
        return decodeResult.invalidTokens
    }

    @discardableResult
    func addRestrictedApp(base64Token: String) -> Bool {
        guard let token = decodeToken(base64Token) else {
            return false
        }
        var current = store.shield.applications ?? Set<ApplicationToken>()
        current.insert(token)
        store.shield.applications = current
        return true
    }

    @discardableResult
    func removeRestrictedApp(base64Token: String) -> Bool {
        guard let token = decodeToken(base64Token) else {
            return false
        }
        var current = store.shield.applications ?? Set<ApplicationToken>()
        current.remove(token)
        store.shield.applications = current
        return true
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

    private struct TokenDecodeResult {
        let tokens: Set<ApplicationToken>
        let invalidTokens: [String]
    }

    private func decodeTokens(_ base64Tokens: [String]) -> TokenDecodeResult {
        var tokens = Set<ApplicationToken>()
        var invalidTokens = [String]()
        for tokenValue in base64Tokens {
            if let token = decodeToken(tokenValue) {
                tokens.insert(token)
            } else {
                invalidTokens.append(tokenValue)
            }
        }
        return TokenDecodeResult(tokens: tokens, invalidTokens: invalidTokens)
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
