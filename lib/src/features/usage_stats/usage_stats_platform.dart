import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// Platform interface for usage statistics functionality.
abstract class UsageStatsPlatform extends PlatformInterface {
  UsageStatsPlatform() : super(token: _token);

  static final Object _token = Object();

  /// Queries usage statistics for all apps within the specified time range.
  ///
  /// **Android only** - Returns a list of maps containing usage data.
  /// **iOS** - Not supported; use platform view for usage reports.
  Future<List<Map<dynamic, dynamic>>> queryUsageStats({
    required int startTimeMs,
    required int endTimeMs,
    bool includeIcons = true,
  }) {
    throw UnimplementedError('queryUsageStats() has not been implemented.');
  }

  /// Queries usage statistics for a specific app.
  ///
  /// **Android only** - Returns a map containing usage data, or null if app not found.
  /// **iOS** - Not supported; use platform view for usage reports.
  Future<Map<dynamic, dynamic>?> queryAppUsageStats({
    required String packageId,
    required int startTimeMs,
    required int endTimeMs,
    bool includeIcons = true,
  }) {
    throw UnimplementedError('queryAppUsageStats() has not been implemented.');
  }
}
