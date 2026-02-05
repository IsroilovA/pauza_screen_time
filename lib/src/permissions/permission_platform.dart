import 'package:pauza_screen_time/pauza_screen_time.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// Platform interface for permission management functionality.
///
/// Defines the contract for platform-specific implementations
/// of permission checking and requesting.

/// The interface for permission platform implementations.
abstract class PermissionPlatform extends PlatformInterface {
  PermissionPlatform() : super(token: _token);

  static final Object _token = Object();

  /// Checks the status of a specific permission.
  ///
  /// [permissionKey] - Platform-specific permission key (e.g., 'android.usageStats').
  Future<PermissionStatus> checkPermission(String permissionKey) {
    throw UnimplementedError('checkPermission() has not been implemented.');
  }

  /// Requests a specific permission from the user.
  ///
  /// Returns true if the permission was granted.
  Future<bool> requestPermission(String permissionKey) {
    throw UnimplementedError('requestPermission() has not been implemented.');
  }

  /// Opens the system settings page for the specified permission.
  Future<void> openPermissionSettings(String permissionKey) {
    throw UnimplementedError('openPermissionSettings() has not been implemented.');
  }
}
