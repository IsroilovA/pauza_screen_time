package com.example.pauza_screen_time.core.method_channel

import com.example.pauza_screen_time.core.ChannelNames
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

internal class CoreChannelRegistrar {
    private var channel: MethodChannel? = null
    private var methodHandler: CoreMethodHandler? = null

    fun attach(messenger: BinaryMessenger) {
        methodHandler = CoreMethodHandler()
        channel = MethodChannel(messenger, ChannelNames.CORE).apply {
            setMethodCallHandler(methodHandler)
        }
    }

    fun detach() {
        channel?.setMethodCallHandler(null)
        channel = null
        methodHandler = null
    }
}

