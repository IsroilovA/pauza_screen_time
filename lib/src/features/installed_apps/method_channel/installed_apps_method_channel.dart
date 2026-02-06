import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:pauza_screen_time/src/core/background_channel_runner.dart';
import 'package:pauza_screen_time/src/features/installed_apps/installed_apps_platform.dart';
import 'package:pauza_screen_time/src/features/installed_apps/method_channel/channel_name.dart';
import 'package:pauza_screen_time/src/features/installed_apps/method_channel/method_names.dart';

/// Method-channel implementation for the Installed Apps feature.
class InstalledAppsMethodChannel extends InstalledAppsPlatform {
  @visibleForTesting
  final MethodChannel channel;

  InstalledAppsMethodChannel({MethodChannel? channel})
    : channel = channel ?? const MethodChannel(installedAppsChannelName);

  @override
  Future<List<Map<dynamic, dynamic>>> getInstalledApps(
    bool includeSystemApps, [
    bool includeIcons = true,
  ]) async {
    if (Platform.isIOS) {
      throw UnsupportedError(
        'getInstalledApps() is only supported on Android.',
      );
    }

    final result = await BackgroundChannelRunner.invokeMethod<List<dynamic>>(
      channel.name,
      InstalledAppsMethodNames.getInstalledApps,
      arguments: {
        'includeSystemApps': includeSystemApps,
        'includeIcons': includeIcons,
      },
    );
    if (result == null) return [];
    return result.cast<Map<dynamic, dynamic>>();
  }

  @override
  Future<Map<dynamic, dynamic>?> getAppInfo(
    String packageId, [
    bool includeIcons = true,
  ]) {
    if (Platform.isIOS) {
      throw UnsupportedError('getAppInfo() is only supported on Android.');
    }

    return BackgroundChannelRunner.invokeMethod<Map<dynamic, dynamic>?>(
      channel.name,
      InstalledAppsMethodNames.getAppInfo,
      arguments: {'packageId': packageId, 'includeIcons': includeIcons},
    );
  }

  @override
  Future<List<Map<dynamic, dynamic>>> showFamilyActivityPicker({
    List<String>? preSelectedTokens,
  }) async {
    if (Platform.isAndroid) {
      throw UnsupportedError(
        'showFamilyActivityPicker() is only supported on iOS.',
      );
    }

    final result = await channel.invokeMethod<List<dynamic>>(
      InstalledAppsMethodNames.showFamilyActivityPicker,
      {'preSelectedTokens': preSelectedTokens ?? []},
    );
    if (result == null) return [];
    return result.cast<Map<dynamic, dynamic>>();
  }
}
