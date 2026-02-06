import 'dart:io';

import 'package:pauza_screen_time/src/features/installed_apps/installed_apps_platform.dart';
import 'package:pauza_screen_time/src/features/installed_apps/method_channel/installed_apps_method_channel.dart';
import 'package:pauza_screen_time/src/features/installed_apps/model/app_info.dart';

/// Manages installed applications enumeration.
class InstalledAppsManager {
  final InstalledAppsPlatform _platform;

  InstalledAppsManager({InstalledAppsPlatform? platform})
    : _platform = platform ?? InstalledAppsMethodChannel();

  // ============================================================
  // Android-Only Methods
  // ============================================================

  /// Returns a list of all installed applications on Android.
  ///
  /// **Android only** - Throws [UnsupportedError] on other platforms.
  ///
  /// [includeSystemApps] - Whether to include system apps (default: false).
  /// [includeIcons] - Whether to include app icons (default: true).
  Future<List<AndroidAppInfo>> getAndroidInstalledApps({
    bool includeSystemApps = false,
    bool includeIcons = true,
  }) async {
    if (!Platform.isAndroid) {
      throw UnsupportedError(
        'getAndroidInstalledApps is only available on Android',
      );
    }

    final result = await _platform.getInstalledApps(
      includeSystemApps,
      includeIcons,
    );
    return result
        .map((item) => AppInfo.fromMap(Map<String, dynamic>.from(item)))
        .whereType<AndroidAppInfo>()
        .toList();
  }

  /// Returns information about a specific Android app by package ID.
  ///
  /// **Android only** - Throws [UnsupportedError] on other platforms.
  ///
  /// [packageId] - Package identifier of the app (e.g., "com.example.app").
  /// [includeIcons] - Whether to include app icons (default: true).
  /// Returns null if the app is not found.
  Future<AndroidAppInfo?> getAndroidAppInfo(
    String packageId, {
    bool includeIcons = true,
  }) async {
    if (!Platform.isAndroid) {
      throw UnsupportedError('getAndroidAppInfo is only available on Android');
    }

    final result = await _platform.getAppInfo(packageId, includeIcons);
    if (result == null) return null;

    final appInfo = AppInfo.fromMap(Map<String, dynamic>.from(result));
    return appInfo is AndroidAppInfo ? appInfo : null;
  }

  /// Checks if a specific Android app is installed.
  ///
  /// **Android only** - Throws [UnsupportedError] on other platforms.
  ///
  /// [packageId] - Package identifier of the app.
  /// Returns true if the app is installed, false otherwise.
  Future<bool> isAndroidAppInstalled(String packageId) async {
    if (!Platform.isAndroid) {
      throw UnsupportedError(
        'isAndroidAppInstalled is only available on Android',
      );
    }

    final appInfo = await getAndroidAppInfo(packageId);
    return appInfo != null;
  }

  // ============================================================
  // iOS-Only Methods
  // ============================================================

  /// Shows the iOS FamilyActivityPicker for user to select apps.
  ///
  /// **iOS only** - Throws [UnsupportedError] on other platforms.
  ///
  /// [preSelectedApps] - Optional list of previously selected apps that should
  /// appear pre-selected when the picker opens. Pass apps retrieved from a
  /// previous [selectIOSApps] call or from your local storage.
  ///
  /// Returns a list of opaque selection tokens as [IOSAppInfo] objects.
  ///
  /// iOS does not allow enumerating installed apps. Persist these tokens yourself
  /// if you want to re-open the picker with a previous selection.
  Future<List<IOSAppInfo>> selectIOSApps({
    List<IOSAppInfo>? preSelectedApps,
  }) async {
    if (!Platform.isIOS) {
      throw UnsupportedError('selectIOSApps is only available on iOS');
    }

    // Extract tokens from pre-selected apps
    final preSelectedTokens = preSelectedApps
        ?.map((app) => app.applicationToken)
        .toList();

    final result = await _platform.showFamilyActivityPicker(
      preSelectedTokens: preSelectedTokens,
    );
    return result
        .map((item) => AppInfo.fromMap(Map<String, dynamic>.from(item)))
        .whereType<IOSAppInfo>()
        .toList();
  }
}
