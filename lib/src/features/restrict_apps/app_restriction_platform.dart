import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// Platform interface for app restriction functionality.
abstract class AppRestrictionPlatform extends PlatformInterface {
  AppRestrictionPlatform() : super(token: _token);

  static final Object _token = Object();

  /// Configures the shield appearance for blocked apps.
  Future<void> configureShield(Map<String, dynamic> configuration) {
    throw UnimplementedError('configureShield() has not been implemented.');
  }

  /// Sets the list of apps to be restricted.
  ///
  /// Returns the list of identifiers that were successfully applied on the
  /// native side (deduplicated, input-order-preserving).
  Future<List<String>> setRestrictedApps(List<String> packageIds) {
    throw UnimplementedError('setRestrictedApps() has not been implemented.');
  }

  /// Adds a single app to the restricted set.
  ///
  /// Returns `true` if the restricted set changed, `false` if it was a no-op.
  Future<bool> addRestrictedApp(String packageId) {
    throw UnimplementedError('addRestrictedApp() has not been implemented.');
  }

  /// Removes restriction from a specific app.
  ///
  /// Returns `true` if the restricted set changed, `false` if it was a no-op.
  Future<bool> removeRestriction(String packageId) {
    throw UnimplementedError('removeRestriction() has not been implemented.');
  }

  /// Checks if an app is currently restricted.
  Future<bool> isRestricted(String packageId) {
    throw UnimplementedError('isRestricted() has not been implemented.');
  }

  /// Removes all app restrictions.
  Future<void> removeAllRestrictions() {
    throw UnimplementedError('removeAllRestrictions() has not been implemented.');
  }

  /// Returns the list of currently restricted package IDs.
  Future<List<String>> getRestrictedApps() {
    throw UnimplementedError('getRestrictedApps() has not been implemented.');
  }
}

