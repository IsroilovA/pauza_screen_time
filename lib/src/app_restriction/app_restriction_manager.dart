import 'package:pauza_screen_time/pauza_screen_time.dart';
import 'package:pauza_screen_time/src/app_restriction/app_restriction.dart';

/// Manager for app restriction and blocking functionality.
///
/// This class provides APIs to configure blocking shields
/// and manage restricted apps.

/// Manages app blocking and restriction functionality.
class AppRestrictionManager {
  final AppRestrictionPlatform _platform;

  AppRestrictionManager(this._platform);

  // ============================================================
  // Shield Configuration
  // ============================================================

  /// Configures the appearance of the blocking shield.
  ///
  /// Must be called before setting restrictions to define how
  /// the shield will appear when a restricted app is launched.
  ///
  /// Example:
  /// ```dart
  /// await manager.configureShield(ShieldConfiguration(
  ///   title: 'App Blocked',
  ///   subtitle: 'This app is currently restricted',
  ///   primaryButtonLabel: 'Close',
  /// ));
  /// ```
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
  /// [packageIds] - List of package identifiers (Android package names or iOS bundle IDs).
  Future<void> restrictApps(List<String> packageIds) {
    return _platform.setRestrictedApps(packageIds);
  }

  /// Removes restriction from a specific app.
  ///
  /// [packageId] - Package identifier of the app to unblock.
  Future<void> unrestrictApp(String packageId) {
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
  Future<bool> isAppRestricted(String packageId) async {
    final restricted = await getRestrictedApps();
    return restricted.contains(packageId);
  }
}
