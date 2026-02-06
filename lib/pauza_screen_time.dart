/// Pauza Screen Time Plugin
///
/// A Flutter plugin for monitoring, restricting, and analyzing application usage.
/// Provides unified API for Android (AccessibilityService) and iOS (Screen Time API).
///
/// This plugin uses a feature-based architecture with separate modules for:
/// - App restriction and blocking
/// - Usage statistics and analytics
/// - Permission management
/// - Installed apps enumeration
library;

// Export feature modules for consumer use.
export 'src/core/core.dart';
export 'src/features/installed_apps/installed_apps.dart';
export 'src/features/permissions/permissions.dart';
export 'src/features/restrict_apps/restrict_apps.dart';
export 'src/features/usage_stats/usage_stats.dart';
