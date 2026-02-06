package com.example.pauza_screen_time.core

object MethodNames {
    const val GET_PLATFORM_VERSION = "getPlatformVersion"

    // Permissions
    const val CHECK_PERMISSION = "checkPermission"
    const val REQUEST_PERMISSION = "requestPermission"
    const val OPEN_PERMISSION_SETTINGS = "openPermissionSettings"

    // Installed apps
    const val GET_INSTALLED_APPS = "getInstalledApps"
    const val GET_APP_INFO = "getAppInfo"
    const val SHOW_FAMILY_ACTIVITY_PICKER = "showFamilyActivityPicker"

    // Usage stats
    const val QUERY_USAGE_STATS = "queryUsageStats"
    const val QUERY_APP_USAGE_STATS = "queryAppUsageStats"

    // Restrictions
    const val CONFIGURE_SHIELD = "configureShield"
    const val SET_RESTRICTED_APPS = "setRestrictedApps"
    const val ADD_RESTRICTED_APP = "addRestrictedApp"
    const val REMOVE_RESTRICTION = "removeRestriction"
    const val REMOVE_ALL_RESTRICTIONS = "removeAllRestrictions"
    const val GET_RESTRICTED_APPS = "getRestrictedApps"
    const val IS_RESTRICTED = "isRestricted"
}
