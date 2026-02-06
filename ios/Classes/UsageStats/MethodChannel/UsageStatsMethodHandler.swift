import Flutter

final class UsageStatsMethodHandler {
    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case MethodNames.queryUsageStats, MethodNames.queryAppUsageStats:
            result(PluginErrors.unsupported(PluginErrorMessage.usageStatsUnsupported))
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
