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

import 'package:pauza_screen_time/pauza_screen_time.dart';
import 'package:pauza_screen_time/src/method_channel_impl.dart';

// Export models and managers for consumer use
export 'src/core/models/models.dart';
export 'src/permissions/permissions.dart';
export 'src/app_restriction/model/model.dart';
export 'src/app_restriction/app_restriction_manager.dart';
export 'src/installed_apps/installed_apps_manager.dart';
export 'src/permissions/permission_manager.dart';
export 'src/usage_stats/usage_stats.dart';

/// Main plugin class for restricting and monitoring application usage.
///
/// This plugin provides feature-specific managers for different functionality:
/// - [appRestriction] - Block and restrict apps
/// - [usageStats] - Query usage statistics with daily breakdown
/// - [permissions] - Manage platform-specific permissions
/// - [installedApps] - Enumerate and search installed apps (Android only; iOS supports selection tokens via picker)
///
/// Example usage:
/// ```dart
/// final plugin = PauzaScreenTime();
///
/// // Configure the blocking shield
/// await plugin.appRestriction.configureShield(ShieldConfiguration(
///   title: 'App Blocked',
///   subtitle: 'This app is currently restricted',
///   primaryButtonLabel: 'Close',
/// ));
///
/// // Restrict apps
/// await plugin.appRestriction.restrictApps(['com.example.app']);
///
/// // Get usage stats with daily breakdown
/// final stats = await plugin.usageStats.getWeekStats();
///
/// // Check permissions (platform-specific)
/// if (Platform.isAndroid) {
///   final status = await plugin.permissions.checkAndroidPermission(
///     AndroidPermission.usageStats
///   );
/// }
/// ```
class PauzaScreenTime {
  final _platform = MethodChannelPauzaScreenTime();

  // Lazy-initialized managers
  AppRestrictionManager? _appRestrictionManager;
  UsageStatsManager? _usageStatsManager;
  PermissionManager? _permissionManager;
  InstalledAppsManager? _installedAppsManager;

  // ============================================================
  // Feature Managers
  // ============================================================

  /// Manager for app restriction and blocking functionality.
  ///
  /// Provides APIs to configure shields and restrict apps.
  AppRestrictionManager get appRestriction {
    _appRestrictionManager ??= AppRestrictionManager(_platform);
    return _appRestrictionManager!;
  }

  /// Manager for app usage statistics and analytics.
  ///
  /// Provides APIs to query usage stats with daily breakdown and analyze patterns.
  UsageStatsManager get usageStats {
    _usageStatsManager ??= UsageStatsManager(_platform);
    return _usageStatsManager!;
  }

  /// Manager for platform-specific permissions.
  ///
  /// Provides APIs to check and request Android/iOS permissions separately.
  PermissionManager get permissions {
    _permissionManager ??= PermissionManager(_platform);
    return _permissionManager!;
  }

  /// Manager for installed applications enumeration.
  ///
  /// Provides APIs to list, search, and filter installed apps.
  InstalledAppsManager get installedApps {
    _installedAppsManager ??= InstalledAppsManager(_platform);
    return _installedAppsManager!;
  }

  // ============================================================
  // Utility
  // ============================================================

  /// Returns the current platform version (for testing/debugging).
  Future<String?> getPlatformVersion() {
    return _platform.getPlatformVersion();
  }
}
