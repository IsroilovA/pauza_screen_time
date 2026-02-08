import 'package:flutter_test/flutter_test.dart';
import 'package:pauza_screen_time/src/features/usage_stats/model/app_usage_stats.dart';

void main() {
  test('UsageStats parses new timestamp schema fields', () {
    final stats = UsageStats.fromMap(const {
      'packageId': 'com.example.app',
      'appName': 'Example',
      'totalDurationMs': 120000,
      'totalLaunchCount': 3,
      'bucketStartMs': 1000,
      'bucketEndMs': 2000,
      'lastTimeUsedMs': 1500,
      'lastTimeVisibleMs': 1800,
    });

    expect(stats.appInfo.packageId, 'com.example.app');
    expect(stats.bucketStart?.millisecondsSinceEpoch, 1000);
    expect(stats.bucketEnd?.millisecondsSinceEpoch, 2000);
    expect(stats.lastTimeUsed?.millisecondsSinceEpoch, 1500);
    expect(stats.lastTimeVisible?.millisecondsSinceEpoch, 1800);
    expect(stats.toMap()['bucketStartMs'], 1000);
    expect(stats.toMap()['bucketEndMs'], 2000);
    expect(stats.toMap()['lastTimeUsedMs'], 1500);
  });

  test('UsageStats keeps legacy timestamp key fallback', () {
    final stats = UsageStats.fromMap(const {
      'packageId': 'com.example.legacy',
      'appName': 'Legacy',
      'totalDurationMs': 90000,
      'totalLaunchCount': 1,
      'firstTimeStampMs': 3000,
      'lastTimeStampMs': 4000,
    });

    expect(stats.bucketStart?.millisecondsSinceEpoch, 3000);
    expect(stats.bucketEnd?.millisecondsSinceEpoch, 4000);
    expect(stats.lastTimeUsed, isNull);
  });
}
