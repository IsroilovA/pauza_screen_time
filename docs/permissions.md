# Permissions

This plugin exposes a typed permission API via `PermissionManager`.

## Concepts

- On **Android**, most features require the user to enable special settings screens:
  - Usage Access (usage stats)
  - Accessibility service (blocking trigger)
- On **iOS**, Screen Time features require Family Controls authorization.

## Android permissions

### What to request

These are represented by `AndroidPermission`:
- `AndroidPermission.usageStats`: Usage Access (Settings → Usage access)
- `AndroidPermission.accessibility`: Accessibility service (Settings → Accessibility)
- `AndroidPermission.queryAllPackages`: install-time manifest capability (Android 11+). **This is not requestable at runtime.**

### Example: request the key permissions

```dart
final permissions = PermissionManager();

await permissions.requestAndroidPermission(AndroidPermission.usageStats);
await permissions.requestAndroidPermission(AndroidPermission.accessibility);
```

### Example: check missing permissions

```dart
final permissions = PermissionManager();

final missing = await permissions.getMissingAndroidPermissions([
  AndroidPermission.usageStats,
  AndroidPermission.accessibility,
]);
```

## iOS permissions

### What to request

These are represented by `IOSPermission`:
- `IOSPermission.familyControls`: required for restrictions + picker
- `IOSPermission.screenTime`: maps to the same underlying authorization

### Example: request Screen Time authorization

```dart
final permissions = PermissionManager();
final granted = await permissions.requestIOSPermission(IOSPermission.familyControls);
```

### Example: check status

```dart
final permissions = PermissionManager();
final status = await permissions.checkIOSPermission(IOSPermission.familyControls);
if (!status.isGranted) {
  // Show UI explaining how to enable Screen Time access.
}
```

## Convenience helper

If you want an “ask for everything” helper, use `PermissionHelper`:

```dart
final helper = PermissionHelper(PermissionManager());
await helper.requestAllRequiredPermissions();
```

### Note about Android `queryAllPackages`

On Android, `QUERY_ALL_PACKAGES` is a manifest-level capability and cannot be granted via a runtime prompt. If you include `AndroidPermission.queryAllPackages` in a “request all” flow, the request will return `false` for that item even though other permissions may be granted.

## Platform setup guides

- [Android setup](android-setup.md)
- [iOS setup](ios-setup.md)

