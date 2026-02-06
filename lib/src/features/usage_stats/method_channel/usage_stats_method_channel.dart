import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:pauza_screen_time/src/core/background_channel_runner.dart';
import 'package:pauza_screen_time/src/features/usage_stats/usage_stats_platform.dart';
import 'package:pauza_screen_time/src/features/usage_stats/method_channel/channel_name.dart';
import 'package:pauza_screen_time/src/features/usage_stats/method_channel/method_names.dart';

/// Method-channel implementation for the Usage Stats feature.
///
/// Note: on iOS this feature is intentionally unsupported at the channel level.
/// Consumers should use the `UsageReportView` platform view instead.
class UsageStatsMethodChannel extends UsageStatsPlatform {
  @visibleForTesting
  final MethodChannel channel;

  UsageStatsMethodChannel({
    MethodChannel? channel,
  }) : channel = channel ?? const MethodChannel(usageStatsChannelName);

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
      channel.name,
      UsageStatsMethodNames.queryUsageStats,
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
  }) {
    if (Platform.isIOS) {
      throw UnsupportedError(
        'queryAppUsageStats() is only supported on Android. '
        'On iOS, use DeviceActivityReport platform view for usage statistics.',
      );
    }

    return BackgroundChannelRunner.invokeMethod<Map<dynamic, dynamic>?>(
      channel.name,
      UsageStatsMethodNames.queryAppUsageStats,
      arguments: {
        'packageId': packageId,
        'startTimeMs': startTimeMs,
        'endTimeMs': endTimeMs,
        'includeIcons': includeIcons,
      },
    );
  }
}

