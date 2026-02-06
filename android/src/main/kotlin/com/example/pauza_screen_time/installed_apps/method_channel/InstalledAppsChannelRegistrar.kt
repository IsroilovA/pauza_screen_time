package com.example.pauza_screen_time.installed_apps.method_channel

import android.content.Context
import com.example.pauza_screen_time.core.ChannelNames
import com.example.pauza_screen_time.installed_apps.InstalledAppsHandler
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

internal class InstalledAppsChannelRegistrar {
    private var channel: MethodChannel? = null
    private var installedAppsHandler: InstalledAppsHandler? = null
    private var methodHandler: InstalledAppsMethodHandler? = null

    fun attach(messenger: BinaryMessenger, context: Context) {
        installedAppsHandler = InstalledAppsHandler(context)
        methodHandler = InstalledAppsMethodHandler(installedAppsHandler!!)
        channel = MethodChannel(messenger, ChannelNames.INSTALLED_APPS).apply {
            setMethodCallHandler(methodHandler)
        }
    }

    fun detach() {
        channel?.setMethodCallHandler(null)
        channel = null
        methodHandler?.detach()
        methodHandler = null
        installedAppsHandler = null
    }
}
