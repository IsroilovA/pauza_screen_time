package com.example.pauza_screen_time.utils

import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.os.Build
import java.io.ByteArrayOutputStream

/**
 * Utility object for common application information operations.
 */
object AppInfoUtils {

    /**
     * Extracts the app icon as a byte array (PNG format).
     *
     * @param appInfo ApplicationInfo object
     * @param packageManager PackageManager instance
     * @return ByteArray of the PNG icon, or null if extraction fails
     */
    fun extractAppIcon(appInfo: ApplicationInfo, packageManager: PackageManager): ByteArray? {
        return try {
            val icon = appInfo.loadIcon(packageManager)
            val bitmap = drawableToBitmap(icon)

            val outputStream = ByteArrayOutputStream()
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, outputStream)
            outputStream.toByteArray()
        } catch (e: Exception) {
            android.util.Log.e("AppInfoUtils", "Error extracting icon for ${appInfo.packageName}", e)
            null
        }
    }

    /**
     * Converts a Drawable to a Bitmap.
     *
     * @param drawable The drawable to convert
     * @return Bitmap representation of the drawable
     */
    fun drawableToBitmap(drawable: Drawable): Bitmap {
        if (drawable is BitmapDrawable) {
            if (drawable.bitmap != null) {
                return drawable.bitmap
            }
        }

        val bitmap = if (drawable.intrinsicWidth <= 0 || drawable.intrinsicHeight <= 0) {
            // Create 1x1 pixel bitmap for drawables with no size
            Bitmap.createBitmap(1, 1, Bitmap.Config.ARGB_8888)
        } else {
            Bitmap.createBitmap(
                drawable.intrinsicWidth,
                drawable.intrinsicHeight,
                Bitmap.Config.ARGB_8888
            )
        }

        val canvas = Canvas(bitmap)
        drawable.setBounds(0, 0, canvas.width, canvas.height)
        drawable.draw(canvas)
        return bitmap
    }

    /**
     * Gets the app category as a string.
     *
     * @param appInfo ApplicationInfo object
     * @return Category name or null if not available
     */
    fun getAppCategory(appInfo: ApplicationInfo): String? {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            when (appInfo.category) {
                ApplicationInfo.CATEGORY_GAME -> "Games"
                ApplicationInfo.CATEGORY_AUDIO -> "Audio"
                ApplicationInfo.CATEGORY_VIDEO -> "Video"
                ApplicationInfo.CATEGORY_IMAGE -> "Image"
                ApplicationInfo.CATEGORY_SOCIAL -> "Social"
                ApplicationInfo.CATEGORY_NEWS -> "News"
                ApplicationInfo.CATEGORY_MAPS -> "Maps"
                ApplicationInfo.CATEGORY_PRODUCTIVITY -> "Productivity"
                else -> null
            }
        } else {
            null
        }
    }

    /**
     * Checks if an app is a system app.
     *
     * @param appInfo ApplicationInfo object
     * @return true if the app is a system app, false otherwise
     */
    fun isSystemApp(appInfo: ApplicationInfo): Boolean {
        return (appInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0
    }
}
