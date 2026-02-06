import Flutter

enum InstalledAppsRegistrar {
    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: ChannelNames.installedApps,
            binaryMessenger: registrar.messenger()
        )
        let handler = InstalledAppsMethodHandler()
        channel.setMethodCallHandler { call, result in
            handler.handle(call, result: result)
        }
    }
}
