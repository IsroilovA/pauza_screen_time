# Restrict / block apps

This guide covers the app restriction API (`AppRestrictionManager`) and how to configure the blocking “shield”.

## How restrictions work

### Android

- You provide **package names** (example: `com.whatsapp`).
- The plugin uses an AccessibilityService to detect when the restricted app is opened.
- The plugin shows an overlay “shield” on top of the app (requires overlay permission).

### iOS

- You provide **base64 `ApplicationToken` strings** (opaque).
- Tokens come from the iOS picker: `InstalledAppsManager.selectIOSApps()`.
- iOS enforces restrictions via `ManagedSettingsStore.shield.applications`.

## 1) Configure the shield UI

Call `configureShield()` before restricting apps.

```dart
final restrictions = AppRestrictionManager();

await restrictions.configureShield(const ShieldConfiguration(
  title: 'Restricted',
  subtitle: 'Ask a parent for more time.',
  // iOS-only, recommended when using extensions:
  appGroupId: 'group.com.yourcompany.yourapp',
  // Optional:
  backgroundBlurStyle: BackgroundBlurStyle.regular,
  primaryButtonLabel: 'OK',
));
```

### Why App Groups matter on iOS

On iOS, `configureShield()` stores the configuration in **App Group UserDefaults** under the key `shieldConfiguration`.

If the App Group is not configured correctly, iOS returns `APP_GROUP_ERROR`.

See [iOS setup](ios-setup.md).

## 2) Restrict apps (Android)

```dart
final restrictions = AppRestrictionManager();

await restrictions.restrictApps([
  'com.whatsapp',
  'com.instagram.android',
]);
```

To add/remove one at a time:

```dart
await restrictions.restrictApp('com.whatsapp');
await restrictions.unrestrictApp('com.whatsapp');
```

## 3) Restrict apps (iOS)

### Step A: request authorization

```dart
final permissions = PermissionManager();
await permissions.requestIOSPermission(IOSPermission.familyControls);
```

### Step B: pick apps (tokens)

```dart
final installedApps = InstalledAppsManager();
final picked = await installedApps.selectIOSApps();

final tokens = picked.map((a) => a.applicationToken).toList();
```

### Step C: apply restrictions using tokens

```dart
final restrictions = AppRestrictionManager();
await restrictions.restrictApps(tokens);
```

## 4) Query current restrictions

```dart
final restrictions = AppRestrictionManager();

final current = await restrictions.getRestrictedApps();
final isBlocked = await restrictions.isAppRestricted(current.first);
```

## Verification checklist

- **Android**:
  - Usage Access enabled (recommended for usage stats)
  - Accessibility enabled (required for blocking triggers)
  - Overlay allowed (required for shield UI)
  - Restrict an app you can easily launch to test
- **iOS**:
  - iOS 16+
  - Screen Time authorization approved
  - Tokens come from `selectIOSApps()` (don’t invent them)

## Next

- [Installed apps](installed-apps.md)
- [Permissions](permissions.md)
- [Troubleshooting](troubleshooting.md)

