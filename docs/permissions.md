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

`requestAndroidPermission(...)` opens the relevant Settings screen and returns when the intent is dispatched. It does not confirm granted status; call `checkAndroidPermission(...)` after the user returns.

Typed error handling:

```dart
try {
  await permissions.requestAndroidPermission(AndroidPermission.accessibility);
} on PauzaError catch (error) {
  // Inspect error.code and error.details.
}
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

Typed error handling:

```dart
try {
  final granted = await permissions.requestIOSPermission(
    IOSPermission.familyControls,
  );
} on PauzaError catch (error) {
  // Handle typed plugin errors.
}
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

On Android, this opens only the first missing runtime prerequisite (`usageStats`, then `accessibility`) so your app can guide the user one step at a time.

### Note about Android `queryAllPackages`

On Android, `QUERY_ALL_PACKAGES` is a manifest-level capability and cannot be granted via a runtime prompt. Treat it as an install-time/policy concern, not part of runtime request flows.

## Platform setup guides

- [Android setup](android-setup.md)
- [iOS setup](ios-setup.md)
