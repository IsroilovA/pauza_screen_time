import Flutter

enum PluginErrorCode {
    static let invalidArguments = "INVALID_ARGUMENT"
    static let settingsError = "SETTINGS_ERROR"
    static let viewControllerError = "VIEW_CONTROLLER_ERROR"
    static let appGroupError = "APP_GROUP_ERROR"
    static let unsupported = "UNSUPPORTED"
    static let invalidToken = "INVALID_TOKEN"
    static let unexpectedError = "UNEXPECTED_ERROR"
}

enum PluginErrorMessage {
    static let missingPermissionKey = "Missing or invalid 'permissionKey' argument"
    static let missingIdentifiers = "Missing or invalid 'identifiers' argument"
    static let missingIdentifier = "Missing or invalid 'identifier' argument"
    static let missingShieldConfiguration = "Missing or invalid shield configuration"
    static let unableToDecodeToken = "Unable to decode application token"
    static let unableToDecodeTokens = "Unable to decode application token(s)"
    static let appGroupUnavailable = "Unable to access App Group for shield configuration"
    static let settingsUrlCreationFailed = "Could not create settings URL"
    static let settingsOpenFailed = "Failed to open settings"
    static let settingsCannotOpen = "Cannot open settings URL"
    static let viewControllerUnavailable = "Could not get root view controller"
    static let restrictionsUnsupported = "App restrictions require iOS 16.0 or later"
    static let usageStatsUnsupported = "Usage stats are only supported on Android. On iOS, use DeviceActivityReport platform view for usage statistics."
}

enum PluginErrors {
    static func invalidArguments(_ message: String) -> FlutterError {
        FlutterError(code: PluginErrorCode.invalidArguments, message: message, details: nil)
    }

    static func settingsError(_ message: String) -> FlutterError {
        FlutterError(code: PluginErrorCode.settingsError, message: message, details: nil)
    }

    static func viewControllerError(_ message: String) -> FlutterError {
        FlutterError(code: PluginErrorCode.viewControllerError, message: message, details: nil)
    }

    static func appGroupError(details: [String: Any]) -> FlutterError {
        FlutterError(code: PluginErrorCode.appGroupError, message: PluginErrorMessage.appGroupUnavailable, details: details)
    }

    static func unsupported(_ message: String) -> FlutterError {
        FlutterError(code: PluginErrorCode.unsupported, message: message, details: nil)
    }

    static func invalidToken(message: String, invalidTokens: [String]) -> FlutterError {
        FlutterError(
            code: PluginErrorCode.invalidToken,
            message: message,
            details: ["invalidTokens": invalidTokens]
        )
    }

    static func unexpectedError(_ error: Error) -> FlutterError {
        FlutterError(
            code: PluginErrorCode.unexpectedError,
            message: "An unexpected error occurred: \(error.localizedDescription)",
            details: nil
        )
    }
}
