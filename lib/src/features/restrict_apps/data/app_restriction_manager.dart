import 'package:pauza_screen_time/src/core/app_identifier.dart';
import 'package:pauza_screen_time/src/features/restrict_apps/app_restriction_platform.dart';
import 'package:pauza_screen_time/src/features/restrict_apps/method_channel/restrictions_method_channel.dart';
import 'package:pauza_screen_time/src/features/restrict_apps/model/restriction_session.dart';
import 'package:pauza_screen_time/src/features/restrict_apps/model/shield_configuration.dart';

/// Manages app blocking and restriction functionality.
class AppRestrictionManager {
  final AppRestrictionPlatform _platform;

  AppRestrictionManager({AppRestrictionPlatform? platform})
    : _platform = platform ?? RestrictionsMethodChannel();

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

  /// Restricts the specified apps by opaque identifiers.
  ///
  /// When a restricted app is launched, the configured shield will be displayed.
  ///
  /// Returns the list of identifiers that were successfully applied on the
  /// native side (deduplicated, input-order-preserving).
  ///
  /// [identifiers] - List of identifiers:
  /// - Android: package names.
  /// - iOS: base64 `ApplicationToken` strings (from FamilyActivityPicker).
  Future<List<AppIdentifier>> restrictApps(List<AppIdentifier> identifiers) {
    return _platform.setRestrictedApps(identifiers);
  }

  /// Restricts a single app.
  ///
  /// Returns `true` if the restricted set changed, `false` if it was a no-op.
  Future<bool> restrictApp(AppIdentifier identifier) {
    return _platform.addRestrictedApp(identifier);
  }

  /// Removes restriction from a specific app.
  ///
  /// [identifier] - Opaque identifier of the app to unblock.
  ///
  /// Returns `true` if the restricted set changed, `false` if it was a no-op.
  Future<bool> unrestrictApp(AppIdentifier identifier) {
    return _platform.removeRestriction(identifier);
  }

  /// Removes all app restrictions.
  Future<void> clearAllRestrictions() {
    return _platform.removeAllRestrictions();
  }

  /// Returns the list of currently restricted app identifiers.
  Future<List<AppIdentifier>> getRestrictedApps() {
    return _platform.getRestrictedApps();
  }

  /// Checks if a specific app is currently restricted.
  Future<bool> isAppRestricted(AppIdentifier identifier) {
    return _platform.isRestricted(identifier);
  }

  /// Returns whether the restriction session is active right now.
  Future<bool> isRestrictionSessionActiveNow() {
    return _platform.isRestrictionSessionActiveNow();
  }

  /// Returns whether a restriction session is configured.
  Future<bool> isRestrictionSessionConfigured() {
    return _platform.isRestrictionSessionConfigured();
  }

  /// Pauses restriction enforcement for the given [duration].
  Future<void> pauseEnforcement(Duration duration) {
    return _platform.pauseEnforcement(duration);
  }

  /// Resumes restriction enforcement immediately.
  Future<void> resumeEnforcement() {
    return _platform.resumeEnforcement();
  }

  /// Returns the current restriction session snapshot.
  Future<RestrictionSession> getRestrictionSession() {
    return _platform.getRestrictionSession();
  }
}
