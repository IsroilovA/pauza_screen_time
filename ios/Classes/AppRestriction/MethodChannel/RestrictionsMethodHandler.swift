import Flutter
import Foundation

final class RestrictionsMethodHandler {
    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case MethodNames.configureShield:
            handleConfigureShield(call: call, result: result)
        case MethodNames.setRestrictedApps:
            handleSetRestrictedApps(call: call, result: result)
        case MethodNames.addRestrictedApp:
            handleAddRestrictedApp(call: call, result: result)
        case MethodNames.removeRestriction:
            handleRemoveRestriction(call: call, result: result)
        case MethodNames.isRestricted:
            handleIsRestricted(call: call, result: result)
        case MethodNames.removeAllRestrictions:
            handleRemoveAllRestrictions(call: call, result: result)
        case MethodNames.getRestrictedApps:
            handleGetRestrictedApps(call: call, result: result)
        case MethodNames.isRestrictionSessionActiveNow:
            handleIsRestrictionSessionActiveNow(result: result)
        case MethodNames.isRestrictionSessionConfigured:
            handleIsRestrictionSessionConfigured(result: result)
        case MethodNames.pauseEnforcement:
            handlePauseEnforcement(call: call, result: result)
        case MethodNames.resumeEnforcement:
            handleResumeEnforcement(result: result)
        case MethodNames.getRestrictionSession:
            handleGetRestrictionSession(result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func handleConfigureShield(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard var configuration = call.arguments as? [String: Any] else {
            result(PluginErrors.invalidArguments(PluginErrorMessage.missingShieldConfiguration))
            return
        }

        let appGroupId = configuration["appGroupId"] as? String
        AppGroupStore.updateGroupIdentifier(appGroupId)
        configuration.removeValue(forKey: "appGroupId")

        if let typedData = configuration["iconBytes"] as? FlutterStandardTypedData {
            configuration["iconBytes"] = typedData.data
        } else if configuration["iconBytes"] is NSNull {
            configuration.removeValue(forKey: "iconBytes")
        }

        switch ShieldConfigurationStore.storeConfiguration(configuration, appGroupId: appGroupId) {
        case .success:
            result(nil)
        case .appGroupUnavailable(let resolvedGroupId):
            var details: [String: Any] = [
                "resolvedAppGroupId": resolvedGroupId
            ]
            if let appGroupId {
                details["appGroupId"] = appGroupId
            } else {
                details["appGroupId"] = NSNull()
            }
            result(PluginErrors.appGroupError(details: details))
        }
    }

    private func handleSetRestrictedApps(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard #available(iOS 16.0, *) else {
            result(PluginErrors.unsupported(PluginErrorMessage.restrictionsUnsupported))
            return
        }
        guard let args = call.arguments as? [String: Any],
              let tokens = args["identifiers"] as? [String] else {
            result(PluginErrors.invalidArguments(PluginErrorMessage.missingIdentifiers))
            return
        }
        let decodeResult = ShieldManager.shared.decodeTokens(base64Tokens: tokens)
        if !decodeResult.invalidTokens.isEmpty {
            result(PluginErrors.invalidToken(
                message: PluginErrorMessage.unableToDecodeTokens,
                invalidTokens: decodeResult.invalidTokens
            ))
            return
        }

        switch RestrictionStateStore.storeDesiredRestrictedApps(decodeResult.appliedBase64Tokens) {
        case .success:
            break
        case .appGroupUnavailable(let resolvedGroupId):
            result(appGroupError(resolvedGroupId: resolvedGroupId))
            return
        }

        applyDesiredRestrictionsIfNeeded()
        result(decodeResult.appliedBase64Tokens)
    }

    private func handleAddRestrictedApp(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard #available(iOS 16.0, *) else {
            result(PluginErrors.unsupported(PluginErrorMessage.restrictionsUnsupported))
            return
        }
        guard let args = call.arguments as? [String: Any],
              let token = args["identifier"] as? String else {
            result(PluginErrors.invalidArguments(PluginErrorMessage.missingIdentifier))
            return
        }

        let decodeResult = ShieldManager.shared.decodeTokens(base64Tokens: [token])
        if !decodeResult.invalidTokens.isEmpty {
            result(PluginErrors.invalidToken(
                message: PluginErrorMessage.unableToDecodeToken,
                invalidTokens: decodeResult.invalidTokens
            ))
            return
        }

