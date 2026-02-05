/// Main plugin entry point for the Pauza Screen Time plugin on iOS.
///
/// Handles method channel communication between Flutter and native iOS code,
/// routing calls to the appropriate handlers for permissions, installed apps,
/// usage statistics, and app restriction functionality.

import Flutter
import UIKit
import SwiftUI

public class PauzaScreenTimePlugin: NSObject, FlutterPlugin {

    /// Registers the plugin with the Flutter engine.
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "pauza_screen_time",
            binaryMessenger: registrar.messenger()
        )
        let instance = PauzaScreenTimePlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)

        registrar.register(
            UsageReportViewFactory(messenger: registrar.messenger()),
            withId: UsageReportViewFactory.viewType
        )
    }
    
    /// Handles incoming method calls from Flutter.
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getPlatformVersion":
            result("iOS " + UIDevice.current.systemVersion)
            
        // MARK: - Permission Methods
            
        case "checkPermission":
            handleCheckPermission(call: call, result: result)
            
        case "requestPermission":
            handleRequestPermission(call: call, result: result)
            
        case "openPermissionSettings":
            handleOpenPermissionSettings(call: call, result: result)
            
        // MARK: - Installed Apps Methods
            
        case "showFamilyActivityPicker":
            handleShowFamilyActivityPicker(call: call, result: result)

        // MARK: - App Restriction Methods

        case "configureShield":
            handleConfigureShield(call: call, result: result)

        case "setRestrictedApps":
            handleSetRestrictedApps(call: call, result: result)

        case "removeRestriction":
            handleRemoveRestriction(call: call, result: result)

        case "removeAllRestrictions":
            handleRemoveAllRestrictions(call: call, result: result)

        case "getRestrictedApps":
            handleGetRestrictedApps(call: call, result: result)
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    // MARK: - Permission Handlers
    
    /// Handles the checkPermission method call.
    private func handleCheckPermission(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let permissionKey = args["permissionKey"] as? String else {
            result(FlutterError(
                code: "INVALID_ARGUMENTS",
                message: "Missing or invalid 'permissionKey' argument",
                details: nil
            ))
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
    
    /// Handles the requestPermission method call.
    private func handleRequestPermission(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let permissionKey = args["permissionKey"] as? String else {
            result(FlutterError(
                code: "INVALID_ARGUMENTS",
                message: "Missing or invalid 'permissionKey' argument",
                details: nil
            ))
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
    
    /// Handles the openPermissionSettings method call.
    ///
    /// On iOS, there is no direct way to open Screen Time settings programmatically.
    /// This opens the app's general settings page instead.
    private func handleOpenPermissionSettings(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
            result(FlutterError(
                code: "SETTINGS_ERROR",
                message: "Could not create settings URL",
                details: nil
            ))
            return
        }
        
        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl, options: [:]) { success in
                if success {
                    result(nil)
                } else {
                    result(FlutterError(
                        code: "SETTINGS_ERROR",
                        message: "Failed to open settings",
                        details: nil
                    ))
                }
            }
        } else {
            result(FlutterError(
                code: "SETTINGS_ERROR",
                message: "Cannot open settings URL",
                details: nil
            ))
        }
    }
    
    // MARK: - Installed Apps Handlers
    
    /// Handles the showFamilyActivityPicker method call.
    ///
    /// Presents the iOS FamilyActivityPicker for the user to select apps.
    /// Accepts optional preSelectedTokens to show apps as pre-selected.
    /// Returns a list of maps containing applicationToken (base64) and platform.
    private func handleShowFamilyActivityPicker(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard #available(iOS 16.0, *) else {
            // FamilyActivityPicker requires iOS 16.0+
            result([])
            return
        }
        
        // Get a view controller suitable for presenting UI (multi-scene safe).
        guard let viewController = getPresentationViewController() else {
            result(FlutterError(
                code: "VIEW_CONTROLLER_ERROR",
                message: "Could not get root view controller",
                details: nil
            ))
            return
        }
        
        // Extract pre-selected tokens from arguments
        var preSelectedTokens: [String]? = nil
        if let args = call.arguments as? [String: Any],
           let tokens = args["preSelectedTokens"] as? [String] {
            preSelectedTokens = tokens
        }
        
        // Present the picker with pre-selected tokens
        FamilyActivityPickerHandler.shared.showPicker(
            from: viewController,
            preSelectedTokens: preSelectedTokens
        ) { selectedApps in
            result(selectedApps)
        }
    }

    // MARK: - App Restriction Handlers

    private func handleConfigureShield(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard var configuration = call.arguments as? [String: Any] else {
            result(FlutterError(
                code: "INVALID_ARGUMENTS",
                message: "Missing or invalid shield configuration",
                details: nil
            ))
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
            result(FlutterError(
                code: "APP_GROUP_ERROR",
                message: "Unable to access App Group for shield configuration",
                details: details
            ))
        }
    }

    private func handleSetRestrictedApps(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard #available(iOS 16.0, *) else {
            result(FlutterError(
                code: "UNSUPPORTED",
                message: "App restrictions require iOS 16.0 or later",
                details: nil
            ))
            return
        }
        guard let args = call.arguments as? [String: Any],
              let tokens = args["packageIds"] as? [String] else {
            result(FlutterError(
                code: "INVALID_ARGUMENTS",
                message: "Missing or invalid 'packageIds' argument",
                details: nil
            ))
            return
        }
        let invalidTokens = ShieldManager.shared.setRestrictedApps(base64Tokens: tokens)
        result([
            "invalidTokens": invalidTokens
        ])
    }

    private func handleRemoveRestriction(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard #available(iOS 16.0, *) else {
            result(FlutterError(
                code: "UNSUPPORTED",
                message: "App restrictions require iOS 16.0 or later",
                details: nil
            ))
            return
        }
        guard let args = call.arguments as? [String: Any],
              let token = args["packageId"] as? String else {
            result(FlutterError(
                code: "INVALID_ARGUMENTS",
                message: "Missing or invalid 'packageId' argument",
                details: nil
            ))
            return
        }
        if ShieldManager.shared.removeRestrictedApp(base64Token: token) {
            result(nil)
        } else {
            result(FlutterError(
                code: "INVALID_TOKEN",
                message: "Unable to decode application token",
                details: [
                    "invalidTokens": [token]
                ]
            ))
        }
    }

    private func handleRemoveAllRestrictions(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard #available(iOS 16.0, *) else {
            result(FlutterError(
                code: "UNSUPPORTED",
                message: "App restrictions require iOS 16.0 or later",
                details: nil
            ))
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
    
    // MARK: - Helper Methods
    
    /// Returns a UIViewController suitable for presenting modal UI.
    ///
    /// Preference order:
    /// - Active scene's key window root view controller
    /// - Any scene window's root view controller
    private func getPresentationViewController() -> UIViewController? {
        if #available(iOS 13.0, *) {
            let scenes = UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .filter { scene in
                    scene.activationState == .foregroundActive || scene.activationState == .foregroundInactive
                }

            for scene in scenes {
                if let root = (scene.windows.first(where: { $0.isKeyWindow }) ??
                               scene.windows.first(where: { !$0.isHidden }) ??
                               scene.windows.first)?.rootViewController {
                    return topMostViewController(from: root)
                }
            }

            // Fallback: any window from any scene.
            for scene in UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }) {
                if let root = scene.windows.first?.rootViewController {
                    return topMostViewController(from: root)
                }
            }
            return nil
        } else {
            return topMostViewController(from: UIApplication.shared.keyWindow?.rootViewController)
        }
    }

    private func topMostViewController(from root: UIViewController?) -> UIViewController? {
        var current = root
        while let presented = current?.presentedViewController {
            current = presented
        }
        return current
    }
}
