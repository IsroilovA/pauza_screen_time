import 'package:pauza_screen_time/src/features/restrict_apps/app_restriction_platform.dart';
import 'package:pauza_screen_time/src/features/restrict_apps/method_channel/restrictions_method_channel.dart';
import 'package:pauza_screen_time/src/features/restrict_apps/model/shield_configuration.dart';

/// Manages app blocking and restriction functionality.
class AppRestrictionManager {
  final AppRestrictionPlatform _platform;

  AppRestrictionManager({
    AppRestrictionPlatform? platform,
  }) : _platform = platform ?? RestrictionsMethodChannel();

  // ============================================================
  // Shield Configuration
  // ============================================================

  /// Configures the appearance of the blocking shield.
  ///
  /// Must be called before setting restrictions to define how
  /// the shield will appear when a restricted app is launched.
  Future<void> configureShield(ShieldConfiguration configuration) {
    return _platform.configureShield(configuration.toMap());
  }

  // ============================================================
  // Restriction Management
  // ============================================================

  /// Restricts the specified apps by their package IDs.
  ///
  /// When a restricted app is launched, the configured shield will be displayed.
  ///
  /// Returns the list of identifiers that were successfully applied on the
  /// native side (deduplicated, input-order-preserving).
  ///
  /// [packageIds] - List of identifiers:
  /// - Android: package names.
  /// - iOS: base64 `ApplicationToken` strings (from FamilyActivityPicker).
  Future<List<String>> restrictApps(List<String> packageIds) {
    return _platform.setRestrictedApps(packageIds);
  }

  /// Restricts a single app.
  ///
  /// Returns `true` if the restricted set changed, `false` if it was a no-op.
  Future<bool> restrictApp(String packageId) {
    return _platform.addRestrictedApp(packageId);
  }

  /// Removes restriction from a specific app.
  ///
  /// [packageId] - Package identifier of the app to unblock.
  ///
  /// Returns `true` if the restricted set changed, `false` if it was a no-op.
  Future<bool> unrestrictApp(String packageId) {
    return _platform.removeRestriction(packageId);
  }

  /// Removes all app restrictions.
  Future<void> clearAllRestrictions() {
    return _platform.removeAllRestrictions();
  }

  /// Returns the list of currently restricted package IDs.
  Future<List<String>> getRestrictedApps() {
    return _platform.getRestrictedApps();
  }

  /// Checks if a specific app is currently restricted.
  Future<bool> isAppRestricted(String packageId) {
    return _platform.isRestricted(packageId);
  }
}

