import Flutter

enum UsageStatsRegistrar {
    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: ChannelNames.usageStats,
            binaryMessenger: registrar.messenger()
        )
        let handler = UsageStatsMethodHandler()
        channel.setMethodCallHandler { call, result in
            handler.handle(call, result: result)
        }
    }
}
