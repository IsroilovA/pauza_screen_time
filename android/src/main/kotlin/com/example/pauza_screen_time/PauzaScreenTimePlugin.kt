package com.example.pauza_screen_time

import android.app.Activity
import android.content.Context
import com.example.pauza_screen_time.app_restriction.RestrictionManager
import com.example.pauza_screen_time.app_restriction.ShieldOverlayManager
import com.example.pauza_screen_time.permissions.PermissionHandler
import com.example.pauza_screen_time.installed_apps.InstalledAppsHandler
import com.example.pauza_screen_time.usage_stats.UsageStatsHandler
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/**
 * Main plugin class for Pauza Screen Time.
 *
 * This plugin provides functionality for:
 * - Managing app restrictions and blocking
 * - Monitoring app usage statistics
 * - Enumerating installed applications
 * - Handling platform-specific permissions
 */
class PauzaScreenTimePlugin :
    FlutterPlugin,
    MethodCallHandler,
    ActivityAware {

    // The MethodChannel that will handle communication between Flutter and native Android
    private lateinit var channel: MethodChannel
    
    // Current activity reference, needed for permission requests
    private var activity: Activity? = null
    
    // Permission handler for managing Android permissions
    private var permissionHandler: PermissionHandler? = null
    
    // Installed apps handler for app enumeration
    private var installedAppsHandler: InstalledAppsHandler? = null
    
    // Usage stats handler for app usage statistics
    private var usageStatsHandler: UsageStatsHandler? = null
    
    // Application context for service checks
    private var applicationContext: Context? = null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "pauza_screen_time")
        channel.setMethodCallHandler(this)
        
        // Initialize permission handler with application context
        permissionHandler = PermissionHandler(flutterPluginBinding.applicationContext)
        
        // Initialize installed apps handler with application context
        installedAppsHandler = InstalledAppsHandler(flutterPluginBinding.applicationContext)
        
        // Initialize usage stats handler with application context
        usageStatsHandler = UsageStatsHandler(flutterPluginBinding.applicationContext)
        
        // Store application context for service checks
        applicationContext = flutterPluginBinding.applicationContext
        
    }

    override fun onMethodCall(
        call: MethodCall,
        result: Result
    ) {
        try {
            when (call.method) {
                "getPlatformVersion" -> {
                    result.success("Android ${android.os.Build.VERSION.RELEASE}")
                }
                
                // Permission-related methods
                "checkPermission" -> handleCheckPermission(call, result)
                "requestPermission" -> handleRequestPermission(call, result)
                "openPermissionSettings" -> handleOpenPermissionSettings(call, result)
                
                // Installed apps methods
                "getInstalledApps" -> handleGetInstalledApps(call, result)
                "getAppInfo" -> handleGetAppInfo(call, result)
                
                // Usage stats methods
                "queryUsageStats" -> handleQueryUsageStats(call, result)
                "queryAppUsageStats" -> handleQueryAppUsageStats(call, result)
                
                // App restriction methods
                "configureShield" -> handleConfigureShield(call, result)
                "setRestrictedApps" -> handleSetRestrictedApps(call, result)
                "addRestrictedApp" -> handleAddRestrictedApp(call, result)
                "removeRestriction" -> handleRemoveRestriction(call, result)
                "removeAllRestrictions" -> handleRemoveAllRestrictions(result)
                "getRestrictedApps" -> handleGetRestrictedApps(result)
                "isRestricted" -> handleIsRestricted(call, result)
                
                else -> {
                    result.notImplemented()
                }
            }
        } catch (e: Exception) {
            result.error(
                "UNEXPECTED_ERROR",
                "An unexpected error occurred: ${e.message}",
                e.stackTraceToString()
            )
        }
    }

    // ============= Permission Method Handlers =============

    private fun handleCheckPermission(call: MethodCall, result: Result) {
        val permissionKey = call.argument<String>("permissionKey")
        
        if (permissionKey == null) {
            result.error(
                "INVALID_ARGUMENT",
                "Permission key is required",
                null
            )
            return
        }
        
        val status = permissionHandler?.checkPermission(permissionKey)
            ?: PermissionHandler.STATUS_UNKNOWN
        
        result.success(status)
    }

    private fun handleRequestPermission(call: MethodCall, result: Result) {
        val permissionKey = call.argument<String>("permissionKey")
        
        if (permissionKey == null) {
            result.error(
                "INVALID_ARGUMENT",
                "Permission key is required",
                null
            )
            return
        }
        
        val currentActivity = activity
        if (currentActivity == null) {
            result.error(
                "NO_ACTIVITY",
                "No activity available for permission request",
                null
            )
            return
        }
        
        val requested = permissionHandler?.requestPermission(currentActivity, permissionKey) ?: false
        
        // For permissions that require user action in settings, we return true if intent was launched
        // The actual permission status should be checked after user returns
        result.success(requested)
    }

    private fun handleOpenPermissionSettings(call: MethodCall, result: Result) {
        val permissionKey = call.argument<String>("permissionKey")
        
        if (permissionKey == null) {
            result.error(
                "INVALID_ARGUMENT",
                "Permission key is required",
                null
            )
            return
        }
        
        val currentActivity = activity
        if (currentActivity == null) {
            result.error(
                "NO_ACTIVITY",
                "No activity available for opening settings",
                null
            )
            return
        }
        
        try {
            permissionHandler?.openPermissionSettings(currentActivity, permissionKey)
            result.success(null)
        } catch (e: Exception) {
            result.error(
                "SETTINGS_ERROR",
                "Failed to open permission settings: ${e.message}",
                e.stackTraceToString()
            )
        }
    }

    // ============= Installed Apps Method Handlers =============

    private fun handleGetInstalledApps(call: MethodCall, result: Result) {
        val includeSystemApps = call.argument<Boolean>("includeSystemApps") ?: false
        val includeIcons = call.argument<Boolean>("includeIcons") ?: true
        
        try {
            val apps = installedAppsHandler?.getInstalledApps(includeSystemApps, includeIcons) ?: emptyList()
            result.success(apps)
        } catch (e: Exception) {
            result.error(
                "GET_APPS_ERROR",
                "Failed to get installed apps: ${e.message}",
                e.stackTraceToString()
            )
        }
    }

    private fun handleGetAppInfo(call: MethodCall, result: Result) {
        val packageId = call.argument<String>("packageId")
        val includeIcons = call.argument<Boolean>("includeIcons") ?: true
        
        if (packageId == null) {
            result.error(
                "INVALID_ARGUMENT",
                "Package ID is required",
                null
            )
            return
        }
        
        try {
            val appInfo = installedAppsHandler?.getAppInfo(packageId, includeIcons)
            result.success(appInfo)
        } catch (e: Exception) {
            result.error(
                "GET_APP_INFO_ERROR",
                "Failed to get app info for $packageId: ${e.message}",
                e.stackTraceToString()
            )
        }
    }

    // ============= Usage Stats Method Handlers =============

    private fun handleQueryUsageStats(call: MethodCall, result: Result) {
        val startTimeMs = call.argument<Long>("startTimeMs")
        val endTimeMs = call.argument<Long>("endTimeMs")
        val includeIcons = call.argument<Boolean>("includeIcons") ?: true
        
        if (startTimeMs == null || endTimeMs == null) {
            result.error(
                "INVALID_ARGUMENT",
                "Start time and end time are required",
                null
            )
            return
        }
        
        try {
            val stats = usageStatsHandler?.queryUsageStats(startTimeMs, endTimeMs, includeIcons) ?: emptyList()
            result.success(stats)
        } catch (e: Exception) {
            result.error(
                "QUERY_USAGE_STATS_ERROR",
                "Failed to query usage stats: ${e.message}",
                e.stackTraceToString()
            )
        }
    }

    private fun handleQueryAppUsageStats(call: MethodCall, result: Result) {
        val packageId = call.argument<String>("packageId")
        val startTimeMs = call.argument<Long>("startTimeMs")
        val endTimeMs = call.argument<Long>("endTimeMs")
        val includeIcons = call.argument<Boolean>("includeIcons") ?: true

        if (packageId == null || startTimeMs == null || endTimeMs == null) {
            result.error(
                "INVALID_ARGUMENT",
                "Package ID, start time, and end time are required",
                null
            )
            return
        }

        try {
            val stats = usageStatsHandler?.queryAppUsageStats(packageId, startTimeMs, endTimeMs, includeIcons)
            result.success(stats)
        } catch (e: Exception) {
            result.error(
                "QUERY_APP_USAGE_STATS_ERROR",
                "Failed to query app usage stats: ${e.message}",
                e.stackTraceToString()
            )
        }
    }

    // ============= App Restriction Method Handlers =============

    private fun handleConfigureShield(call: MethodCall, result: Result) {
        val context = applicationContext
        if (context == null) {
            result.error(
                "NO_CONTEXT",
                "Application context is not available",
                null
            )
            return
        }
        
        val configMap = call.arguments as? Map<String, Any?>
        if (configMap == null) {
            result.error(
                "INVALID_ARGUMENT",
                "Shield configuration map is required",
                null
            )
            return
        }
        
        try {
            ShieldOverlayManager.getInstance(context).configure(configMap)
            result.success(null)
        } catch (e: Exception) {
            result.error(
                "CONFIGURE_SHIELD_ERROR",
                "Failed to configure shield: ${e.message}",
                e.stackTraceToString()
            )
        }
    }

    private fun handleSetRestrictedApps(call: MethodCall, result: Result) {
        val context = applicationContext
        if (context == null) {
            result.error("NO_CONTEXT", "Application context is not available", null)
            return
        }

        val args = call.arguments
        val packageIds: List<String>? = when (args) {
            is Map<*, *> -> {
                val raw = args["packageIds"]
                if (raw is List<*>) {
                    val list = raw.filterIsInstance<String>()
                    if (list.size == raw.size) list else null
                } else {
                    null
                }
            }
            is List<*> -> {
                val list = args.filterIsInstance<String>()
                if (list.size == args.size) list else null
            }
            else -> null
        }

        if (packageIds == null) {
            result.error(
                "INVALID_ARGUMENT",
                "Expected `{packageIds: List<String>}` (or a legacy raw `List<String>`)",
                null
            )
            return
        }
        
        try {
            RestrictionManager.getInstance(context).setRestrictedApps(packageIds)
            result.success(null)
        } catch (e: Exception) {
            result.error(
                "SET_RESTRICTED_APPS_ERROR",
                "Failed to set restricted apps: ${e.message}",
                e.stackTraceToString()
            )
        }
    }

    private fun handleAddRestrictedApp(call: MethodCall, result: Result) {
        val context = applicationContext
        if (context == null) {
            result.error("NO_CONTEXT", "Application context is not available", null)
            return
        }
        
        val packageId = call.argument<String>("packageId")
        if (packageId == null) {
            result.error("INVALID_ARGUMENT", "Package ID is required", null)
            return
        }
        
        try {
            val added = RestrictionManager.getInstance(context).addRestrictedApp(packageId)
            result.success(added)
        } catch (e: Exception) {
            result.error(
                "ADD_RESTRICTED_APP_ERROR",
                "Failed to add restricted app: ${e.message}",
                e.stackTraceToString()
            )
        }
    }

    private fun handleRemoveRestriction(call: MethodCall, result: Result) {
        val context = applicationContext
        if (context == null) {
            result.error("NO_CONTEXT", "Application context is not available", null)
            return
        }
        
        val packageId = call.argument<String>("packageId")
        if (packageId == null) {
            result.error("INVALID_ARGUMENT", "Package ID is required", null)
            return
        }
        
        try {
            val removed = RestrictionManager.getInstance(context).removeRestriction(packageId)
            result.success(removed)
        } catch (e: Exception) {
            result.error(
                "REMOVE_RESTRICTION_ERROR",
                "Failed to remove restriction: ${e.message}",
                e.stackTraceToString()
            )
        }
    }

    private fun handleRemoveAllRestrictions(result: Result) {
        val context = applicationContext
        if (context == null) {
            result.error("NO_CONTEXT", "Application context is not available", null)
            return
        }
        
        try {
            RestrictionManager.getInstance(context).removeAllRestrictions()
            result.success(null)
        } catch (e: Exception) {
            result.error(
                "REMOVE_ALL_RESTRICTIONS_ERROR",
                "Failed to remove all restrictions: ${e.message}",
                e.stackTraceToString()
            )
        }
    }

    private fun handleGetRestrictedApps(result: Result) {
        val context = applicationContext
        if (context == null) {
            result.error("NO_CONTEXT", "Application context is not available", null)
            return
        }
        
        try {
            val apps = RestrictionManager.getInstance(context).getRestrictedApps()
            result.success(apps)
        } catch (e: Exception) {
            result.error(
                "GET_RESTRICTED_APPS_ERROR",
                "Failed to get restricted apps: ${e.message}",
                e.stackTraceToString()
            )
        }
    }

    private fun handleIsRestricted(call: MethodCall, result: Result) {
        val context = applicationContext
        if (context == null) {
            result.error("NO_CONTEXT", "Application context is not available", null)
            return
        }
        
        val packageId = call.argument<String>("packageId")
        if (packageId == null) {
            result.error("INVALID_ARGUMENT", "Package ID is required", null)
            return
        }
        
        try {
            val isRestricted = RestrictionManager.getInstance(context).isRestricted(packageId)
            result.success(isRestricted)
        } catch (e: Exception) {
            result.error(
                "IS_RESTRICTED_ERROR",
                "Failed to check if app is restricted: ${e.message}",
                e.stackTraceToString()
            )
        }
    }

    // ============= Plugin Lifecycle =============

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        permissionHandler = null
        installedAppsHandler = null
        usageStatsHandler = null
        applicationContext = null
        
    }

    // ============= Activity Lifecycle =============

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }
}
