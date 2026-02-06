import Flutter

enum CoreRegistrar {
    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: ChannelNames.core,
            binaryMessenger: registrar.messenger()
        )
        let handler = CoreMethodHandler()
        channel.setMethodCallHandler { call, result in
            handler.handle(call, result: result)
        }
    }
}
