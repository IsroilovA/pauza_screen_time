package com.example.pauza_screen_time.installed_apps.method_channel

import com.example.pauza_screen_time.core.MethodNames
import com.example.pauza_screen_time.core.PluginErrorHelper
import com.example.pauza_screen_time.core.PluginErrors
import com.example.pauza_screen_time.installed_apps.InstalledAppsHandler
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class InstalledAppsMethodHandler(
    private val installedAppsHandler: InstalledAppsHandler
) : MethodCallHandler {
    override fun onMethodCall(call: MethodCall, result: Result) {
        try {
            when (call.method) {
                MethodNames.GET_INSTALLED_APPS -> handleGetInstalledApps(call, result)
                MethodNames.GET_APP_INFO -> handleGetAppInfo(call, result)
                else -> result.notImplemented()
            }
        } catch (e: Exception) {
            PluginErrorHelper.unexpectedError(result, e)
        }
    }

    private fun handleGetInstalledApps(call: MethodCall, result: Result) {
        val includeSystemApps = call.argument<Boolean>("includeSystemApps") ?: false
        val includeIcons = call.argument<Boolean>("includeIcons") ?: true

        try {
            val apps = installedAppsHandler.getInstalledApps(includeSystemApps, includeIcons)
            result.success(apps)
        } catch (e: Exception) {
            PluginErrorHelper.error(
                result,
                PluginErrors.CODE_GET_APPS_ERROR,
                "Failed to get installed apps: ${e.message}",
                e
            )
        }
    }

    private fun handleGetAppInfo(call: MethodCall, result: Result) {
        val packageId = call.argument<String>("packageId")
        val includeIcons = call.argument<Boolean>("includeIcons") ?: true

        if (packageId == null) {
            PluginErrorHelper.invalidArgument(result, "Package ID is required")
            return
        }

        try {
            val appInfo = installedAppsHandler.getAppInfo(packageId, includeIcons)
            result.success(appInfo)
        } catch (e: Exception) {
            PluginErrorHelper.error(
                result,
                PluginErrors.CODE_GET_APP_INFO_ERROR,
                "Failed to get app info for $packageId: ${e.message}",
                e
            )
        }
    }
}