        ensureDesiredRestrictionsInitializedFromManagedStore()
        var desired = RestrictionStateStore.loadDesiredRestrictedApps()
        if desired.contains(token) {
            result(false)
            return
        }
        desired.append(token)

        switch RestrictionStateStore.storeDesiredRestrictedApps(desired) {
        case .success:
            break
        case .appGroupUnavailable(let resolvedGroupId):
            result(appGroupError(resolvedGroupId: resolvedGroupId))
            return
        }

        applyDesiredRestrictionsIfNeeded()
        result(true)
    }

    private func handleRemoveRestriction(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard #available(iOS 16.0, *) else {
            result(PluginErrors.unsupported(PluginErrorMessage.restrictionsUnsupported))
            return
        }
        guard let args = call.arguments as? [String: Any],
              let token = args["identifier"] as? String else {
            result(PluginErrors.invalidArguments(PluginErrorMessage.missingIdentifier))
            return
        }

        let decodeResult = ShieldManager.shared.decodeTokens(base64Tokens: [token])
        if !decodeResult.invalidTokens.isEmpty {
            result(PluginErrors.invalidToken(
                message: PluginErrorMessage.unableToDecodeToken,
                invalidTokens: decodeResult.invalidTokens
            ))
            return
        }

        ensureDesiredRestrictionsInitializedFromManagedStore()
        var desired = RestrictionStateStore.loadDesiredRestrictedApps()
        let previousCount = desired.count
        desired.removeAll { $0 == token }
        let changed = desired.count != previousCount

        switch RestrictionStateStore.storeDesiredRestrictedApps(desired) {
        case .success:
            break
        case .appGroupUnavailable(let resolvedGroupId):
            result(appGroupError(resolvedGroupId: resolvedGroupId))
            return
        }

        applyDesiredRestrictionsIfNeeded()
        result(changed)
    }

    private func handleIsRestricted(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard #available(iOS 16.0, *) else {
            result(PluginErrors.unsupported(PluginErrorMessage.restrictionsUnsupported))
            return
        }
        guard let args = call.arguments as? [String: Any],
              let token = args["identifier"] as? String else {
            result(PluginErrors.invalidArguments(PluginErrorMessage.missingIdentifier))
            return
        }

        let decodeResult = ShieldManager.shared.decodeTokens(base64Tokens: [token])
        if !decodeResult.invalidTokens.isEmpty {
            result(PluginErrors.invalidToken(
                message: PluginErrorMessage.unableToDecodeToken,
                invalidTokens: decodeResult.invalidTokens
            ))
            return
        }
        ensureDesiredRestrictionsInitializedFromManagedStore()
        let restricted = RestrictionStateStore.loadDesiredRestrictedApps().contains(token)
        result(restricted)
    }

    private func handleRemoveAllRestrictions(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard #available(iOS 16.0, *) else {
            result(PluginErrors.unsupported(PluginErrorMessage.restrictionsUnsupported))
            return
        }

        switch RestrictionStateStore.storeDesiredRestrictedApps([]) {
        case .success:
            break
        case .appGroupUnavailable(let resolvedGroupId):
            result(appGroupError(resolvedGroupId: resolvedGroupId))
            return
        }

        ShieldManager.shared.clearRestrictions()
        result(nil)
    }

    private func handleGetRestrictedApps(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard #available(iOS 16.0, *) else {
            result([])
            return
        }
        ensureDesiredRestrictionsInitializedFromManagedStore()
        let tokens = RestrictionStateStore.loadDesiredRestrictedApps()
        result(tokens)
    }

    private func handleIsRestrictionSessionActiveNow(result: @escaping FlutterResult) {
        guard #available(iOS 16.0, *) else {
            result(false)
            return
        }

        ensureDesiredRestrictionsInitializedFromManagedStore()
        applyDesiredRestrictionsIfNeeded()
        let restrictedApps = RestrictionStateStore.loadDesiredRestrictedApps()
        let isPausedNow = RestrictionStateStore.loadPausedUntilEpochMs() > 0
        result(!restrictedApps.isEmpty && !isPausedNow)
    }

    private func handleIsRestrictionSessionConfigured(result: @escaping FlutterResult) {
        guard #available(iOS 16.0, *) else {
            result(false)
            return
        }

        ensureDesiredRestrictionsInitializedFromManagedStore()
        let restrictedApps = RestrictionStateStore.loadDesiredRestrictedApps()
        result(!restrictedApps.isEmpty)
    }

    private func handlePauseEnforcement(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard #available(iOS 16.0, *) else {
            result(PluginErrors.unsupported(PluginErrorMessage.restrictionsUnsupported))
            return
        }

        guard let args = call.arguments as? [String: Any],
              let durationValue = args["durationMs"] as? NSNumber else {
            result(PluginErrors.invalidArguments("Missing or invalid 'durationMs' argument"))
            return
        }
        let durationMs = durationValue.int64Value
        if durationMs <= 0 {
            result(PluginErrors.invalidArguments("Missing or invalid 'durationMs' argument"))
            return
        }

        if RestrictionStateStore.loadPausedUntilEpochMs() > 0 {
            result(PluginErrors.invalidArguments("Restriction enforcement is already paused"))
            return
        }

        let pausedUntilEpochMs = RestrictionStateStore.currentEpochMs() + durationMs
        switch RestrictionStateStore.storePausedUntilEpochMs(pausedUntilEpochMs) {
        case .success:
            break
        case .appGroupUnavailable(let resolvedGroupId):
            result(appGroupError(resolvedGroupId: resolvedGroupId))
            return
        }

        ShieldManager.shared.clearRestrictions()
        result(nil)
    }

    private func handleResumeEnforcement(result: @escaping FlutterResult) {
        guard #available(iOS 16.0, *) else {
            result(PluginErrors.unsupported(PluginErrorMessage.restrictionsUnsupported))
            return
        }

        switch RestrictionStateStore.storePausedUntilEpochMs(0) {
        case .success:
            break
        case .appGroupUnavailable(let resolvedGroupId):
            result(appGroupError(resolvedGroupId: resolvedGroupId))
            return
        }

        applyDesiredRestrictionsIfNeeded()
        result(nil)
    }

    private func handleGetRestrictionSession(result: @escaping FlutterResult) {
        guard #available(iOS 16.0, *) else {
            result([
                "isActiveNow": false,
                "isPausedNow": false,
                "pausedUntilEpochMs": NSNull(),
                "restrictedApps": [String]()
            ])
            return
        }

        ensureDesiredRestrictionsInitializedFromManagedStore()
        applyDesiredRestrictionsIfNeeded()
        let restrictedApps = RestrictionStateStore.loadDesiredRestrictedApps()
        let pausedUntilEpochMs = RestrictionStateStore.loadPausedUntilEpochMs()
        let isPausedNow = pausedUntilEpochMs > 0
        result([
            "isActiveNow": !restrictedApps.isEmpty && !isPausedNow,
            "isPausedNow": isPausedNow,
            "pausedUntilEpochMs": isPausedNow ? pausedUntilEpochMs : NSNull(),
            "restrictedApps": restrictedApps
        ])
    }

    @available(iOS 16.0, *)
    private func applyDesiredRestrictionsIfNeeded() {
        ensureDesiredRestrictionsInitializedFromManagedStore()
        let desiredRestrictedApps = RestrictionStateStore.loadDesiredRestrictedApps()
        if desiredRestrictedApps.isEmpty {
            ShieldManager.shared.clearRestrictions()
            return
        }

        let isPausedNow = RestrictionStateStore.loadPausedUntilEpochMs() > 0
        if isPausedNow {
            ShieldManager.shared.clearRestrictions()
            return
        }

        let decodeResult = ShieldManager.shared.decodeTokens(base64Tokens: desiredRestrictedApps)
        if !decodeResult.invalidTokens.isEmpty {
            ShieldManager.shared.clearRestrictions()
            return
        }
        ShieldManager.shared.setRestrictedApps(decodeResult.tokens)
    }

    private func appGroupError(resolvedGroupId: String) -> FlutterError {
        PluginErrors.appGroupError(
            details: [
                "resolvedAppGroupId": resolvedGroupId,
                "appGroupId": AppGroupStore.currentGroupIdentifier
            ]
        )
    }

    @available(iOS 16.0, *)
    private func ensureDesiredRestrictionsInitializedFromManagedStore() {
        let desiredRestrictedApps = RestrictionStateStore.loadDesiredRestrictedApps()
        if !desiredRestrictedApps.isEmpty {
            return
        }

        let currentlyApplied = ShieldManager.shared.getRestrictedApps()
        if currentlyApplied.isEmpty {
            return
        }

        _ = RestrictionStateStore.storeDesiredRestrictedApps(currentlyApplied)
    }
}
