package com.example.pauza_screen_time.app_restriction

import android.content.Context
import android.content.Intent
import android.graphics.PixelFormat
import android.util.Log
import android.view.Gravity
import android.view.WindowManager
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.platform.ComposeView
import androidx.lifecycle.setViewTreeLifecycleOwner
import androidx.savedstate.setViewTreeSavedStateRegistryOwner
import com.example.pauza_screen_time.app_restriction.model.ShieldConfig
import com.example.pauza_screen_time.app_restriction.overlay.OverlayLifecycleOwner
import com.example.pauza_screen_time.app_restriction.overlay.OverlaySavedStateRegistryOwner
import com.example.pauza_screen_time.app_restriction.overlay.ShieldOverlayContent

/**
 * Manages the shield overlay display on Android using Jetpack Compose.
 *
 * This singleton class handles the overlay lifecycle including:
 * - Storing shield configuration from Flutter
 * - Displaying shield overlay using WindowManager with Compose UI
 * - Hiding overlay and navigating to home screen
 * - Handling button taps and navigating to home
 *
 * Uses TYPE_ACCESSIBILITY_OVERLAY for the overlay window type, which requires
 * the AccessibilityService to be enabled.
 */
class ShieldOverlayManager private constructor(context: Context) {

    companion object {
        private const val TAG = "ShieldOverlayManager"

        @Volatile
        private var instance: ShieldOverlayManager? = null

        /**
         * Gets the singleton instance, creating it if necessary.
         *
         * @param context Application context
         * @return The ShieldOverlayManager singleton
         */
        fun getInstance(context: Context): ShieldOverlayManager {
            return instance ?: synchronized(this) {
                instance ?: ShieldOverlayManager(context.applicationContext).also {
                    instance = it
                }
            }
        }

        /**
         * Gets the existing instance without creating a new one.
         *
         * @return The existing instance or null
         */
        fun getInstanceOrNull(): ShieldOverlayManager? = instance
    }

    // WindowManager for overlay display
    private val appContext: Context = context.applicationContext
    private var overlayContext: Context = appContext

    private val windowManager: WindowManager
        get() = overlayContext.getSystemService(Context.WINDOW_SERVICE) as WindowManager

    // Current overlay view reference
    private var overlayView: ComposeView? = null

    // Current blocked package (for event emission)
    private var currentBlockedPackage: String? = null

    // Shield configuration (stored from Flutter)
    private var configuration by mutableStateOf<ShieldConfig?>(null)

    /**
     * Configures the shield appearance from Flutter method channel data.
     *
     * @param configMap Map containing shield configuration parameters
     */
    fun configure(configMap: Map<String, Any?>) {
        configuration = ShieldConfig.fromMap(configMap)
        Log.d(TAG, "Shield configured: ${configuration?.title}")
    }

    /**
     * Shows the shield overlay for a blocked app.
     *
     * @param packageId The package ID of the blocked app
     */
    fun showShield(packageId: String, contextOverride: Context? = null) {
        if (overlayView != null) {
            Log.d(TAG, "Shield already showing")
            return
        }

        if (contextOverride != null) {
            overlayContext = contextOverride
        }

        currentBlockedPackage = packageId

        val config = configuration ?: ShieldConfig.DEFAULT

        // Create the overlay ComposeView
        val composeView = ComposeView(overlayContext).apply {
            setViewTreeLifecycleOwner(OverlayLifecycleOwner())
            setViewTreeSavedStateRegistryOwner(OverlaySavedStateRegistryOwner())

            setContent {
                ShieldOverlayContent(
                    config = config,
                    onPrimaryClick = { handleButtonTap("primary") },
                    onSecondaryClick = { handleButtonTap("secondary") }
                )
            }
        }

        // Configure window parameters
        val params = createWindowParams()

        try {
            windowManager.addView(composeView, params)
            overlayView = composeView
            Log.d(TAG, "Shield shown for: $packageId")
        } catch (e: Exception) {
            overlayView = null
            currentBlockedPackage = null
            overlayContext = appContext
            Log.e(TAG, "Failed to show shield overlay", e)
        }
    }

    /**
     * Hides the shield overlay if currently visible.
     */
    fun hideShield() {
        overlayView?.let { view ->
            try {
                windowManager.removeView(view)
                Log.d(TAG, "Shield hidden")
            } catch (e: Exception) {
                Log.e(TAG, "Failed to hide shield overlay", e)
            }
        }
        overlayView = null
        currentBlockedPackage = null
        overlayContext = appContext
    }

    /**
     * Checks if the shield overlay is currently visible.
     *
     * @return true if overlay is showing
     */
    fun isShowing(): Boolean = overlayView != null

    /**
     * Creates WindowManager.LayoutParams for the overlay window.
     */
    private fun createWindowParams(): WindowManager.LayoutParams {
        return WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.CENTER
        }
    }

    /**
     * Handles button tap events and navigates to home.
     */
    private fun handleButtonTap(buttonType: String) {
        val packageId = currentBlockedPackage ?: return

        // Navigate to home screen (matching iOS .close behavior)
        navigateToHome()

        // Hide the shield
        hideShield()
    }

    /**
     * Navigates to the home screen launcher.
     */
    private fun navigateToHome() {
        val homeIntent = Intent(Intent.ACTION_MAIN).apply {
            addCategory(Intent.CATEGORY_HOME)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }
        appContext.startActivity(homeIntent)
    }
}
