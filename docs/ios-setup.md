# iOS setup

iOS support uses Apple’s **Screen Time** APIs:
- `FamilyControls` for authorization and app selection (picker)
- `ManagedSettings` for enforcing app restrictions
- `DeviceActivity` for rendering usage reports

Because of Apple privacy rules, iOS has important constraints:
- You cannot enumerate installed apps programmatically.
- You cannot read usage stats as data; you can only **render** them as a native report.

## Requirements

- iOS **16.0+** (this plugin requests individual authorization via `AuthorizationCenter.requestAuthorization(for: .individual)`).

## 1) Enable Screen Time on the device (developer sanity check)

### Why this is needed

If Screen Time is disabled system-wide, the user cannot approve Family Controls authorization.

### How to verify

On the test device: **Settings → Screen Time → Turn On Screen Time**.

## 2) Add App Groups (recommended; required for shield configuration sharing)

### Why this is needed

The plugin can store shield configuration in an **App Group** so it’s accessible to app extensions (for example, a Shield Configuration extension).

On native iOS, the plugin resolves the App Group identifier in this order:
1) `ShieldConfiguration(appGroupId: ...)` (Dart, optional)
2) `Info.plist` key `AppGroupIdentifier`
3) fallback to `group.<bundleId>`

### Xcode steps

1) Open `ios/Runner.xcworkspace` in Xcode
2) Select **Runner** target
3) Go to **Signing & Capabilities**
4) Click **+ Capability** → add **App Groups**
5) Add an app group, e.g. `group.com.yourcompany.yourapp`

### Add the `Info.plist` key (recommended)

In your app `Info.plist`, add:
- Key: `AppGroupIdentifier`
- Value: `group.com.yourcompany.yourapp`

### How to verify

- When you call `configureShield(...)` with `appGroupId`, you should not see iOS `INTERNAL_FAILURE`.
- If you do see `INTERNAL_FAILURE` with App Group diagnostics, your App Group is missing or not enabled for the running target.

## 3) Request Screen Time authorization

### Why this is needed

Without authorization, iOS will not allow app restriction APIs to operate.

### Dart code

```dart
final permissions = PermissionManager();
final granted = await permissions.requestIOSPermission(IOSPermission.familyControls);
```

### How to verify

- The system dialog appears.
- After approval, `checkIOSPermission(IOSPermission.familyControls)` returns `PermissionStatus.granted`.

## 4) Enable reliable pause auto-resume (Device Activity Monitor extension)

### Why this is needed

`pauseEnforcement(Duration)` is implemented on iOS by clearing managed shields and storing pause state in the App Group.

For **reliable** auto-resume when the host app is backgrounded/terminated, you also need a **Device Activity Monitor Extension** that can re-apply stored restrictions at pause end.

Without this extension, restrictions still resume when plugin code runs again, but timing is best-effort.

### Xcode steps (high level)

1) In Xcode: **File → New → Target**
2) Choose **Device Activity Monitor Extension**
3) Enable **App Groups** capability for the extension target (same group ID as Runner)
4) In the extension implementation, read the stored desired token list + pause state from App Group defaults and re-apply restrictions when pause expires

## 5) Create the Shield Configuration extension (optional but recommended)

### Why this is needed

If you want a custom “shield” UI (the system screen shown when an app is restricted), iOS requires a **Shield Configuration Extension** target.

This plugin contains a ready-to-use data source implementation (`ShieldConfigurationExtension`), but **extensions live in the host app** — you typically copy/adapt this file into your extension target.

### Xcode steps (high level)

1) In Xcode: **File → New → Target**
2) Choose **Shield Configuration Extension**
3) Enable **App Groups** capability for the extension target too (same group ID)
4) Add a Swift file to the extension target implementing:
   - `ShieldConfigurationDataSource`
   - reads config from the app group defaults key `shieldConfiguration`

### Minimal Swift example

```swift
import ManagedSettingsUI
import ManagedSettings
import UIKit

@available(iOSApplicationExtension 16.0, *)
final class ShieldConfigurationExtension: ShieldConfigurationDataSource {
  override func configuration(shielding application: Application) -> ShieldConfiguration {
    // Load your stored payload from App Group UserDefaults and map it.
    // See plugin source: ios/Classes/AppRestriction/ShieldConfigurationExtension.swift
    return ShieldConfiguration(
      title: ShieldConfiguration.Label(text: "Restricted", color: .white),
      subtitle: ShieldConfiguration.Label(text: "Ask for more time.", color: .lightGray)
    )
  }
}
```

## 6) Create the Device Activity Report extension (required for `UsageReportView`)

### Why this is needed

`UsageReportView` embeds a native `DeviceActivityReport` which only works if your app has a **Device Activity Report extension** target.

The Dart widget passes:
- `reportContext` (string, e.g. `daily`)
- `segment` (`daily` or `hourly`)
- `startTimeMs` / `endTimeMs`

The iOS side turns `reportContext` into `DeviceActivityReport.Context(reportContextId)`.

### Xcode steps (high level)

1) In Xcode: **File → New → Target**
2) Choose **Device Activity Report Extension**
3) Ensure the extension supports iOS 16+
4) Configure your report to support the contexts you will pass from Dart (for example `daily`)

### How to verify

- Build and run on a real device
- Render:

```dart
IOSUsageReportView(
  reportContext: 'daily',
  startDate: DateTime.now().subtract(const Duration(days: 1)),
  endDate: DateTime.now(),
)
```

If the extension is missing, the view will not render correctly.

## Next

- [Restrict / block apps](restrict-apps.md)
- [Usage stats](usage-stats.md)
- [Troubleshooting](troubleshooting.md)
