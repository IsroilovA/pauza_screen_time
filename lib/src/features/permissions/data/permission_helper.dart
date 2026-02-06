import 'dart:io';

import 'package:pauza_screen_time/src/features/permissions/model/android_permission.dart';
import 'package:pauza_screen_time/src/features/permissions/model/ios_permission.dart';
import 'package:pauza_screen_time/src/features/permissions/model/permission_status.dart';
import 'package:pauza_screen_time/src/features/permissions/data/permission_manager.dart';

/// Helper class for managing permissions.
///
/// This class provides convenience methods to check and request multiple permissions
/// at once, utilizing [PermissionManager].
class PermissionHelper {
  final PermissionManager _permissionManager;

  const PermissionHelper(this._permissionManager);

  /// Checks all required permissions for the current platform.
  ///
  /// Returns a map of permission keys to their status.
  /// Consider using [PermissionManager.checkAndroidPermissions] or
  /// [PermissionManager.checkIOSPermissions] for typed results.
  Future<Map<String, PermissionStatus>> checkAllRequiredPermissions() async {
    final results = <String, PermissionStatus>{};

    if (Platform.isAndroid) {
      final typed = await _permissionManager.checkAndroidPermissions(
        AndroidPermission.values,
      );
      for (final entry in typed.entries) {
        results[entry.key.key] = entry.value;
      }
    } else if (Platform.isIOS) {
      final typed = await _permissionManager.checkIOSPermissions(
        IOSPermission.values,
      );
      for (final entry in typed.entries) {
        results[entry.key.key] = entry.value;
      }
    }

    return results;
  }

  /// Requests all required permissions for the current platform.
  ///
  /// Returns true if all permissions were granted.
  Future<bool> requestAllRequiredPermissions() async {
    if (Platform.isAndroid) {
      final results = await Future.wait([
        _permissionManager.requestAndroidPermission(
          AndroidPermission.usageStats,
        ),
        _permissionManager.requestAndroidPermission(
          AndroidPermission.accessibility,
        ),
        _permissionManager.requestAndroidPermission(
          AndroidPermission.queryAllPackages,
        ),
      ]);
      return results.every((granted) => granted);
    } else if (Platform.isIOS) {
      final results = await Future.wait([
        _permissionManager.requestIOSPermission(IOSPermission.familyControls),
        _permissionManager.requestIOSPermission(IOSPermission.screenTime),
      ]);
      return results.every((granted) => granted);
    }

    return false;
  }

  /// Checks if all required permissions are granted.
  Future<bool> areAllPermissionsGranted() async {
    final statuses = await checkAllRequiredPermissions();
    return statuses.values.every((status) => status.isGranted);
  }

  /// Returns a list of permissions that are not granted.
  Future<List<String>> getMissingPermissions() async {
    final statuses = await checkAllRequiredPermissions();
    return statuses.entries
        .where((entry) => !entry.value.isGranted)
        .map((entry) => entry.key)
        .toList();
  }
}
