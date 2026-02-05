import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:pauza_screen_time/pauza_screen_time.dart';
import 'package:pauza_screen_time/src/app_restriction/app_restriction.dart';
import 'package:pauza_screen_time/src/core/background_channel_runner.dart';
import 'package:pauza_screen_time/src/installed_apps/installed_apps.dart';

/// Method channel implementation of the platform interfaces.
///
/// Provides the concrete implementation of platform communication
/// using Flutter method channels and event channels.

/// Method channel implementation of all platform interfaces.
class MethodChannelPauzaScreenTime
    implements
        AppRestrictionPlatform,
        UsageStatsPlatform,
        PermissionPlatform,
        InstalledAppsPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('pauza_screen_time');

  // Singleton instance
  static final MethodChannelPauzaScreenTime _instance = MethodChannelPauzaScreenTime._();

  MethodChannelPauzaScreenTime._();

  factory MethodChannelPauzaScreenTime() => _instance;

  /// Returns the current platform version (for testing/debugging).
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  // ============================================================
  // App Restriction Platform
  // ============================================================

  @override
  Future<void> configureShield(Map<String, dynamic> configuration) async {
    await methodChannel.invokeMethod<void>('configureShield', configuration);
  }

  @override
  Future<void> setRestrictedApps(List<String> packageIds) async {
    await methodChannel.invokeMethod<void>('setRestrictedApps', {'packageIds': packageIds});
  }

  @override
  Future<void> removeRestriction(String packageId) async {
    await methodChannel.invokeMethod<void>('removeRestriction', {'packageId': packageId});
  }

  @override
  Future<void> removeAllRestrictions() async {
    await methodChannel.invokeMethod<void>('removeAllRestrictions');
  }

  @override
  Future<List<String>> getRestrictedApps() async {
    final result = await methodChannel.invokeMethod<List<dynamic>>('getRestrictedApps');
    if (result == null) return [];
    return result.cast<String>();
  }

  // ============================================================
  // Usage Stats Platform
  // ============================================================

  @override
  Future<List<Map<dynamic, dynamic>>> queryUsageStats({
    required int startTimeMs,
    required int endTimeMs,
    bool includeIcons = true,
  }) async {
    if (Platform.isIOS) {
      throw UnsupportedError(
        'queryUsageStats() is only supported on Android. '
        'On iOS, use DeviceActivityReport platform view for usage statistics.',
      );
    }
    final result = await BackgroundChannelRunner.invokeMethod<List<dynamic>>(
      methodChannel.name,
      'queryUsageStats',
      arguments: {'startTimeMs': startTimeMs, 'endTimeMs': endTimeMs, 'includeIcons': includeIcons},
    );
    if (result == null) return [];
    return result.cast<Map<dynamic, dynamic>>();
  }

  @override
  Future<Map<dynamic, dynamic>?> queryAppUsageStats({
    required String packageId,
    required int startTimeMs,
    required int endTimeMs,
    bool includeIcons = true,
  }) async {
    if (Platform.isIOS) {
      throw UnsupportedError(
        'queryAppUsageStats() is only supported on Android. '
        'On iOS, use DeviceActivityReport platform view for usage statistics.',
      );
    }
    return BackgroundChannelRunner.invokeMethod<Map<dynamic, dynamic>?>(
      methodChannel.name,
      'queryAppUsageStats',
      arguments: {
        'packageId': packageId,
        'startTimeMs': startTimeMs,
        'endTimeMs': endTimeMs,
        'includeIcons': includeIcons,
      },
    );
  }

  // ============================================================
  // Permission Platform
  // ============================================================

  @override
  Future<PermissionStatus> checkPermission(String permissionKey) async {
    final result = await methodChannel.invokeMethod<String>('checkPermission', {
      'permissionKey': permissionKey,
    });
    if (result == null) {
      throw StateError('Native layer returned null for permission check: $permissionKey');
    }
    return PermissionStatus.fromString(result);
  }

  @override
  Future<bool> requestPermission(String permissionKey) async {
    final result = await methodChannel.invokeMethod<bool>('requestPermission', {
      'permissionKey': permissionKey,
    });
    return result ?? false;
  }

  @override
  Future<void> openPermissionSettings(String permissionKey) async {
    await methodChannel.invokeMethod<void>('openPermissionSettings', {
      'permissionKey': permissionKey,
    });
  }

  // ============================================================
  // Installed Apps Platform
  // ============================================================

  @override
  Future<List<Map<dynamic, dynamic>>> getInstalledApps(
    bool includeSystemApps, [
    bool includeIcons = true,
  ]) async {
    if (Platform.isIOS) {
      throw UnsupportedError('getInstalledApps() is only supported on Android.');
    }
    final result = await BackgroundChannelRunner.invokeMethod<List<dynamic>>(
      methodChannel.name,
      'getInstalledApps',
      arguments: {'includeSystemApps': includeSystemApps, 'includeIcons': includeIcons},
    );
    if (result == null) return [];
    return result.cast<Map<dynamic, dynamic>>();
  }

  @override
  Future<Map<dynamic, dynamic>?> getAppInfo(String packageId, [bool includeIcons = true]) async {
    if (Platform.isIOS) {
      throw UnsupportedError('getAppInfo() is only supported on Android.');
    }
    return BackgroundChannelRunner.invokeMethod<Map<dynamic, dynamic>?>(
      methodChannel.name,
      'getAppInfo',
      arguments: {'packageId': packageId, 'includeIcons': includeIcons},
    );
  }

  @override
  Future<List<Map<dynamic, dynamic>>> showFamilyActivityPicker({
    List<String>? preSelectedTokens,
  }) async {
    if (Platform.isAndroid) {
      throw UnsupportedError('showFamilyActivityPicker() is only supported on iOS.');
    }
    final result = await methodChannel.invokeMethod<List<dynamic>>('showFamilyActivityPicker', {
      'preSelectedTokens': preSelectedTokens ?? [],
    });
    if (result == null) return [];
    return result.cast<Map<dynamic, dynamic>>();
  }
}
