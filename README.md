# pauza_screen_time

Flutter plugin for **app usage monitoring**, **app restriction / blocking**, and **parental control** experiences.

This package provides a single Dart API with platform-specific implementations:
- **Android**: usage stats via `UsageStatsManager`, app blocking via **AccessibilityService** + **overlay shield**
- **iOS**: app blocking via **Screen Time** (FamilyControls / ManagedSettings), usage reports via a native **DeviceActivityReport** platform view

## Platform support

| Feature | Android | iOS |
|---|---:|---:|
| Permissions helpers | ✅ | ✅ (iOS 16+) |
| Installed apps | ✅ enumerate | ✅ picker tokens only |
| Restrict / block apps | ✅ (Accessibility + overlay) | ✅ (Screen Time, iOS 16+) |
| Restriction session snapshot | ✅ | ✅ |
| Pause enforcement API | ✅ | ✅ (reliable resume requires monitor extension) |
| Usage stats as data (`UsageStatsManager`) | ✅ | ❌ (throws `UnsupportedError`) |
| Usage stats as UI (`UsageReportView`) | ❌ | ✅ (iOS 16+, requires report extension) |

## Important limitations (read this first)

- **iOS app enumeration is not available**. You must use the iOS picker and store opaque tokens.
- **iOS usage stats cannot be read programmatically**. Apple only allows rendering usage via `DeviceActivityReport` UI.
- **Android blocking requires user-enabled system settings** (Usage Access, Accessibility).
- **iOS pause auto-resume reliability requires a Device Activity Monitor extension** in the host app.

## Installation

Add the dependency:

```bash
flutter pub add pauza_screen_time
```

Import it:

```dart
import 'package:pauza_screen_time/pauza_screen_time.dart';
```

## Quick start (minimal)

```dart
import 'package:pauza_screen_time/pauza_screen_time.dart';

final permissions = PermissionManager();
final installedApps = InstalledAppsManager();
final restrictions = AppRestrictionManager();

// Android: request required permissions and enable services in Settings.
// iOS: request Screen Time authorization.
//
// Then:
// - Android: restrict by package names, e.g. "com.whatsapp"
// - iOS: restrict by base64 ApplicationToken strings from selectIOSApps()

// Pause / session APIs:
await restrictions.pauseEnforcement(const Duration(minutes: 5));
await restrictions.resumeEnforcement();
final isActiveNow = await restrictions.isRestrictionSessionActiveNow();
final isConfigured = await restrictions.isRestrictionSessionConfigured();
final session = await restrictions.getRestrictionSession();
```

## Documentation

Start here:
- [Getting started](docs/getting-started.md)

Platform setup:
- [Android setup](docs/android-setup.md)
- [iOS setup](docs/ios-setup.md)

Feature guides:
- [Permissions](docs/permissions.md)
- [Restrict / block apps](docs/restrict-apps.md)
- [Installed apps](docs/installed-apps.md)
- [Usage stats](docs/usage-stats.md)

Help:
- [Troubleshooting](docs/troubleshooting.md)
