package com.example.pauza_screen_time.core

import io.flutter.plugin.common.MethodChannel.Result

object PluginErrors {
    const val CODE_INVALID_ARGUMENT = "INVALID_ARGUMENT"
    const val CODE_MISSING_PERMISSION = "MISSING_PERMISSION"
    const val CODE_PERMISSION_DENIED = "PERMISSION_DENIED"
    const val CODE_SYSTEM_RESTRICTED = "SYSTEM_RESTRICTED"
    const val CODE_INTERNAL_FAILURE = "INTERNAL_FAILURE"
}

object PluginErrorHelper {
    private const val PLATFORM_ANDROID = "android"

    fun invalidArgument(
        result: Result,
        feature: String,
        action: String,
        message: String,
        diagnostic: String? = null,
    ) {
        result.error(
            PluginErrors.CODE_INVALID_ARGUMENT,
            message,
            details(feature, action, diagnostic = diagnostic),
        )
    }

    fun missingPermission(
        result: Result,
        feature: String,
        action: String,
        message: String,
        missing: List<String>? = null,
        status: Map<String, Any?>? = null,
        diagnostic: String? = null,
    ) {
        result.error(
            PluginErrors.CODE_MISSING_PERMISSION,
            message,
            details(feature, action, missing = missing, status = status, diagnostic = diagnostic),
        )
    }

    fun permissionDenied(
        result: Result,
        feature: String,
        action: String,
        message: String,
        missing: List<String>? = null,
        status: Map<String, Any?>? = null,
        diagnostic: String? = null,
    ) {
        result.error(
            PluginErrors.CODE_PERMISSION_DENIED,
            message,
            details(feature, action, missing = missing, status = status, diagnostic = diagnostic),
        )
    }

    fun systemRestricted(
        result: Result,
        feature: String,
        action: String,
        message: String,
        missing: List<String>? = null,
        status: Map<String, Any?>? = null,
        diagnostic: String? = null,
    ) {
        result.error(
            PluginErrors.CODE_SYSTEM_RESTRICTED,
            message,
            details(feature, action, missing = missing, status = status, diagnostic = diagnostic),
        )
    }

    fun internalFailure(
        result: Result,
        feature: String,
        action: String,
        message: String,
        diagnostic: String? = null,
        error: Exception? = null,
    ) {
        result.error(
            PluginErrors.CODE_INTERNAL_FAILURE,
            message,
            details(feature, action, diagnostic = diagnostic, throwable = error),
        )
    }

    private fun details(
        feature: String,
        action: String,
        missing: List<String>? = null,
        status: Map<String, Any?>? = null,
        diagnostic: String? = null,
        throwable: Throwable? = null,
    ): Map<String, Any?> {
        return mutableMapOf<String, Any?>(
            "feature" to feature,
            "action" to action,
            "platform" to PLATFORM_ANDROID,
        ).apply {
            if (!missing.isNullOrEmpty()) {
                this["missing"] = missing
            }
            if (!status.isNullOrEmpty()) {
                this["status"] = status
            }
            if (!diagnostic.isNullOrBlank()) {
                this["diagnostic"] = diagnostic
            }
            if (throwable != null) {
                this["diagnostic"] = throwable.stackTraceToString()
            }
        }
    }
}
