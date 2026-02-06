# Usage stats

This feature is platform-specific.

## Android: usage stats as data

### Why permissions matter

Android requires **Usage Access** (Settings permission) to read usage statistics.

See:
- [Android setup](android-setup.md) (Usage Access)
- [Permissions](permissions.md)

### Read usage stats for a time range

```dart
final usage = UsageStatsManager();

final now = DateTime.now();
final stats = await usage.getUsageStats(
  startDate: now.subtract(const Duration(days: 7)),
  endDate: now,
  includeIcons: true,
);
```

### Read usage stats for one app

```dart
final usage = UsageStatsManager();

final now = DateTime.now();
final app = await usage.getAppUsageStats(
  packageId: 'com.whatsapp',
  startDate: now.subtract(const Duration(days: 7)),
  endDate: now,
);
```

## iOS: usage stats as UI (`UsageReportView`)

### Important limitation

On iOS, Apple does **not** let you read Screen Time usage stats as data. The plugin exposes a native UI report you embed in Flutter:

- Widget: `UsageReportView` / `IOSUsageReportView`
- Native view type: `pauza_screen_time/usage_report`

### Setup requirement

You must create a **Device Activity Report extension** target in the host iOS app.

See [iOS setup](ios-setup.md).

### Example: embed a report

```dart
IOSUsageReportView(
  reportContext: 'daily',
  segment: IOSUsageReportSegment.daily,
  startDate: DateTime.now().subtract(const Duration(days: 7)),
  endDate: DateTime.now(),
  fallback: SizedBox.shrink(),
)
```

### Choosing `reportContext`

The plugin passes your string directly to:

```swift
DeviceActivityReport.Context(reportContextId)
```

Your report extension must support the same context identifiers.

