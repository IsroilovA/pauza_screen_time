package com.example.pauza_screen_time.app_restriction.method_channel

import android.content.Context
import com.example.pauza_screen_time.app_restriction.RestrictionManager
import com.example.pauza_screen_time.app_restriction.ShieldOverlayManager
import com.example.pauza_screen_time.core.MethodNames
import com.example.pauza_screen_time.core.PluginErrorHelper
import com.example.pauza_screen_time.core.PluginErrors
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class RestrictionsMethodHandler(
    private val contextProvider: () -> Context?
) : MethodCallHandler {
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
                MethodNames.GET_RESTRICTION_SESSION -> handleGetRestrictionSession(result)
                else -> result.notImplemented()
            }
        } catch (e: Exception) {
            PluginErrorHelper.unexpectedError(result, e)
        }
    }

    private fun handleConfigureShield(call: MethodCall, result: Result) {
        val context = contextProvider()
        if (context == null) {
            PluginErrorHelper.noContext(result)
            return
        }

        val configMap = call.arguments as? Map<String, Any?>
        if (configMap == null) {
            PluginErrorHelper.invalidArgument(result, "Shield configuration map is required")
            return
        }

        try {
            ShieldOverlayManager.getInstance(context).configure(configMap)
            result.success(null)
        } catch (e: Exception) {
            PluginErrorHelper.error(
                result,
                PluginErrors.CODE_CONFIGURE_SHIELD_ERROR,
                "Failed to configure shield: ${e.message}",
                e
            )
        }
    }

    private fun handleSetRestrictedApps(call: MethodCall, result: Result) {
        val context = contextProvider()
        if (context == null) {
            PluginErrorHelper.noContext(result)
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
            PluginErrorHelper.invalidArgument(result, "Missing or invalid 'identifiers' argument")
            return
        }

        try {
            val trimmed = identifiers.map { it.trim() }
            val hasBlank = trimmed.any { it.isBlank() }
            if (hasBlank) {
                PluginErrorHelper.invalidArgument(result, "Identifiers must be non-blank strings")
                return
            }

            val applied = LinkedHashSet<String>()
            for (identifier in trimmed) {
                applied.add(identifier)
            }
            val appliedList = applied.toList()

            RestrictionManager.getInstance(context).setRestrictedApps(appliedList)
            result.success(appliedList)
        } catch (e: Exception) {
            PluginErrorHelper.error(
                result,
                PluginErrors.CODE_SET_RESTRICTED_APPS_ERROR,
                "Failed to set restricted apps: ${e.message}",
                e
            )
        }
    }

    private fun handleAddRestrictedApp(call: MethodCall, result: Result) {
        val context = contextProvider()
        if (context == null) {
            PluginErrorHelper.noContext(result)
            return
        }

        val identifier = call.argument<String>("identifier")
        if (identifier == null) {
            PluginErrorHelper.invalidArgument(result, "Missing or invalid 'identifier' argument")
            return
        }

        try {
            val added = RestrictionManager.getInstance(context).addRestrictedApp(identifier)
            result.success(added)
        } catch (e: Exception) {
            PluginErrorHelper.error(
                result,
                PluginErrors.CODE_ADD_RESTRICTED_APP_ERROR,
                "Failed to add restricted app: ${e.message}",
                e
            )
        }
    }

    private fun handleRemoveRestriction(call: MethodCall, result: Result) {
        val context = contextProvider()
        if (context == null) {
            PluginErrorHelper.noContext(result)
            return
        }

        val identifier = call.argument<String>("identifier")
        if (identifier == null) {
            PluginErrorHelper.invalidArgument(result, "Missing or invalid 'identifier' argument")
            return
        }

        try {
            val removed = RestrictionManager.getInstance(context).removeRestriction(identifier)
            result.success(removed)
        } catch (e: Exception) {
            PluginErrorHelper.error(
                result,
                PluginErrors.CODE_REMOVE_RESTRICTION_ERROR,
                "Failed to remove restriction: ${e.message}",
                e
            )
        }
    }

    private fun handleRemoveAllRestrictions(result: Result) {
        val context = contextProvider()
        if (context == null) {
            PluginErrorHelper.noContext(result)
            return
        }

        try {
            RestrictionManager.getInstance(context).removeAllRestrictions()
            result.success(null)
        } catch (e: Exception) {
            PluginErrorHelper.error(
                result,
                PluginErrors.CODE_REMOVE_ALL_RESTRICTIONS_ERROR,
                "Failed to remove all restrictions: ${e.message}",
                e
            )
        }
    }

    private fun handleGetRestrictedApps(result: Result) {
        val context = contextProvider()
        if (context == null) {
            PluginErrorHelper.noContext(result)
            return
        }

        try {
            val apps = RestrictionManager.getInstance(context).getRestrictedApps()
            result.success(apps)
        } catch (e: Exception) {
            PluginErrorHelper.error(
                result,
                PluginErrors.CODE_GET_RESTRICTED_APPS_ERROR,
                "Failed to get restricted apps: ${e.message}",
                e
            )
        }
    }

    private fun handleIsRestricted(call: MethodCall, result: Result) {
        val context = contextProvider()
        if (context == null) {
            PluginErrorHelper.noContext(result)
            return
        }

        val identifier = call.argument<String>("identifier")
        if (identifier == null) {
            PluginErrorHelper.invalidArgument(result, "Missing or invalid 'identifier' argument")
            return
        }

        try {
            val isRestricted = RestrictionManager.getInstance(context).isRestricted(identifier)
            result.success(isRestricted)
        } catch (e: Exception) {
            PluginErrorHelper.error(
                result,
                PluginErrors.CODE_IS_RESTRICTED_ERROR,
                "Failed to check if app is restricted: ${e.message}",
                e
            )
        }
    }

    private fun handleIsRestrictionSessionActiveNow(result: Result) {
        val context = contextProvider()
        if (context == null) {
            PluginErrorHelper.noContext(result)
            return
        }

        try {
            val restrictedApps = RestrictionManager.getInstance(context).getRestrictedApps()
            result.success(restrictedApps.isNotEmpty())
        } catch (e: Exception) {
            PluginErrorHelper.error(
                result,
                PluginErrors.CODE_GET_RESTRICTED_APPS_ERROR,
                "Failed to get restriction session active state: ${e.message}",
                e
            )
        }
    }

    private fun handleGetRestrictionSession(result: Result) {
        val context = contextProvider()
        if (context == null) {
            PluginErrorHelper.noContext(result)
            return
        }

        try {
            val restrictedApps = RestrictionManager.getInstance(context).getRestrictedApps()
            result.success(
                mapOf(
                    "isActiveNow" to restrictedApps.isNotEmpty(),
                    "restrictedApps" to restrictedApps
                )
            )
        } catch (e: Exception) {
            PluginErrorHelper.error(
                result,
                PluginErrors.CODE_GET_RESTRICTED_APPS_ERROR,
                "Failed to get restriction session: ${e.message}",
                e
            )
        }
    }
}
