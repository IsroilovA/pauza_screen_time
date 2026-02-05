package com.example.pauza_screen_time.app_restriction

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.provider.Settings
import android.util.Log
import android.view.accessibility.AccessibilityEvent

/**
 * AccessibilityService implementation for monitoring foreground app changes.
 *
 * This service detects when apps are launched (via TYPE_WINDOW_STATE_CHANGED events)
 * and checks if the launched app is on the blocklist. If blocked, it triggers
 * the shield overlay to be displayed over the restricted app.
 *
 * Features:
 * - Monitors foreground app changes in real-time
 * - Integrates with RestrictionManager for blocklist checking
 * - Triggers ShieldOverlayManager when blocked app is detected
 * - Shows shield overlay for restricted apps
 */
class AppMonitoringService : AccessibilityService() {

    companion object {
        private const val TAG = "AppMonitoringService"
        private const val EVENT_DEBOUNCE_MS = 500L
        
        // Reference to the running service instance
        @Volatile
        private var instance: AppMonitoringService? = null
        
        /**
         * Checks if the accessibility service is enabled in system settings.
         *
         * @param context The application context
         * @return true if the service is enabled, false otherwise
         */
        fun isRunning(context: Context): Boolean {
            val enabledServices = Settings.Secure.getString(
                context.contentResolver,
                Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
            )
            
            if (enabledServices.isNullOrEmpty()) {
                return false
            }

            val expectedService = ComponentName(context, AppMonitoringService::class.java).flattenToString()
            return enabledServices.split(':').any { it == expectedService }
        }
        
        /**
         * Gets the current service instance if running.
         *
         * @return The service instance or null if not running
         */
        fun getInstance(): AppMonitoringService? = instance
    }
    
    // Track the last detected foreground package to avoid duplicate processing
    private var lastForegroundPackage: String? = null

    // Track last processed event time to avoid rapid toggles
    private var lastEventTimestamp: Long = 0L
    
    // Flag to indicate if monitoring is active
    private var isMonitoring = true

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
        
        // Configure the service programmatically (supplements XML config)
        val info = AccessibilityServiceInfo().apply {
            eventTypes = AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED
            feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
            notificationTimeout = 100
            flags = AccessibilityServiceInfo.FLAG_REPORT_VIEW_IDS
        }
        serviceInfo = info
        
        Log.d(TAG, "AppMonitoringService connected and configured")
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null || !isMonitoring) return
        
        // Only process window state change events
        if (event.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return
        
        val packageName = event.packageName?.toString() ?: return
        
        // Skip system UI and keyboards
        if (shouldIgnorePackage(packageName)) return

        val now = System.currentTimeMillis()
        if (now - lastEventTimestamp < EVENT_DEBOUNCE_MS) return
        lastEventTimestamp = now

        // Skip if same as last detected package (avoid duplicate processing)
        if (packageName == lastForegroundPackage) return
        
        lastForegroundPackage = packageName
        
        Log.d(TAG, "Foreground app changed: $packageName")
        
        // Check if this app is on the blocklist
        if (isAppRestricted(packageName)) {
            Log.d(TAG, "Restricted app detected: $packageName")
            handleRestrictedAppDetected(packageName)
        }
    }

    override fun onInterrupt() {
        Log.d(TAG, "AppMonitoringService interrupted")
        ShieldOverlayManager.getInstanceOrNull()?.hideShield()
    }

    override fun onDestroy() {
        super.onDestroy()
        instance = null
        ShieldOverlayManager.getInstanceOrNull()?.hideShield()
        Log.d(TAG, "AppMonitoringService destroyed")
    }
    
    /**
     * Enables or disables foreground app monitoring.
     *
     * @param enabled true to enable monitoring, false to disable
     */
    fun setMonitoringEnabled(enabled: Boolean) {
        isMonitoring = enabled
        Log.d(TAG, "Monitoring ${if (enabled) "enabled" else "disabled"}")
    }
    
    /**
     * Checks if a package should be ignored (system UI, keyboards, etc.).
     *
     * @param packageName The package name to check
     * @return true if the package should be ignored
     */
    private fun shouldIgnorePackage(packageName: String): Boolean {
        val ownPackageName = applicationContext.packageName
        if (packageName == ownPackageName) return true

        val ignoredPackagePrefixes = listOf(
            // System UI / launchers
            "com.android.systemui",
            "com.android.launcher",
            "com.google.android.apps.nexuslauncher",
            // Keyboards / IMEs (common)
            "com.google.android.inputmethod",
            "com.samsung.android.honeyboard",
        )

        return ignoredPackagePrefixes.any { packageName.startsWith(it) } ||
            packageName.contains("keyboard", ignoreCase = true) ||
            packageName.contains("inputmethod", ignoreCase = true)
    }
    
    /**
     * Checks if the given package is on the restriction blocklist.
     *
     * @param packageName The package name to check
     * @return true if the app is restricted
     */
    private fun isAppRestricted(packageName: String): Boolean {
        return RestrictionManager.getInstance(applicationContext).isRestricted(packageName)
    }
    
    /**
     * Called when a restricted app is launched.
     * 
     * Shows the shield overlay.
     *
     * @param packageName The package name of the restricted app
     */
    private fun handleRestrictedAppDetected(packageName: String) {
        Log.d(TAG, "Handling restricted app detection: $packageName")
        
        // Show shield overlay
        ShieldOverlayManager.getInstance(applicationContext).showShield(
            packageName,
            contextOverride = this
        )
        
    }
}
