package com.example.pauza_screen_time.app_restriction.method_channel

import android.content.Context
import com.example.pauza_screen_time.app_restriction.RestrictionManager
import com.example.pauza_screen_time.app_restriction.ShieldOverlayManager
import com.example.pauza_screen_time.core.MethodNames
import com.example.pauza_screen_time.core.PluginErrorHelper
import com.example.pauza_screen_time.permissions.PermissionHandler
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class RestrictionsMethodHandler(
    private val contextProvider: () -> Context?
) : MethodCallHandler {
    companion object {
        private const val ANDROID_ACCESSIBILITY_KEY = "android.accessibility"
        private const val FEATURE = "restrictions"
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        try {
            when (call.method) {
                MethodNames.CONFIGURE_SHIELD -> handleConfigureShield(call, result)
                MethodNames.SET_RESTRICTED_APPS -> handleSetRestrictedApps(call, result)
                MethodNames.ADD_RESTRICTED_APP -> handleAddRestrictedApp(call, result)
                MethodNames.REMOVE_RESTRICTION -> handleRemoveRestriction(call, result)
                MethodNames.REMOVE_ALL_RESTRICTIONS -> handleRemoveAllRestrictions(result)
                MethodNames.GET_RESTRICTED_APPS -> handleGetRestrictedApps(result)
                MethodNames.IS_RESTRICTED -> handleIsRestricted(call, result)
                MethodNames.IS_RESTRICTION_SESSION_ACTIVE_NOW -> handleIsRestrictionSessionActiveNow(result)
                MethodNames.IS_RESTRICTION_SESSION_CONFIGURED -> handleIsRestrictionSessionConfigured(result)
                MethodNames.PAUSE_ENFORCEMENT -> handlePauseEnforcement(call, result)
                MethodNames.RESUME_ENFORCEMENT -> handleResumeEnforcement(result)
                MethodNames.GET_RESTRICTION_SESSION -> handleGetRestrictionSession(result)
                else -> result.notImplemented()
            }
        } catch (e: Exception) {
            PluginErrorHelper.internalFailure(
                result = result,
                feature = FEATURE,
                action = call.method,
                message = "Unexpected restriction error: ${e.message}",
                error = e,
            )
        }
    }

    private fun handleConfigureShield(call: MethodCall, result: Result) {
        val context = contextProvider()
        if (context == null) {
            PluginErrorHelper.internalFailure(
                result = result,
                feature = FEATURE,
                action = MethodNames.CONFIGURE_SHIELD,
                message = "Application context is not available",
            )
            return
        }

        val configMap = call.arguments as? Map<String, Any?>
        if (configMap == null) {
            PluginErrorHelper.invalidArgument(
                result = result,
                feature = FEATURE,
                action = MethodNames.CONFIGURE_SHIELD,
                message = "Shield configuration map is required",
            )
            return
        }

        try {
            ShieldOverlayManager.getInstance(context).configure(configMap)
            result.success(null)
        } catch (e: Exception) {
            PluginErrorHelper.internalFailure(
                result = result,
                feature = FEATURE,
                action = MethodNames.CONFIGURE_SHIELD,
                message = "Failed to configure shield: ${e.message}",
                error = e,
            )
        }
    }

    private fun handleSetRestrictedApps(call: MethodCall, result: Result) {
        val context = contextProvider()
        if (context == null) {
            PluginErrorHelper.internalFailure(
                result = result,
                feature = FEATURE,
                action = MethodNames.SET_RESTRICTED_APPS,
                message = "Application context is not available",
            )
            return
        }

        val args = call.arguments
        val identifiers: List<String>? = when (args) {
            is Map<*, *> -> {
                val raw = args["identifiers"]
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

        if (identifiers == null) {
            PluginErrorHelper.invalidArgument(
                result = result,
                feature = FEATURE,
                action = MethodNames.SET_RESTRICTED_APPS,
                message = "Missing or invalid 'identifiers' argument",
            )
            return
        }

        try {
            val trimmed = identifiers.map { it.trim() }
            val hasBlank = trimmed.any { it.isBlank() }
            if (hasBlank) {
                PluginErrorHelper.invalidArgument(
                    result = result,
                    feature = FEATURE,
                    action = MethodNames.SET_RESTRICTED_APPS,
                    message = "Identifiers must be non-blank strings",
                )
                return
            }

            val applied = LinkedHashSet<String>()
            for (identifier in trimmed) {
                applied.add(identifier)
            }
            val appliedList = applied.toList()

            if (appliedList.isNotEmpty()) {
                val missingPrerequisites = getMissingPrerequisites(context)
                if (missingPrerequisites.isNotEmpty()) {
                    PluginErrorHelper.missingPermission(
                        result = result,
                        feature = FEATURE,
                        action = MethodNames.SET_RESTRICTED_APPS,
                        message = "Restriction prerequisites are not satisfied",
                        missing = missingPrerequisites,
                        status = mapOf(
                            ANDROID_ACCESSIBILITY_KEY to PermissionHandler(context)
                                .checkPermission(PermissionHandler.ACCESSIBILITY_KEY),
                        ),
                    )
                    return
                }
            }

            RestrictionManager.getInstance(context).setRestrictedApps(appliedList)
            result.success(appliedList)
        } catch (e: Exception) {
            PluginErrorHelper.internalFailure(
                result = result,
                feature = FEATURE,
                action = MethodNames.SET_RESTRICTED_APPS,
                message = "Failed to set restricted apps: ${e.message}",
                error = e,
            )
        }
    }

    private fun handleAddRestrictedApp(call: MethodCall, result: Result) {
        val context = contextProvider()
        if (context == null) {
            PluginErrorHelper.internalFailure(
                result = result,
                feature = FEATURE,
                action = MethodNames.ADD_RESTRICTED_APP,
                message = "Application context is not available",
            )
            return
        }

        val identifier = call.argument<String>("identifier")
        if (identifier == null) {
            PluginErrorHelper.invalidArgument(
                result = result,
                feature = FEATURE,
                action = MethodNames.ADD_RESTRICTED_APP,
                message = "Missing or invalid 'identifier' argument",
            )
            return
        }

        try {
            val missingPrerequisites = getMissingPrerequisites(context)
            if (missingPrerequisites.isNotEmpty()) {
                PluginErrorHelper.missingPermission(
                    result = result,
                    feature = FEATURE,
                    action = MethodNames.ADD_RESTRICTED_APP,
                    message = "Restriction prerequisites are not satisfied",
                    missing = missingPrerequisites,
                    status = mapOf(
                        ANDROID_ACCESSIBILITY_KEY to PermissionHandler(context)
                            .checkPermission(PermissionHandler.ACCESSIBILITY_KEY),
                    ),
                )
                return
            }

            val added = RestrictionManager.getInstance(context).addRestrictedApp(identifier)
            result.success(added)
        } catch (e: Exception) {
            PluginErrorHelper.internalFailure(
                result = result,
                feature = FEATURE,
                action = MethodNames.ADD_RESTRICTED_APP,
                message = "Failed to add restricted app: ${e.message}",
                error = e,
            )
        }
    }

    private fun handleRemoveRestriction(call: MethodCall, result: Result) {
        val context = contextProvider()
        if (context == null) {
            PluginErrorHelper.internalFailure(
                result = result,
                feature = FEATURE,
                action = MethodNames.REMOVE_RESTRICTION,
                message = "Application context is not available",
            )
            return
        }

        val identifier = call.argument<String>("identifier")
        if (identifier == null) {
            PluginErrorHelper.invalidArgument(
                result = result,
                feature = FEATURE,
                action = MethodNames.REMOVE_RESTRICTION,
                message = "Missing or invalid 'identifier' argument",
            )
            return
        }

        try {
            val removed = RestrictionManager.getInstance(context).removeRestriction(identifier)
            result.success(removed)
        } catch (e: Exception) {
            PluginErrorHelper.internalFailure(
                result = result,
                feature = FEATURE,
                action = MethodNames.REMOVE_RESTRICTION,
                message = "Failed to remove restriction: ${e.message}",
                error = e,
            )
        }
    }

    private fun handleRemoveAllRestrictions(result: Result) {
        val context = contextProvider()
        if (context == null) {
            PluginErrorHelper.internalFailure(
                result = result,
                feature = FEATURE,
                action = MethodNames.REMOVE_ALL_RESTRICTIONS,
                message = "Application context is not available",
            )
            return
        }

        try {
            RestrictionManager.getInstance(context).removeAllRestrictions()
            result.success(null)
        } catch (e: Exception) {
            PluginErrorHelper.internalFailure(
                result = result,
                feature = FEATURE,
                action = MethodNames.REMOVE_ALL_RESTRICTIONS,
                message = "Failed to remove all restrictions: ${e.message}",
                error = e,
            )
        }
    }

    private fun handleGetRestrictedApps(result: Result) {
        val context = contextProvider()
        if (context == null) {
            PluginErrorHelper.internalFailure(
                result = result,
                feature = FEATURE,
                action = MethodNames.GET_RESTRICTED_APPS,
                message = "Application context is not available",
            )
            return
        }

        try {
            val apps = RestrictionManager.getInstance(context).getRestrictedApps()
            result.success(apps)
        } catch (e: Exception) {
            PluginErrorHelper.internalFailure(
                result = result,
                feature = FEATURE,
                action = MethodNames.GET_RESTRICTED_APPS,
                message = "Failed to get restricted apps: ${e.message}",
                error = e,
            )
        }
    }

    private fun handleIsRestricted(call: MethodCall, result: Result) {
        val context = contextProvider()
        if (context == null) {
            PluginErrorHelper.internalFailure(
                result = result,
                feature = FEATURE,
                action = MethodNames.IS_RESTRICTED,
                message = "Application context is not available",
            )
            return
        }

        val identifier = call.argument<String>("identifier")
        if (identifier == null) {
            PluginErrorHelper.invalidArgument(
                result = result,
                feature = FEATURE,
                action = MethodNames.IS_RESTRICTED,
                message = "Missing or invalid 'identifier' argument",
            )
            return
        }

        try {
            val isRestricted = RestrictionManager.getInstance(context).isRestricted(identifier)
            result.success(isRestricted)
        } catch (e: Exception) {
            PluginErrorHelper.internalFailure(
                result = result,
                feature = FEATURE,
                action = MethodNames.IS_RESTRICTED,
                message = "Failed to check if app is restricted: ${e.message}",
                error = e,
            )
        }
    }

    private fun handleIsRestrictionSessionActiveNow(result: Result) {
        val context = contextProvider()
        if (context == null) {
            PluginErrorHelper.internalFailure(
                result = result,
                feature = FEATURE,
                action = MethodNames.IS_RESTRICTION_SESSION_ACTIVE_NOW,
                message = "Application context is not available",
            )
            return
        }

        try {
            val restrictionManager = RestrictionManager.getInstance(context)
            val restrictedApps = restrictionManager.getRestrictedApps()
            val isPausedNow = restrictionManager.isPausedNow()
            val isPrerequisitesMet = areRestrictionPrerequisitesMet(context)
            result.success(restrictedApps.isNotEmpty() && !isPausedNow && isPrerequisitesMet)
        } catch (e: Exception) {
            PluginErrorHelper.internalFailure(
                result = result,
                feature = FEATURE,
                action = MethodNames.IS_RESTRICTION_SESSION_ACTIVE_NOW,
                message = "Failed to get restriction session active state: ${e.message}",
                error = e,
            )
        }
    }

    private fun handleIsRestrictionSessionConfigured(result: Result) {
        val context = contextProvider()
        if (context == null) {
            PluginErrorHelper.internalFailure(
                result = result,
                feature = FEATURE,
                action = MethodNames.IS_RESTRICTION_SESSION_CONFIGURED,
                message = "Application context is not available",
            )
            return
        }

        try {
            val restrictedApps = RestrictionManager.getInstance(context).getRestrictedApps()
            result.success(restrictedApps.isNotEmpty())
        } catch (e: Exception) {
            PluginErrorHelper.internalFailure(
                result = result,
                feature = FEATURE,
                action = MethodNames.IS_RESTRICTION_SESSION_CONFIGURED,
                message = "Failed to get restriction session configuration state: ${e.message}",
                error = e,
            )
        }
    }

    private fun handlePauseEnforcement(call: MethodCall, result: Result) {
        val context = contextProvider()
        if (context == null) {
            PluginErrorHelper.internalFailure(
                result = result,
                feature = FEATURE,
                action = MethodNames.PAUSE_ENFORCEMENT,
                message = "Application context is not available",
            )
            return
        }

        val durationMs = call.argument<Number>("durationMs")?.toLong()
        if (durationMs == null || durationMs <= 0L) {
            PluginErrorHelper.invalidArgument(
                result = result,
                feature = FEATURE,
                action = MethodNames.PAUSE_ENFORCEMENT,
                message = "Missing or invalid 'durationMs' argument",
            )
            return
        }

        try {
            val restrictionManager = RestrictionManager.getInstance(context)
            if (restrictionManager.isPausedNow()) {
                PluginErrorHelper.invalidArgument(
                    result = result,
                    feature = FEATURE,
                    action = MethodNames.PAUSE_ENFORCEMENT,
                    message = "Restriction enforcement is already paused",
                )
                return
            }

            restrictionManager.pauseFor(durationMs)
            ShieldOverlayManager.getInstanceOrNull()?.hideShield()
            result.success(null)
        } catch (e: Exception) {
            PluginErrorHelper.internalFailure(
                result = result,
                feature = FEATURE,
                action = MethodNames.PAUSE_ENFORCEMENT,
                message = "Failed to pause restriction enforcement: ${e.message}",
                error = e,
            )
        }
    }

    private fun handleResumeEnforcement(result: Result) {
        val context = contextProvider()
        if (context == null) {
            PluginErrorHelper.internalFailure(
                result = result,
                feature = FEATURE,
                action = MethodNames.RESUME_ENFORCEMENT,
                message = "Application context is not available",
            )
            return
        }

        try {
            RestrictionManager.getInstance(context).clearPause()
            result.success(null)
        } catch (e: Exception) {
            PluginErrorHelper.internalFailure(
                result = result,
                feature = FEATURE,
                action = MethodNames.RESUME_ENFORCEMENT,
                message = "Failed to resume restriction enforcement: ${e.message}",
                error = e,
            )
        }
    }

    private fun handleGetRestrictionSession(result: Result) {
        val context = contextProvider()
        if (context == null) {
            PluginErrorHelper.internalFailure(
                result = result,
                feature = FEATURE,
                action = MethodNames.GET_RESTRICTION_SESSION,
                message = "Application context is not available",
            )
            return
        }

        try {
            val restrictionManager = RestrictionManager.getInstance(context)
            val restrictedApps = restrictionManager.getRestrictedApps()
            val pausedUntilEpochMs = restrictionManager.getPausedUntilEpochMs()
            val isPausedNow = pausedUntilEpochMs > 0L
            val isPrerequisitesMet = areRestrictionPrerequisitesMet(context)
            result.success(
                mapOf(
                    "isActiveNow" to (restrictedApps.isNotEmpty() && !isPausedNow && isPrerequisitesMet),
                    "isPausedNow" to isPausedNow,
                    "pausedUntilEpochMs" to if (isPausedNow) pausedUntilEpochMs else null,
                    "restrictedApps" to restrictedApps,
                )
            )
        } catch (e: Exception) {
            PluginErrorHelper.internalFailure(
                result = result,
                feature = FEATURE,
                action = MethodNames.GET_RESTRICTION_SESSION,
                message = "Failed to get restriction session: ${e.message}",
                error = e,
            )
        }
    }

    private fun areRestrictionPrerequisitesMet(context: Context): Boolean {
        return getMissingPrerequisites(context).isEmpty()
    }

    private fun getMissingPrerequisites(context: Context): List<String> {
        val permissionHandler = PermissionHandler(context)
        val accessibilityStatus = permissionHandler.checkPermission(PermissionHandler.ACCESSIBILITY_KEY)
        if (accessibilityStatus == PermissionHandler.STATUS_GRANTED) {
            return emptyList()
        }
        return listOf(ANDROID_ACCESSIBILITY_KEY)
    }

}
