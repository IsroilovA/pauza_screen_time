import Flutter

enum RestrictionsRegistrar {
    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: ChannelNames.restrictions,
            binaryMessenger: registrar.messenger()
        )
        let handler = RestrictionsMethodHandler()
        channel.setMethodCallHandler { call, result in
            handler.handle(call, result: result)
        }
    }
}
