# Troubleshooting

This page lists common setup issues and how to fix them.

## Android

### Blocking doesn’t show when I open a restricted app

**Likely cause**: Accessibility service is not enabled.

**Fix**:
- Open **Settings → Accessibility**
- Enable your app’s accessibility service

**Verify**:
- Restrict a well-known app (e.g. a browser) and open it — the overlay should appear within ~500ms.

### Blocking triggers, but shield overlay is not visible

**Likely cause**: Overlay permission is missing.

**Fix**:
- Open **Settings → Apps → Special app access → Display over other apps**
- Allow your app

### Usage stats are empty

**Likely cause**: Usage Access is not granted.

**Fix**:
- Open **Settings → Usage access**
- Allow your app

## iOS

### `requestIOSPermission(...)` returns false

**Likely causes**:
- Screen Time is disabled on the device
- user tapped “Don’t Allow”
- device is not iOS 16+

**Fix**:
- **Settings → Screen Time → Turn On Screen Time**
- Re-run and request authorization again

### `UsageReportView` shows nothing / fails to render

**Likely cause**: missing **Device Activity Report extension** target.

**Fix**:
- Follow [iOS setup](ios-setup.md) step “Device Activity Report extension”
- Ensure your extension supports the same `reportContext` you pass from Dart (for example `daily`)

### iOS error `APP_GROUP_ERROR` after calling `configureShield()`

**What it means**:

The plugin tried to store shield configuration into the resolved App Group, but `UserDefaults(suiteName: groupId)` returned `nil`.

**Fix**:
- Add **App Groups** capability to:
  - Runner target
  - Shield Configuration extension target (if you use it)
- Ensure both use the same app group identifier
- Add `Info.plist` key `AppGroupIdentifier` or pass `ShieldConfiguration(appGroupId: ...)`

### iOS error `INVALID_TOKEN`

**What it means**:

The token you passed to restrictions could not be decoded as an iOS `ApplicationToken`.

**Fix**:
- Only use tokens returned from `InstalledAppsManager.selectIOSApps()`
- Don’t trim/alter the base64 string when storing it

