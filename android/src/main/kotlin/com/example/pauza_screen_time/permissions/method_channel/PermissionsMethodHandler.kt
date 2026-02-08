package com.example.pauza_screen_time.permissions.method_channel

import android.app.Activity
import com.example.pauza_screen_time.core.MethodNames
import com.example.pauza_screen_time.core.PluginErrorHelper
import com.example.pauza_screen_time.permissions.PermissionHandler
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class PermissionsMethodHandler(
    private val permissionHandler: PermissionHandler,
    private val activityProvider: () -> Activity?
) : MethodCallHandler {
    companion object {
        private const val FEATURE = "permissions"
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        try {
            when (call.method) {
                MethodNames.CHECK_PERMISSION -> handleCheckPermission(call, result)
                MethodNames.REQUEST_PERMISSION -> handleRequestPermission(call, result)
                MethodNames.OPEN_PERMISSION_SETTINGS -> handleOpenPermissionSettings(call, result)
                else -> result.notImplemented()
            }
        } catch (e: Exception) {
            PluginErrorHelper.internalFailure(
                result = result,
                feature = FEATURE,
                action = call.method,
                message = "Unexpected permissions error: ${e.message}",
                error = e,
            )
        }
    }

    private fun handleCheckPermission(call: MethodCall, result: Result) {
        val permissionKey = call.argument<String>("permissionKey")
        if (permissionKey == null) {
            PluginErrorHelper.invalidArgument(
                result = result,
                feature = FEATURE,
                action = MethodNames.CHECK_PERMISSION,
                message = "Missing or invalid 'permissionKey' argument",
            )
            return
        }
        val status = permissionHandler.checkPermission(permissionKey)
        result.success(status)
    }

    private fun handleRequestPermission(call: MethodCall, result: Result) {
        val permissionKey = call.argument<String>("permissionKey")
        if (permissionKey == null) {
            PluginErrorHelper.invalidArgument(
                result = result,
                feature = FEATURE,
                action = MethodNames.REQUEST_PERMISSION,
                message = "Missing or invalid 'permissionKey' argument",
            )
            return
        }

        val currentActivity = activityProvider()
        if (currentActivity == null) {
            PluginErrorHelper.internalFailure(
                result = result,
                feature = FEATURE,
                action = MethodNames.REQUEST_PERMISSION,
                message = "No activity available for permission request",
            )
            return
        }

        val requested = permissionHandler.requestPermission(currentActivity, permissionKey)
        result.success(requested)
    }

    private fun handleOpenPermissionSettings(call: MethodCall, result: Result) {
        val permissionKey = call.argument<String>("permissionKey")
        if (permissionKey == null) {
            PluginErrorHelper.invalidArgument(
                result = result,
                feature = FEATURE,
                action = MethodNames.OPEN_PERMISSION_SETTINGS,
                message = "Missing or invalid 'permissionKey' argument",
            )
            return
        }

        val currentActivity = activityProvider()
        if (currentActivity == null) {
            PluginErrorHelper.internalFailure(
                result = result,
                feature = FEATURE,
                action = MethodNames.OPEN_PERMISSION_SETTINGS,
                message = "No activity available for opening settings",
            )
            return
        }

        try {
            permissionHandler.openPermissionSettings(currentActivity, permissionKey)
            result.success(null)
        } catch (e: Exception) {
            PluginErrorHelper.internalFailure(
                result = result,
                feature = FEATURE,
                action = MethodNames.OPEN_PERMISSION_SETTINGS,
                message = "Failed to open permission settings: ${e.message}",
                error = e,
            )
        }
    }
}
