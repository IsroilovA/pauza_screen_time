package com.example.pauza_screen_time.core

import io.flutter.plugin.common.MethodChannel.Result

object PluginErrors {
    const val CODE_INVALID_ARGUMENT = "INVALID_ARGUMENT"
    const val CODE_NO_ACTIVITY = "NO_ACTIVITY"
    const val CODE_NO_CONTEXT = "NO_CONTEXT"
    const val CODE_SETTINGS_ERROR = "SETTINGS_ERROR"
    const val CODE_GET_APPS_ERROR = "GET_APPS_ERROR"
    const val CODE_GET_APP_INFO_ERROR = "GET_APP_INFO_ERROR"
    const val CODE_QUERY_USAGE_STATS_ERROR = "QUERY_USAGE_STATS_ERROR"
    const val CODE_QUERY_APP_USAGE_STATS_ERROR = "QUERY_APP_USAGE_STATS_ERROR"
    const val CODE_CONFIGURE_SHIELD_ERROR = "CONFIGURE_SHIELD_ERROR"
    const val CODE_SET_RESTRICTED_APPS_ERROR = "SET_RESTRICTED_APPS_ERROR"
    const val CODE_ADD_RESTRICTED_APP_ERROR = "ADD_RESTRICTED_APP_ERROR"
    const val CODE_REMOVE_RESTRICTION_ERROR = "REMOVE_RESTRICTION_ERROR"
    const val CODE_REMOVE_ALL_RESTRICTIONS_ERROR = "REMOVE_ALL_RESTRICTIONS_ERROR"
    const val CODE_GET_RESTRICTED_APPS_ERROR = "GET_RESTRICTED_APPS_ERROR"
    const val CODE_IS_RESTRICTED_ERROR = "IS_RESTRICTED_ERROR"
    const val CODE_UNEXPECTED_ERROR = "UNEXPECTED_ERROR"
}

object PluginErrorHelper {
    fun invalidArgument(result: Result, message: String) {
        result.error(PluginErrors.CODE_INVALID_ARGUMENT, message, null)
    }

    fun noActivity(result: Result, message: String) {
        result.error(PluginErrors.CODE_NO_ACTIVITY, message, null)
    }

    fun noContext(result: Result, message: String = "Application context is not available") {
        result.error(PluginErrors.CODE_NO_CONTEXT, message, null)
    }

    fun error(result: Result, code: String, message: String, error: Exception? = null) {
        result.error(code, message, error?.stackTraceToString())
    }

    fun unexpectedError(result: Result, error: Exception) {
        result.error(
            PluginErrors.CODE_UNEXPECTED_ERROR,
            "An unexpected error occurred: ${error.message}",
            error.stackTraceToString()
        )
    }
}
