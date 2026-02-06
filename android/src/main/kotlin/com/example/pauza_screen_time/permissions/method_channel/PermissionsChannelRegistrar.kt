package com.example.pauza_screen_time.permissions.method_channel

import android.app.Activity
import android.content.Context
import com.example.pauza_screen_time.core.ChannelNames
import com.example.pauza_screen_time.permissions.PermissionHandler
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

internal class PermissionsChannelRegistrar {
    private var channel: MethodChannel? = null
    private var permissionHandler: PermissionHandler? = null
    private var methodHandler: PermissionsMethodHandler? = null

    fun attach(
        messenger: BinaryMessenger,
        context: Context,
        activityProvider: () -> Activity?
    ) {
        permissionHandler = PermissionHandler(context)
        methodHandler = PermissionsMethodHandler(permissionHandler!!, activityProvider)
        channel = MethodChannel(messenger, ChannelNames.PERMISSIONS).apply {
            setMethodCallHandler(methodHandler)
        }
    }

    fun detach() {
        channel?.setMethodCallHandler(null)
        channel = null
        methodHandler = null
        permissionHandler = null
    }
}
