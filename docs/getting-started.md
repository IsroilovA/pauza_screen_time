# Getting started

This guide shows the recommended **end-to-end flow** for both platforms and points you to the platform setup guides you must complete first.

## 0) Install

Add the dependency:

```bash
flutter pub add pauza_screen_time
```

Import the library:

```dart
import 'package:pauza_screen_time/pauza_screen_time.dart';
```

## 1) Do platform setup first

- **Android**: follow [Android setup](android-setup.md) (Usage Access + Accessibility + Overlay).
- **iOS**: follow [iOS setup](ios-setup.md) (Screen Time authorization + App Groups + required extensions).

If you skip these, calls may succeed but features won’t work (for example: blocking won’t trigger if the accessibility service is not enabled).

## 2) Instantiate managers

```dart
final core = CoreManager();
final permissions = PermissionManager();
final installedApps = InstalledAppsManager();
final restrictions = AppRestrictionManager();
final usage = UsageStatsManager();
```

## 3) Common flows

### Android flow (recommended)

1) Request/enable required permissions (opens Settings screens):

```dart
final permissions = PermissionManager();

await permissions.requestAndroidPermission(AndroidPermission.usageStats);
await permissions.requestAndroidPermission(AndroidPermission.accessibility);
await permissions.requestAndroidPermission(AndroidPermission.overlay);
```

2) Pick apps to restrict (package names) and apply restrictions:

```dart
final installedApps = InstalledAppsManager();
final restrictions = AppRestrictionManager();

final apps = await installedApps.getAndroidInstalledApps(includeSystemApps: false);
final packageIdsToBlock = apps.take(3).map((a) => a.packageId).toList();

await restrictions.configureShield(const ShieldConfiguration(
  title: 'Time for a break',
  subtitle: 'This app is blocked right now.',
));

await restrictions.restrictApps(packageIdsToBlock);
```

3) Read usage stats as data (Android only):

```dart
final usage = UsageStatsManager();

final now = DateTime.now();
final stats = await usage.getUsageStats(
  startDate: now.subtract(const Duration(days: 7)),
  endDate: now,
);
```

### iOS flow (recommended)

1) Request Screen Time authorization (system dialog):

```dart
final permissions = PermissionManager();
final granted = await permissions.requestIOSPermission(IOSPermission.familyControls);
if (!granted) {
  // Explain to the user how to enable Screen Time permissions in Settings.
  return;
}
```

2) Pick apps (returns opaque tokens) and restrict them:

```dart
final installedApps = InstalledAppsManager();
final restrictions = AppRestrictionManager();

final picked = await installedApps.selectIOSApps();
final tokens = picked.map((a) => a.applicationToken).toList();

await restrictions.configureShield(const ShieldConfiguration(
  // Optional but recommended when using extensions.
  // Also see docs/ios-setup.md (Info.plist key AppGroupIdentifier).
  appGroupId: 'group.com.yourcompany.yourapp',
  title: 'Restricted',
  subtitle: 'Ask a parent for more time.',
));

await restrictions.restrictApps(tokens);
```

3) Show usage reports as UI (iOS only):

```dart
IOSUsageReportView(
  reportContext: 'daily',
  startDate: DateTime.now().subtract(const Duration(days: 7)),
  endDate: DateTime.now(),
)
```

This requires the **Device Activity Report extension** in the host iOS app. See [iOS setup](ios-setup.md).

## Next

- [Permissions](permissions.md)
- [Restrict / block apps](restrict-apps.md)
- [Installed apps](installed-apps.md)
- [Usage stats](usage-stats.md)
- [Troubleshooting](troubleshooting.md)

