import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// Platform interface for app restriction functionality.
///
/// Defines the contract for platform-specific implementations
/// of app blocking and restriction features.

/// The interface for app restriction platform implementations.
abstract class AppRestrictionPlatform extends PlatformInterface {
  AppRestrictionPlatform() : super(token: _token);

  static final Object _token = Object();

  /// Configures the shield appearance for blocked apps.
  Future<void> configureShield(Map<String, dynamic> configuration) {
    throw UnimplementedError('configureShield() has not been implemented.');
  }

  /// Sets the list of apps to be restricted.
  Future<void> setRestrictedApps(List<String> packageIds) {
    throw UnimplementedError('setRestrictedApps() has not been implemented.');
  }

  /// Removes restriction from a specific app.
  Future<void> removeRestriction(String packageId) {
    throw UnimplementedError('removeRestriction() has not been implemented.');
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
