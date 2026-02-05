package com.example.pauza_screen_time.app_restriction.overlay

import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.LifecycleRegistry
import androidx.savedstate.SavedStateRegistry
import androidx.savedstate.SavedStateRegistryController
import androidx.savedstate.SavedStateRegistryOwner

/**
 * Contains LifecycleOwner and SavedStateRegistryOwner implementations for
 * hosting a ComposeView in a WindowManager overlay context.
 *
 * These classes are required because ComposeView needs access to the view tree
 * lifecycle and saved state registry, which are not automatically available
 * when attaching views directly to WindowManager.
 */

/**
 * LifecycleOwner implementation for overlay ComposeViews.
 *
 * Immediately moves to RESUMED state on creation since overlays
 * are always visible when added to WindowManager.
 */
class OverlayLifecycleOwner : LifecycleOwner {
    private val lifecycleRegistry = LifecycleRegistry(this)

    init {
        lifecycleRegistry.currentState = Lifecycle.State.RESUMED
    }

    override val lifecycle: Lifecycle
        get() = lifecycleRegistry
}

/**
 * SavedStateRegistryOwner implementation for overlay ComposeViews.
 *
 * Provides both lifecycle and saved state registry needed by Compose components
 * that might use rememberSaveable or other state restoration APIs.
 */
class OverlaySavedStateRegistryOwner : SavedStateRegistryOwner {
    private val lifecycleRegistry = LifecycleRegistry(this)
    private val savedStateRegistryController = SavedStateRegistryController.create(this)

    init {
        savedStateRegistryController.performAttach()
        savedStateRegistryController.performRestore(null)
        lifecycleRegistry.currentState = Lifecycle.State.RESUMED
    }

    override val lifecycle: Lifecycle
        get() = lifecycleRegistry

    override val savedStateRegistry: SavedStateRegistry
        get() = savedStateRegistryController.savedStateRegistry
}
