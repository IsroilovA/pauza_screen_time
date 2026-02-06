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
              let tokens = args["packageIds"] as? [String] else {
            result(PluginErrors.invalidArguments(PluginErrorMessage.missingPackageIds))
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

        ShieldManager.shared.setRestrictedApps(decodeResult.tokens)
        result(decodeResult.appliedBase64Tokens)
    }

    private func handleAddRestrictedApp(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard #available(iOS 16.0, *) else {
            result(PluginErrors.unsupported(PluginErrorMessage.restrictionsUnsupported))
            return
        }
        guard let args = call.arguments as? [String: Any],
              let token = args["packageId"] as? String else {
            result(PluginErrors.invalidArguments(PluginErrorMessage.missingPackageId))
            return
        }

        guard let changed = ShieldManager.shared.addRestrictedApp(base64Token: token) else {
            result(PluginErrors.invalidToken(
                message: PluginErrorMessage.unableToDecodeToken,
                invalidTokens: [token]
            ))
            return
        }
        result(changed)
    }

    private func handleRemoveRestriction(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard #available(iOS 16.0, *) else {
            result(PluginErrors.unsupported(PluginErrorMessage.restrictionsUnsupported))
            return
        }
        guard let args = call.arguments as? [String: Any],
              let token = args["packageId"] as? String else {
            result(PluginErrors.invalidArguments(PluginErrorMessage.missingPackageId))
            return
        }
        guard let changed = ShieldManager.shared.removeRestrictedApp(base64Token: token) else {
            result(PluginErrors.invalidToken(
                message: PluginErrorMessage.unableToDecodeToken,
                invalidTokens: [token]
            ))
            return
        }
        result(changed)
    }

    private func handleIsRestricted(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard #available(iOS 16.0, *) else {
            result(PluginErrors.unsupported(PluginErrorMessage.restrictionsUnsupported))
            return
        }
        guard let args = call.arguments as? [String: Any],
              let token = args["packageId"] as? String else {
            result(PluginErrors.invalidArguments(PluginErrorMessage.missingPackageId))
            return
        }

        guard let restricted = ShieldManager.shared.isRestricted(base64Token: token) else {
            result(PluginErrors.invalidToken(
                message: PluginErrorMessage.unableToDecodeToken,
                invalidTokens: [token]
            ))
            return
        }
        result(restricted)
    }

    private func handleRemoveAllRestrictions(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard #available(iOS 16.0, *) else {
            result(PluginErrors.unsupported(PluginErrorMessage.restrictionsUnsupported))
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
        let tokens = ShieldManager.shared.getRestrictedApps()
        result(tokens)
    }
}
