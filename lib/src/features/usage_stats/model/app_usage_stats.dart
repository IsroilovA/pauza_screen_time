import 'package:flutter/foundation.dart';

import 'package:pauza_screen_time/src/features/installed_apps/model/app_info.dart';

/// Usage statistics for an application over a time period.
///
/// This model captures all data available from Android's UsageStats API,
/// including app metadata (name, icon), usage duration, launch counts,
/// and various timestamps that define the statistics bucket and visibility.
@immutable
class UsageStats {
  /// Information about the application (package name, label, icon).
  final AndroidAppInfo appInfo;

  /// Total time the app was in the foreground.
  final Duration totalDuration;

  /// Total number of times the app was launched.
  final int totalLaunchCount;

  /// Timestamp when the app was first used in the queried period.
  final DateTime? firstUsed;

  /// Timestamp when the app was last used in the queried period.
  final DateTime? lastUsed;

  /// Start time of the statistics bucket (Android only).
  /// Represents when this UsageStats measurement period began.
  final DateTime? firstTimeStamp;

  /// End time of the statistics bucket (Android only).
  /// Represents when this UsageStats measurement period ended.
  final DateTime? lastTimeStamp;

  /// Timestamp when app was last visible (Android Q+ only).
  /// This tracks when the app was last visible, even if not in foreground/focused.
  final DateTime? lastTimeVisible;

  const UsageStats({
    required this.appInfo,
    required this.totalDuration,
    required this.totalLaunchCount,
    this.firstUsed,
    this.lastUsed,
    this.firstTimeStamp,
    this.lastTimeStamp,
    this.lastTimeVisible,
  });

  /// Creates a UsageStats from a map (used for platform channel deserialization).
  factory UsageStats.fromMap(Map<String, dynamic> map) {
    return UsageStats(
      appInfo: AndroidAppInfo(
        packageId: map['packageId'] as String,
        name: map['appName'] as String? ?? map['packageId'] as String,
        icon: map['appIcon'] != null ? Uint8List.fromList(List<int>.from(map['appIcon'] as List)) : null,
        category: map['category'] as String?,
        isSystemApp: map['isSystemApp'] as bool? ?? false,
      ),
      totalDuration: Duration(milliseconds: map['totalDurationMs'] as int),
      totalLaunchCount: map['totalLaunchCount'] as int,
      firstUsed:
          map['firstUsedMs'] != null ? DateTime.fromMillisecondsSinceEpoch(map['firstUsedMs'] as int) : null,
      lastUsed: map['lastUsedMs'] != null ? DateTime.fromMillisecondsSinceEpoch(map['lastUsedMs'] as int) : null,
      firstTimeStamp: map['firstTimeStampMs'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['firstTimeStampMs'] as int)
          : null,
      lastTimeStamp: map['lastTimeStampMs'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastTimeStampMs'] as int)
          : null,
      lastTimeVisible: map['lastTimeVisibleMs'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastTimeVisibleMs'] as int)
          : null,
    );
  }

  /// Converts this UsageStats to a map (used for platform channel serialization).
  Map<String, dynamic> toMap() {
    return {
      'packageId': appInfo.packageId,
      'appName': appInfo.name,
      'totalDurationMs': totalDuration.inMilliseconds,
      'totalLaunchCount': totalLaunchCount,
      'firstUsedMs': firstUsed?.millisecondsSinceEpoch,
      'lastUsedMs': lastUsed?.millisecondsSinceEpoch,
      'appIcon': appInfo.icon?.toList(),
      'category': appInfo.category,
      'isSystemApp': appInfo.isSystemApp,
      'firstTimeStampMs': firstTimeStamp?.millisecondsSinceEpoch,
      'lastTimeStampMs': lastTimeStamp?.millisecondsSinceEpoch,
      'lastTimeVisibleMs': lastTimeVisible?.millisecondsSinceEpoch,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UsageStats &&
        other.appInfo == appInfo &&
        other.totalDuration == totalDuration &&
        other.totalLaunchCount == totalLaunchCount;
  }

  @override
  int get hashCode => Object.hash(appInfo, totalDuration, totalLaunchCount);

  @override
  String toString() => 'UsageStats(appInfo: $appInfo, totalDuration: $totalDuration, launches: $totalLaunchCount)';
}

