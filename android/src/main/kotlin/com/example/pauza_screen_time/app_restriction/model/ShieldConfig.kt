package com.example.pauza_screen_time.app_restriction.model

/**
 * Data class representing shield overlay configuration from Flutter.
 *
 * This model holds all visual and behavioral configuration for the blocking
 * shield overlay, including colors, text, button labels, and icon data.
 */
data class ShieldConfig(
    val title: String,
    val subtitle: String?,
    val backgroundColor: Int,
    val titleColor: Int,
    val subtitleColor: Int,
    val backgroundBlurStyle: String?,
    val iconBytes: ByteArray?,
    val primaryButtonLabel: String?,
    val primaryButtonBackgroundColor: Int?,
    val primaryButtonTextColor: Int?,
    val secondaryButtonLabel: String?,
    val secondaryButtonTextColor: Int?
) {
    companion object {
        /**
         * Default configuration used when no Flutter configuration is provided.
         */
        val DEFAULT = ShieldConfig(
            title = "App Blocked",
            subtitle = "This app has been restricted.",
            backgroundColor = 0xFF1A1A2E.toInt(),
            titleColor = 0xFFFFFFFF.toInt(),
            subtitleColor = 0xFFB0B0B0.toInt(),
            backgroundBlurStyle = null,
            iconBytes = null,
            primaryButtonLabel = "OK",
            primaryButtonBackgroundColor = 0xFF6366F1.toInt(),
            primaryButtonTextColor = 0xFFFFFFFF.toInt(),
            secondaryButtonLabel = null,
            secondaryButtonTextColor = null
        )

        /**
         * Creates a ShieldConfig from a Flutter method channel map.
         *
         * @param configMap Map containing configuration parameters from Flutter
         * @return Parsed ShieldConfig instance
         */
        fun fromMap(configMap: Map<String, Any?>): ShieldConfig {
            return ShieldConfig(
                title = configMap["title"] as? String ?: "App Blocked",
                subtitle = configMap["subtitle"] as? String,
                backgroundColor = (configMap["backgroundColor"] as? Number)?.toInt() ?: 0xFF1A1A2E.toInt(),
                titleColor = (configMap["titleColor"] as? Number)?.toInt() ?: 0xFFFFFFFF.toInt(),
                subtitleColor = (configMap["subtitleColor"] as? Number)?.toInt() ?: 0xFFB0B0B0.toInt(),
                backgroundBlurStyle = configMap["backgroundBlurStyle"] as? String,
                iconBytes = configMap["iconBytes"] as? ByteArray,
                primaryButtonLabel = configMap["primaryButtonLabel"] as? String,
                primaryButtonBackgroundColor = (configMap["primaryButtonBackgroundColor"] as? Number)?.toInt(),
                primaryButtonTextColor = (configMap["primaryButtonTextColor"] as? Number)?.toInt(),
                secondaryButtonLabel = configMap["secondaryButtonLabel"] as? String,
                secondaryButtonTextColor = (configMap["secondaryButtonTextColor"] as? Number)?.toInt()
            )
        }
    }

    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (javaClass != other?.javaClass) return false
        other as ShieldConfig
        return title == other.title &&
            subtitle == other.subtitle &&
            backgroundColor == other.backgroundColor &&
            titleColor == other.titleColor &&
            subtitleColor == other.subtitleColor &&
            backgroundBlurStyle == other.backgroundBlurStyle &&
            iconBytes?.contentEquals(other.iconBytes) ?: (other.iconBytes == null) &&
            primaryButtonLabel == other.primaryButtonLabel &&
            primaryButtonBackgroundColor == other.primaryButtonBackgroundColor &&
            primaryButtonTextColor == other.primaryButtonTextColor &&
            secondaryButtonLabel == other.secondaryButtonLabel &&
            secondaryButtonTextColor == other.secondaryButtonTextColor
    }

    override fun hashCode(): Int {
        var result = title.hashCode()
        result = 31 * result + (subtitle?.hashCode() ?: 0)
        result = 31 * result + backgroundColor
        result = 31 * result + titleColor
        result = 31 * result + subtitleColor
        result = 31 * result + (backgroundBlurStyle?.hashCode() ?: 0)
        result = 31 * result + (iconBytes?.contentHashCode() ?: 0)
        result = 31 * result + (primaryButtonLabel?.hashCode() ?: 0)
        result = 31 * result + (primaryButtonBackgroundColor ?: 0)
        result = 31 * result + (primaryButtonTextColor ?: 0)
        result = 31 * result + (secondaryButtonLabel?.hashCode() ?: 0)
        result = 31 * result + (secondaryButtonTextColor ?: 0)
        return result
    }
}
