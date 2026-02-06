import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:pauza_screen_time/src/features/restrict_apps/app_restriction_platform.dart';
import 'package:pauza_screen_time/src/features/restrict_apps/method_channel/channel_name.dart';
import 'package:pauza_screen_time/src/features/restrict_apps/method_channel/method_names.dart';

/// Method-channel implementation for the Restrict Apps feature.
class RestrictionsMethodChannel extends AppRestrictionPlatform {
  @visibleForTesting
  final MethodChannel channel;

  RestrictionsMethodChannel({
    MethodChannel? channel,
  }) : channel = channel ?? const MethodChannel(restrictionsChannelName);

  @override
  Future<void> configureShield(Map<String, dynamic> configuration) {
    return channel.invokeMethod<void>(RestrictionsMethodNames.configureShield, configuration);
  }

  @override
  Future<List<String>> setRestrictedApps(List<String> packageIds) async {
    final result = await channel.invokeMethod<List<dynamic>>(
      RestrictionsMethodNames.setRestrictedApps,
      {'packageIds': packageIds},
    );
    if (result == null) return [];
    return result.cast<String>();
  }

  @override
  Future<bool> addRestrictedApp(String packageId) async {
    final result = await channel.invokeMethod<bool>(
      RestrictionsMethodNames.addRestrictedApp,
      {'packageId': packageId},
    );
    return result ?? false;
  }

  @override
  Future<bool> removeRestriction(String packageId) async {
    final result = await channel.invokeMethod<bool>(
      RestrictionsMethodNames.removeRestriction,
      {'packageId': packageId},
    );
    return result ?? false;
  }

  @override
  Future<bool> isRestricted(String packageId) async {
    final result = await channel.invokeMethod<bool>(
      RestrictionsMethodNames.isRestricted,
      {'packageId': packageId},
    );
    return result ?? false;
  }

  @override
  Future<void> removeAllRestrictions() {
    return channel.invokeMethod<void>(RestrictionsMethodNames.removeAllRestrictions);
  }

  @override
  Future<List<String>> getRestrictedApps() async {
    final result = await channel.invokeMethod<List<dynamic>>(RestrictionsMethodNames.getRestrictedApps);
    if (result == null) return [];
    return result.cast<String>();
  }
}

