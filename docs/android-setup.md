# Android setup

Android support uses:
- **UsageStatsManager** for usage statistics data
- **AccessibilityService** to detect when a restricted app is opened
- **Overlay permission** to draw the blocking shield over other apps

This means your users must enable several system settings manually.

## Requirements

- Android 5.0+ (API 21+)

## 1) What the plugin already declares (manifest merging)

This plugin includes its own Android manifest at `android/src/main/AndroidManifest.xml` inside the plugin. Flutter/Gradle will **merge** it into your app when you add the dependency.

It declares:
- `android.permission.PACKAGE_USAGE_STATS` (Usage Access)
- `android.permission.SYSTEM_ALERT_WINDOW` (Overlay)
- `android.permission.QUERY_ALL_PACKAGES` (Android 11+ app enumeration)
- Accessibility service `com.example.pauza_screen_time.app_restriction.AppMonitoringService`

### When you should edit your app manifest

Usually you **don’t need to** add anything to your app manifest if merging works correctly.

However, you *may* need to adjust your app if:
- you use a very restrictive manifest merger setup
- you want to add your own explanation UI / deep links
- Play Console policy requires changes related to `QUERY_ALL_PACKAGES`

## 2) Enable Usage Access (required for usage stats)

### Why this is needed

Android treats usage stats access as a special permission controlled in Settings. Without it, `UsageStatsManager.getUsageStats()` will return empty results or throw on the native side.

### How to request / open Settings

```dart
final permissions = PermissionManager();
await permissions.requestAndroidPermission(AndroidPermission.usageStats);
```

### How to verify

1) Open **Settings** → **Security & privacy** (or similar) → **Usage access**
2) Find your app and ensure it is **Allowed**

## 3) Enable Accessibility service (required for blocking)

### Why this is needed

The plugin uses an `AccessibilityService` to detect foreground app changes. Without it, restrictions can be set but **nothing will trigger** when the user opens a blocked app.

### How to request / open Settings

```dart
final permissions = PermissionManager();
await permissions.requestAndroidPermission(AndroidPermission.accessibility);
```

### How to verify

1) Open **Settings** → **Accessibility**
2) Find your app’s service and enable it
3) Re-open your app and try launching a restricted app — the shield should appear

## 4) Enable “Display over other apps” (required for the shield overlay)

### Why this is needed

The blocking UI is drawn as an overlay window. Without overlay permission, the service can detect restricted apps but it cannot show the shield.

### How to request / open Settings

```dart
final permissions = PermissionManager();
await permissions.requestAndroidPermission(AndroidPermission.overlay);
```

### How to verify

1) Open **Settings** → **Apps** → **Special app access** → **Display over other apps**
2) Allow your app

## 5) Notes about `QUERY_ALL_PACKAGES`

### What it’s for

`InstalledAppsManager.getAndroidInstalledApps()` enumerates installed apps. On Android 11+ this may require `android.permission.QUERY_ALL_PACKAGES`.

### Important Play policy note

Google Play restricts use of `QUERY_ALL_PACKAGES`. If you don’t qualify, you may need to remove this capability or limit queries via `<queries>` instead.

## Troubleshooting

If blocking doesn’t work:
- Confirm **Accessibility** is enabled (step 3)
- Confirm **Overlay** is allowed (step 4)
- Confirm you called `AppRestrictionManager.restrictApps()` with valid package names

See [Troubleshooting](troubleshooting.md) for more.

