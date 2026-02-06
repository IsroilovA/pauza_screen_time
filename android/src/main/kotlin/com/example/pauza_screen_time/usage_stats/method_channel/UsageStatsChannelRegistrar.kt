package com.example.pauza_screen_time.usage_stats.method_channel

import android.content.Context
import com.example.pauza_screen_time.core.ChannelNames
import com.example.pauza_screen_time.usage_stats.UsageStatsHandler
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

internal class UsageStatsChannelRegistrar {
    private var channel: MethodChannel? = null
    private var usageStatsHandler: UsageStatsHandler? = null
    private var methodHandler: UsageStatsMethodHandler? = null

    fun attach(messenger: BinaryMessenger, context: Context) {
        usageStatsHandler = UsageStatsHandler(context)
        methodHandler = UsageStatsMethodHandler(usageStatsHandler!!)
        channel = MethodChannel(messenger, ChannelNames.USAGE_STATS).apply {
            setMethodCallHandler(methodHandler)
        }
    }

    fun detach() {
        channel?.setMethodCallHandler(null)
        channel = null
        methodHandler?.detach()
        methodHandler = null
        usageStatsHandler = null
    }
}
