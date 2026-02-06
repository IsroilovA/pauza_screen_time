import 'dart:io';

import 'package:pauza_screen_time/src/features/permissions/method_channel/permissions_method_channel.dart';
import 'package:pauza_screen_time/src/features/permissions/model/android_permission.dart';
import 'package:pauza_screen_time/src/features/permissions/model/ios_permission.dart';
import 'package:pauza_screen_time/src/features/permissions/model/permission_status.dart';
import 'package:pauza_screen_time/src/features/permissions/permission_platform.dart';

/// Manages platform-specific permissions.
class PermissionManager {
  final PermissionPlatform _platform;

  PermissionManager({PermissionPlatform? platform})
    : _platform = platform ?? PermissionsMethodChannel();

  // ============================================================
  // Android Permissions
  // ============================================================

  /// Checks the status of an Android permission.
  ///
  /// Only call this on Android platform.
  Future<PermissionStatus> checkAndroidPermission(
    AndroidPermission permission,
  ) {
    assert(Platform.isAndroid, 'This method is only available on Android');
    return _platform.checkPermission(permission.key);
  }

  /// Requests an Android permission from the user.
  ///
  /// Returns true if the permission was granted.
  /// Only call this on Android platform.
  Future<bool> requestAndroidPermission(AndroidPermission permission) {
    assert(Platform.isAndroid, 'This method is only available on Android');
    return _platform.requestPermission(permission.key);
  }

  /// Opens the system settings page for the specified Android permission.
  ///
  /// Useful when a permission needs to be granted manually.
  /// Only call this on Android platform.
  Future<void> openAndroidPermissionSettings(AndroidPermission permission) {
    assert(Platform.isAndroid, 'This method is only available on Android');
    return _platform.openPermissionSettings(permission.key);
  }

  // ============================================================
  // iOS Permissions
  // ============================================================

  /// Checks the status of an iOS permission.
  ///
  /// Only call this on iOS platform.
  Future<PermissionStatus> checkIOSPermission(IOSPermission permission) {
    assert(Platform.isIOS, 'This method is only available on iOS');
    return _platform.checkPermission(permission.key);
  }

  /// Requests an iOS permission from the user.
  ///
  /// Returns true if the permission was granted.
  /// Only call this on iOS platform.
  Future<bool> requestIOSPermission(IOSPermission permission) {
    assert(Platform.isIOS, 'This method is only available on iOS');
    return _platform.requestPermission(permission.key);
  }

  // ============================================================
  // Typed Batch Permission Checks
  // ============================================================

  /// Checks the status of multiple Android permissions.
  ///
  /// Returns a typed map of permissions to their status.
  /// Only call this on Android platform.
  Future<Map<AndroidPermission, PermissionStatus>> checkAndroidPermissions(
    List<AndroidPermission> permissions,
  ) async {
    assert(Platform.isAndroid, 'This method is only available on Android');
    final results = <AndroidPermission, PermissionStatus>{};
    for (final permission in permissions) {
      results[permission] = await _platform.checkPermission(permission.key);
    }
    return results;
  }

  /// Checks the status of multiple iOS permissions.
  ///
  /// Returns a typed map of permissions to their status.
  /// Only call this on iOS platform.
  Future<Map<IOSPermission, PermissionStatus>> checkIOSPermissions(
    List<IOSPermission> permissions,
  ) async {
    assert(Platform.isIOS, 'This method is only available on iOS');
    final results = <IOSPermission, PermissionStatus>{};
    for (final permission in permissions) {
      results[permission] = await _platform.checkPermission(permission.key);
    }
    return results;
  }

  /// Returns a list of Android permissions that are not granted.
  ///
  /// If [subset] is provided, only checks those permissions.
  /// Otherwise, checks all Android permissions.
  Future<List<AndroidPermission>> getMissingAndroidPermissions([
    List<AndroidPermission>? subset,
  ]) async {
    assert(Platform.isAndroid, 'This method is only available on Android');
    final permissionsToCheck = subset ?? AndroidPermission.values;
    final statuses = await checkAndroidPermissions(permissionsToCheck);
    return statuses.entries
        .where((entry) => !entry.value.isGranted)
        .map((entry) => entry.key)
        .toList();
  }

  /// Returns a list of iOS permissions that are not granted.
  ///
  /// If [subset] is provided, only checks those permissions.
  /// Otherwise, checks all iOS permissions.
  Future<List<IOSPermission>> getMissingIOSPermissions([
    List<IOSPermission>? subset,
  ]) async {
    assert(Platform.isIOS, 'This method is only available on iOS');
    final permissionsToCheck = subset ?? IOSPermission.values;
    final statuses = await checkIOSPermissions(permissionsToCheck);
    return statuses.entries
        .where((entry) => !entry.value.isGranted)
        .map((entry) => entry.key)
        .toList();
  }
}
