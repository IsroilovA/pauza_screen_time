import Flutter

enum PermissionsRegistrar {
    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: ChannelNames.permissions,
            binaryMessenger: registrar.messenger()
        )
        let handler = PermissionsMethodHandler()
        channel.setMethodCallHandler { call, result in
            handler.handle(call, result: result)
        }
    }
}
