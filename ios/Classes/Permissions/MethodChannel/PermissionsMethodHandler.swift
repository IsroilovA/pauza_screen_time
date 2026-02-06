import Flutter
import UIKit

final class PermissionsMethodHandler {
    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case MethodNames.checkPermission:
            handleCheckPermission(call: call, result: result)
        case MethodNames.requestPermission:
            handleRequestPermission(call: call, result: result)
        case MethodNames.openPermissionSettings:
            handleOpenPermissionSettings(call: call, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func handleCheckPermission(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let permissionKey = args["permissionKey"] as? String else {
            result(PluginErrors.invalidArguments(PluginErrorMessage.missingPermissionKey))
            return
        }

        if #available(iOS 16.0, *) {
            let status = PermissionHandler.shared.checkPermission(permissionKey: permissionKey)
            result(status)
        } else {
            let status = LegacyPermissionHandler.shared.checkPermission(permissionKey: permissionKey)
            result(status)
        }
    }

    private func handleRequestPermission(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let permissionKey = args["permissionKey"] as? String else {
            result(PluginErrors.invalidArguments(PluginErrorMessage.missingPermissionKey))
            return
        }

        if #available(iOS 16.0, *) {
            PermissionHandler.shared.requestPermission(permissionKey: permissionKey) { granted in
                result(granted)
            }
        } else {
            LegacyPermissionHandler.shared.requestPermission(permissionKey: permissionKey) { granted in
                result(granted)
            }
        }
    }

    private func handleOpenPermissionSettings(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
            result(PluginErrors.settingsError(PluginErrorMessage.settingsUrlCreationFailed))
            return
        }

        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl, options: [:]) { success in
                if success {
                    result(nil)
                } else {
                    result(PluginErrors.settingsError(PluginErrorMessage.settingsOpenFailed))
                }
            }
        } else {
            result(PluginErrors.settingsError(PluginErrorMessage.settingsCannotOpen))
        }
    }
}
