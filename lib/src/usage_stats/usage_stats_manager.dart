import 'dart:io' show Platform;

import 'package:pauza_screen_time/pauza_screen_time.dart';

/// Manager for app usage statistics.
///
/// This class provides core APIs to query usage statistics from the platform.
/// Users should implement their own filtering, sorting, and analytics as needed.
///
/// **Platform Support:**
/// - **Android**: Full support via UsageStatsManager API
/// - **iOS**: Not supported (use DeviceActivityReport platform view instead)
class UsageStatsManager {
  final UsageStatsPlatform _platform;

  UsageStatsManager(this._platform);

  // ============================================================
  // Usage Stats Queries (Android Only)
  // ============================================================

  /// Returns usage statistics for all apps within the specified time range.
  ///
  /// **Android only** - This method is not supported on iOS.
  ///
  /// [startDate] - Start of the time range.
  /// [endDate] - End of the time range.
  /// [includeIcons] - Whether to include app icons (default: true).
  ///
  /// Throws [UnsupportedError] if called on iOS.
  ///
  /// Example:
  /// ```dart
  /// if (Platform.isAndroid) {
  ///   final stats = await manager.getUsageStats(
  ///     startDate: DateTime.now().subtract(Duration(days: 7)),
  ///     endDate: DateTime.now(),
  ///   );
  /// }
  /// ```
  Future<List<UsageStats>> getUsageStats({
    required DateTime startDate,
    required DateTime endDate,
    bool includeIcons = true,
  }) async {
    if (!Platform.isAndroid) {
      throw UnsupportedError(
        'getUsageStats() is only supported on Android. '
        'On iOS, use DeviceActivityReport platform view for usage statistics.',
      );
    }

    final result = await _platform.queryUsageStats(
      startTimeMs: startDate.millisecondsSinceEpoch,
      endTimeMs: endDate.millisecondsSinceEpoch,
      includeIcons: includeIcons,
    );

    return result.map((item) => UsageStats.fromMap(Map<String, dynamic>.from(item))).toList();
  }

  /// Returns usage statistics for a specific app.
  ///
  /// **Android only** - This method is not supported on iOS.
  ///
  /// [packageId] - Package identifier of the app.
  /// [startDate] - Start of the time range.
  /// [endDate] - End of the time range.
  /// [includeIcons] - Whether to include app icons (default: true).
  ///
  /// Throws [UnsupportedError] if called on iOS.
  Future<UsageStats?> getAppUsageStats({
    required String packageId,
    required DateTime startDate,
    required DateTime endDate,
    bool includeIcons = true,
  }) async {
    if (!Platform.isAndroid) {
      throw UnsupportedError(
        'getAppUsageStats() is only supported on Android. '
        'On iOS, use DeviceActivityReport platform view for usage statistics.',
      );
    }

    final result = await _platform.queryAppUsageStats(
      packageId: packageId,
      startTimeMs: startDate.millisecondsSinceEpoch,
      endTimeMs: endDate.millisecondsSinceEpoch,
      includeIcons: includeIcons,
    );

    if (result == null) return null;
    return UsageStats.fromMap(Map<String, dynamic>.from(result));
  }
}
