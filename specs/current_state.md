# Current State vs Specifications (`specs/specifications.md`)

**Repository:** `pauza_screen_time` (Flutter plugin)  
**Scope of this document:** plugin package code + native Android/iOS implementations + `docs/` + `specs/`.  
**Explicitly out of scope (per request):**
- The `example/` app (no analysis; not used for acceptance here).
- **Events & observability** (spec §6.8 is treated as “not needed for now”).
- Android **usage stats granularity** (spec mentions it; per request, we do not require it right now).

**Goal of this document:** For each item in `specs/specifications.md`, state:
1) what is implemented today and how it works,  
2) whether it meets the spec (“accepted”) and if not, why,  
3) whether gaps are fixable/doable (and what would be required).

---

## 0) Executive summary

### What is **implemented** (high level)

- **Dart API & module split**: Feature managers + platform interfaces + method-channel implementations exist for:
  - Permissions (`PermissionManager`)
  - Installed apps (`InstalledAppsManager`)
  - Restrict/block apps (`AppRestrictionManager`)
  - Usage stats (Android data via `UsageStatsManager`, iOS UI via `UsageReportView`)
- **Android**:
  - Installed apps enumeration via `PackageManager`
  - Usage stats aggregates via `UsageStatsManager`
  - App blocking via `AccessibilityService` foreground detection + full-screen overlay “shield”
  - Local persistence of restricted set and pause state in `SharedPreferences`
- **iOS** (iOS 16+):
  - Screen Time authorization request/check via `FamilyControls.AuthorizationCenter`
  - App selection via `FamilyActivityPicker` returning opaque base64 `ApplicationToken` strings
  - App blocking via `ManagedSettingsStore.shield.applications`
  - Usage reporting via embedded native `DeviceActivityReport` platform view (`UsageReportView`)
  - Local persistence of desired restricted tokens + pause state in App Group `UserDefaults`
  - Shield appearance configuration storage for a host **Shield Configuration extension** to consume

### Major spec gaps / non-accepted items

1) **No explicit “start/stop enforcement” session API** (spec §4.2, §6.3):  
   Current design treats “session configured” as “restricted list non-empty” and “active now” as “configured and not paused”. Stopping enforcement requires clearing restrictions (loses configured set).

2) **Scheduling APIs are not implemented** (spec §4.4, §5.5 typo but scheduling section, §6.5, acceptance criteria):  
   No Dart APIs and no native scheduling mechanism exists.

3) **Fail-safe enforcement reporting is not implemented** (spec §8):  
   - Android restrictions can be set even if Accessibility is disabled; no error is surfaced.  
   - iOS restrictions can be set without checking Screen Time authorization; no error is surfaced if the system ignores it.

4) **Android permission request semantics are misleading** (spec §6.1):  
   `requestAndroidPermission(...)` returns whether the Settings screen was opened, not whether permission was actually granted; `PermissionHelper.requestAllRequiredPermissions()` is currently guaranteed to return `false` on Android because it includes `queryAllPackages`.

5) **iOS App Group usage has a correctness risk** (shield config vs restriction state):  
   `configureShield(appGroupId: ...)` stores shield config using that group, but restriction session state storage currently resolves the group independently and does not reliably follow the override. This can break extension sharing unless the host app’s Info.plist/App Group happens to match the plugin’s resolution.

### What looks “accepted” today (given current scope)

- Android installed apps listing with icon/category/system flag is implemented and matches spec §6.2 (Android).
- iOS app selection via system picker returning opaque tokens is implemented and matches spec §6.2 (iOS).
- Android usage stats as aggregated per-app totals over a range is implemented (spec §5.5 / §6.6) with some schema/field naming concerns.
- iOS usage reporting as an embeddable system UI view is implemented (spec §5.6 / §6.7), but still depends on host extensions.
- Pause enforcement exists on both platforms (spec §6.4), but iOS “auto-resume at pause expiry” is **best-effort** without a monitor extension.

---

## 1) Architecture & “how it is done”

### 1.1 Dart-side structure (public API)

Entrypoint exports:
- `lib/pauza_screen_time.dart` exports:
  - `src/core/core.dart`
  - `src/features/permissions/permissions.dart`
  - `src/features/installed_apps/installed_apps.dart`
  - `src/features/restrict_apps/restrict_apps.dart`
  - `src/features/usage_stats/usage_stats.dart`

Managers (what host apps use):
- `PermissionManager` (`lib/src/features/permissions/data/permission_manager.dart`)
- `InstalledAppsManager` (`lib/src/features/installed_apps/data/installed_apps_manager.dart`)
- `AppRestrictionManager` (`lib/src/features/restrict_apps/data/app_restriction_manager.dart`)
- `UsageStatsManager` (`lib/src/features/usage_stats/data/usage_stats_manager.dart`)
- `CoreManager` (`lib/src/core/core_manager.dart`) – currently only `getPlatformVersion()`

Platform abstraction:
- Each feature defines a `PlatformInterface`:
  - `PermissionPlatform`, `InstalledAppsPlatform`, `AppRestrictionPlatform`, `UsageStatsPlatform`
- Default implementations are method-channel based:
  - `PermissionsMethodChannel`, `InstalledAppsMethodChannel`, `RestrictionsMethodChannel`, `UsageStatsMethodChannel`

Cross-platform identifier model:
- `AppIdentifier` is an **opaque wrapper** around `String` (`lib/src/core/app_identifier.dart`):
  - Android uses package name
  - iOS uses base64 `ApplicationToken`

Performance pattern for large payloads:
- `BackgroundChannelRunner` (`lib/src/core/background_channel_runner.dart`) runs selected method-channel calls on a background isolate to avoid blocking the UI isolate during platform message decoding (important for icon byte arrays and big lists).

### 1.2 Android native structure

Registration / channels:
- Main plugin class: `android/src/main/kotlin/.../PauzaScreenTimePlugin.kt`
- Per-feature registrars under `android/src/main/kotlin/.../*/method_channel/*Registrar.kt`
- Method handlers under `.../*/method_channel/*MethodHandler.kt`

Key Android implementations:
- **Permissions**: `permissions/PermissionHandler.kt`
  - Usage Access check via `AppOpsManager(OPSTR_GET_USAGE_STATS)`
  - Accessibility enabled check via `Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES`
  - Settings deep links via `Intent(Settings.ACTION_...)`
- **Installed apps**: `installed_apps/InstalledAppsHandler.kt` + `utils/AppInfoUtils.kt`
  - Enumerates via `PackageManager.getInstalledApplications(...)`
  - Extracts label + PNG icon bytes + category + system app flag
- **Usage stats**: `usage_stats/UsageStatsHandler.kt`
  - Reads `UsageStatsManager.queryUsageStats(INTERVAL_BEST, start, end)`
  - Computes launch counts by scanning `queryEvents(...)` for `ACTIVITY_RESUMED`
- **Blocking**:
  - Foreground detection: `app_restriction/AppMonitoringService.kt` (AccessibilityService)
  - Restricted set persistence: `app_restriction/RestrictionManager.kt` (SharedPreferences JSON payload)
  - Overlay: `app_restriction/ShieldOverlayManager.kt` + compose UI in `app_restriction/overlay/*`
  - Manifest declares:
    - `PACKAGE_USAGE_STATS`, `QUERY_ALL_PACKAGES`
    - the accessibility service (`android/src/main/AndroidManifest.xml`)

### 1.3 iOS native structure

Registration:
- Main plugin: `ios/Classes/PauzaScreenTimePlugin.swift`
  - Registers method channels for Core / Permissions / InstalledApps / Restrictions
  - Registers a platform view factory for usage reports: `UsageReportViewFactory.viewType == "pauza_screen_time/usage_report"`

Key iOS implementations (iOS 16+):
- **Permissions**: `ios/Classes/Permissions/PermissionHandler.swift`
  - `AuthorizationCenter.shared.authorizationStatus` check
  - `requestAuthorization(for: .individual)` request
- **Installed apps (selection)**: `FamilyActivityPickerHandler.swift`
  - Presents `FamilyActivityPicker` via `UIHostingController`
  - Serializes selected `ApplicationToken` via JSONEncoder -> base64 string
- **Blocking / restrictions**:
  - Uses `ManagedSettingsStore().shield.applications` via `ShieldManager.swift`
  - Persists “desired restricted tokens” + “pause until” to App Group defaults via `RestrictionStateStore.swift`
  - Stores shield UI configuration payload via `ShieldConfigurationStore.swift`
  - Contains an example `ShieldConfigurationDataSource` implementation for an extension: `ShieldConfigurationExtension.swift` (host app must create the extension target)
- **Usage reporting UI**:
  - Platform view embeds SwiftUI `DeviceActivityReport` (`UsageReportContainerView.swift`)
  - Date range passed from Flutter (epoch ms) -> `DeviceActivityFilter` daily/hourly segments

---

## 2) Spec-by-spec comparison

> Legend used below:
> - **Done / Accepted**: implemented and matches spec intent
> - **Done / Not accepted**: implemented but deviates (reason + fixability described)
> - **Not done**: not implemented
> - **Out of scope**: excluded by request (events/observability)

### 2.1 Spec §1 Overview (single Flutter-facing API)

**What’s implemented**
- A single Dart package with feature managers and a unified identifier model (`AppIdentifier`).
- Android/iOS platform differences are handled inside managers/method channels.

**Accepted?** Yes for the “single API surface” aspect.

**Notes**
- The “single API” is achieved by grouping into managers rather than a single monolithic class, which is still consistent with spec intent.

### 2.2 Spec §2 Goals

#### Goal: “Reliable, local-first enforcement”

**Android**
- Enforcement relies on Accessibility being enabled:
  - Foreground app changes are detected by `AppMonitoringService` (AccessibilityService).
  - A full-screen overlay shield is shown when a restricted package becomes foreground.
- Restricted set persists in SharedPreferences via `RestrictionManager`, so it survives process restarts.

**iOS**
- Enforcement uses `ManagedSettingsStore` (system-managed restrictions).
- Desired restricted tokens persist in App Group `UserDefaults`, but actual “re-application” is best-effort unless the host app adds extensions for background/termination scenarios.

**Accepted?** **Partially**.
- Android: works when prerequisites are enabled, but is not “fail-safe” and is user-disableable.
- iOS: restrictions can be applied, but pause/resume and re-application semantics depend on host extensions.

**Fixability**
- Add explicit “preflight” checks (permissions/authorization) and surface structured errors when enforcement can’t be applied (see §6.1 / §6.3 gaps below).

#### Goal: “Consistent Dart API without hiding limitations”

**What’s implemented**
- Android-only vs iOS-only methods throw `UnsupportedError` at the Dart layer (`UsageStatsManager` on iOS; Android installed apps on iOS; iOS picker on Android).
- Docs call out iOS limitations.

**Accepted?** Mostly yes.

#### Goal: “Permissions discoverable and actionable”

**What’s implemented**
- Permission status checks exist on both platforms.
- Settings deep links exist:
  - Android: Usage Access, Accessibility, App details
  - iOS: open app Settings page

**Accepted?** **Partially**, because Android “request” is not a true request (it opens Settings) and returns a misleading boolean.

#### Goal: “Offline operation for enforcement and schedules”

**What’s implemented**
- Enforcement is local-first on both platforms.
- Schedules are not implemented.

**Accepted?** Enforcement: yes. Schedules: not done.

#### Goal: “Reliable fixed-time pauses”

**What’s implemented**
- Android pause is time-based and checked at enforcement time (`paused_until_epoch_ms` in SharedPreferences).
- iOS pause stores `pausedUntilEpochMs` in App Group defaults and clears shields during pause.

**Accepted?** **Android: yes. iOS: partially** (auto-resume timing is best-effort without a Device Activity Monitor extension; plugin itself cannot provide a background trigger in-process).

---

## 3) Functional requirements (Spec §6)

### 3.1 §6.1 Permissions & authorization

#### Android

**Implemented**
- `PermissionManager.checkAndroidPermission(...)` -> method channel -> `PermissionHandler.checkPermission(...)`
- Supported keys:
  - `android.usageStats`: checks `AppOpsManager.OPSTR_GET_USAGE_STATS`
  - `android.accessibility`: checks if `AppMonitoringService` is in enabled accessibility services
  - `android.queryAllPackages`: best-effort check whether permission is declared and guarded query succeeds (Android 11+)
- `openAndroidPermissionSettings(...)` deep links to appropriate Settings pages

**Not accepted (behavior)**
- `requestAndroidPermission(...)` returns a boolean that currently means “request intent started”, not “granted”.  
  - Native code uses `startActivityForResult(...)` to open Settings screens.
  - There is no callback channel or re-check to confirm grant.
- `PermissionHelper.requestAllRequiredPermissions()` always includes `AndroidPermission.queryAllPackages`, which is not requestable at runtime; therefore the helper will often return `false` even if the user enabled the relevant settings.

**Fixable?** Yes.
- Change Dart docs + API contract to “opens settings screen” (return `void`) **or**
- Return a richer result type like `{ started: bool, statusAfter: PermissionStatus }` after a re-check when app resumes.
- Update `PermissionHelper` to:
  - exclude `queryAllPackages` from “request” flow (treat it as install-time / policy concern)
  - provide separate “capability declared/available” reporting

#### iOS

**Implemented**
- `AuthorizationCenter.shared.authorizationStatus` mapped to:
  - `granted` / `denied` / `notDetermined`
- Request uses `requestAuthorization(for: .individual)` and returns `bool granted`.
- Settings deep link opens app Settings.

**Accepted?** Yes, within iOS 16+ scope.

**Remaining gap (spec intent)**
- Restrictions methods do not verify authorization before applying (see §6.3). This belongs to a “fail-safe” permission model.

---

### 3.2 §6.2 Installed apps & selection

#### Android: enumerate installed apps

**Implemented**
- Dart: `InstalledAppsManager.getAndroidInstalledApps(...)`
- Native: `InstalledAppsHandler.getInstalledApps(...)` iterates `PackageManager.getInstalledApplications(...)`
- Returned metadata includes:
  - stable identifier: `packageId`
  - display name: `name`
  - icon bytes: `icon` (optional)
  - system app flag: `isSystemApp`
  - category: `category` (Android O+ mapping)

**Accepted?** Yes.

**Important product/policy note (not in spec, but critical)**
- The plugin declares `android.permission.QUERY_ALL_PACKAGES` in its manifest. On Google Play, this is heavily restricted and may require justification or rejection. If the host app cannot qualify, this must be redesigned using `<queries>` or narrower enumeration.

#### iOS: picker tokens

**Implemented**
- Dart: `InstalledAppsManager.selectIOSApps(preSelectedApps: ...)`
- Native: `FamilyActivityPickerHandler.showPicker(...)`
  - Optional “preselected” tokens are decoded and applied before presenting picker.
  - Tokens returned are base64-encoded JSON-encoded `ApplicationToken`.

**Accepted?** Yes.

**Limitations**
- No display metadata is returned to Dart (name/icon). This matches iOS constraints; docs instruct using native `Label(applicationToken)` in SwiftUI if needed.

---

### 3.3 §6.3 Restrict / unblock apps (enforcement)

#### What exists today (Dart API)

`AppRestrictionManager` provides:
- `configureShield(ShieldConfiguration)`
- `restrictApps(List<AppIdentifier>)` (replaces full set)
- `restrictApp(AppIdentifier)` / `unrestrictApp(AppIdentifier)` (incremental)
- `clearAllRestrictions()`
- `getRestrictedApps()` / `isAppRestricted(...)`
- “Session snapshot” helpers:
  - `isRestrictionSessionActiveNow()`
  - `isRestrictionSessionConfigured()`
  - `getRestrictionSession()`
- Pause:
  - `pauseEnforcement(Duration)`
  - `resumeEnforcement()`

#### Android enforcement “how it works”

- Restricted set stored in `SharedPreferences` (`RestrictionManager`).
- Accessibility service (`AppMonitoringService`) listens to foreground/window events:
  - Determines “focused application package” using interactive windows (reduces false positives).
  - If restricted and not paused: shows overlay via `ShieldOverlayManager`.
- Shield overlay:
  - Window type: `TYPE_ACCESSIBILITY_OVERLAY`
  - Compose UI via `ShieldOverlayContent`
  - Button taps currently navigate to **Home** and dismiss overlay.

**Accepted?** **Partially**.
- Blocking works under expected conditions, but there is no “hard” prevention beyond overlay and it is bypassable by disabling Accessibility.
- The spec’s “explicit start/stop session” is not present.

**Key non-accepted spec deviations**
1) **No explicit start/stop enforcement**  
   - Clearing restrictions removes configuration rather than stopping enforcement while preserving a configured set.
2) **Fail-safe behavior is missing**  
   - `setRestrictedApps(...)` succeeds even if Accessibility is disabled; there is no structured error indicating “missing permission / service not enabled”.
3) **Active-state reporting is optimistic**  
   - Android `isRestrictionSessionActiveNow` returns `restrictedApps.isNotEmpty && !isPausedNow` without checking that Accessibility service is enabled/running.

**Fixable?** Yes.
- Add a persisted “enforcementEnabled” boolean, separate from “desired restricted apps”.
- Implement `startEnforcement()` / `stopEnforcement()` on Dart + native:
  - Android: service checks + store flag; `AppMonitoringService` consults it.
  - iOS: apply/clear `ManagedSettingsStore` while keeping desired tokens persisted.
- Update `isRestrictionSessionActiveNow` to incorporate required prerequisites:
  - Android: accessibility enabled
  - iOS: authorization approved

#### iOS enforcement “how it works”

- Desired tokens are stored in App Group defaults (`RestrictionStateStore.desiredRestrictedAppsKey`).
- Applying restrictions:
  - decode tokens -> `Set<ApplicationToken>`
  - set `ManagedSettingsStore().shield.applications = tokens`
- Clearing restrictions sets `shield.applications = nil` (and `webDomains = nil`).
- Pause sets a future epoch ms and clears shields while paused.

**Accepted?** **Partially**.
- Core “restrict these tokens” behavior is correct for iOS 16+.
- However:
  - No explicit start/stop enforcement API exists (same issue as Android).
  - No authorization preflight is performed before applying.
  - Timed pause auto-resume depends on future invocations of plugin code (or a host extension).

---

### 3.4 §6.4 Pause enforcement

#### Android

**Implemented**
- `pauseEnforcement(duration)` stores `paused_until_epoch_ms = now + duration` in SharedPreferences.
- Accessibility service checks `RestrictionManager.isPausedNow()` and does not block during pause.
- Auto-resume happens naturally when the pause time expires (no extra work required) because the service re-checks pause on each foreground event.

**Accepted?** Yes.

**Minor notes**
- If the device is idle and no app switching occurs exactly at pause expiry, the “moment” enforcement resumes is effectively “next relevant event”. This is typically acceptable for Android.

#### iOS

**Implemented**
- Pause stores `pausedUntilEpochMs` in App Group defaults.
- While paused, `applyDesiredRestrictionsIfNeeded()` clears restrictions.
- Resume clears pause state and re-applies desired restrictions.

**Not fully accepted**
- Without a Device Activity Monitor extension (host responsibility), there is no guaranteed background trigger at pause expiry to re-apply restrictions.

**Doable?** Yes, but it is primarily **host-app extension work**, not something the plugin can fully deliver alone.

---

### 3.5 §6.5 Scheduling

**Implemented today:** Not done.
- No Dart scheduling API exists.
- No Android alarms/work scheduling exist.
- No iOS `DeviceActivityMonitor` integration exists (beyond docs mentioning it conceptually).

**Accepted?** No.

**Doable?** Yes, but with meaningful complexity:
- Android:
  - likely `AlarmManager` (exact alarms vs inexact) or `WorkManager` (best-effort) to start/stop enforcement windows,
  - persistence of schedule definitions,
  - careful interaction rules with manual start/stop and pauses.
- iOS:
  - best implemented via `DeviceActivityMonitor` extension which can apply/clear shields on schedule boundaries,
  - needs App Group shared state and extension configuration.

---

### 3.6 §6.6 Usage stats (Android)

**Implemented**
- Dart: `UsageStatsManager.getUsageStats(startDate, endDate, includeIcons)`
- Native: `UsageStatsHandler.queryUsageStats(start, end)`
  - uses `UsageStatsManager.queryUsageStats(INTERVAL_BEST, start, end)`
  - filters out apps with `totalTimeInForeground <= 0`
  - computes `totalLaunchCount` via event scan (`ACTIVITY_RESUMED`)
  - enriches with app label/icon/category/system flag

**Accepted?** **Partially**.
- Meets “aggregated per-app usage totals over a range”.
- Missing from spec minimums / clarity:
  - No explicit “total device screen time” API (caller can sum per-app durations as an approximation).
  - No granularity selection model (per request, not required right now).
  - Time zone and rounding are implicitly “epoch ms / device local time interpretation”; not explicitly modeled.

**Correctness concern (field semantics)**
- Native mapping populates:
  - `firstUsedMs` with `usageStats.firstTimeStamp`
  - `lastUsedMs` with `usageStats.lastTimeStamp`
  - and also separately sets `firstTimeStampMs`/`lastTimeStampMs` to those same values  
  This makes `firstUsed`/`lastUsed` in Dart misleading or duplicate. If consumers rely on “last time used”, this is likely wrong.

**Fixable?** Yes.
- Either:
  - remove/rename `firstUsed/lastUsed` fields (keep only bucket timestamps), **or**
  - map `lastUsedMs` to Android’s `UsageStats.lastTimeUsed` and document the semantics.

---

### 3.7 §6.7 Usage report view (iOS)

**Implemented**
- Dart: `UsageReportView` / `IOSUsageReportView` renders a `UiKitView` with:
  - `viewType: "pauza_screen_time/usage_report"`
  - `creationParams`: `reportContext`, `segment` (daily/hourly), `startTimeMs`, `endTimeMs`
- iOS: `UsageReportContainerView` embeds `DeviceActivityReport(Context, filter)`

**Accepted?** Yes, as a UI embedding mechanism.

**Remaining “spec polish”**
- The spec calls for explicit recoverable “unsupported/unavailable” states.  
  Today:
  - on non-iOS platforms the widget returns `fallback`/empty
  - on iOS < 16 it shows a text message
  - authorization/extension-missing error states are not surfaced as structured Dart results

**Doable?** Yes.
- Expose a small Dart “capability check” method (`isUsageReportSupported`) and/or a callback/error channel.
- Detect common failure modes where possible (though extension absence is not always directly detectable from within the plugin).

---

### 3.8 §6.8 Events & observability

**Status:** Out of scope (per request).

---

### 3.9 §6.9 Error model

**What exists**
- iOS returns `FlutterError` with codes like:
  - `INVALID_ARGUMENT`, `SETTINGS_ERROR`, `VIEW_CONTROLLER_ERROR`, `APP_GROUP_ERROR`, `UNSUPPORTED`, `INVALID_TOKEN`, `UNEXPECTED_ERROR`
  - See `ios/Classes/Core/PluginErrors.swift`
- Android uses `result.error(code, message, details)` with codes like:
  - `INVALID_ARGUMENT`, `NO_ACTIVITY`, `NO_CONTEXT`, `SETTINGS_ERROR`, `GET_APPS_ERROR`, `QUERY_USAGE_STATS_ERROR`, etc.
  - See `android/src/main/kotlin/.../core/PluginErrors.kt`

**Not accepted vs spec intent**
- There is no **single, stable, documented taxonomy** across platforms (codes differ and some states are not represented uniformly).
- Missing key categories from spec intent:
  - “missing permission / authorization” errors for restriction enforcement,
  - “system restricted (MDM/parental)” is not distinguished from denied,
  - no typed Dart error/result wrappers (it is mostly PlatformExceptions).

**Fixable?** Yes.
- Define a Dart-side `PauzaError` model (sealed union) and map platform exceptions into it.
- Ensure both platforms emit consistent `code`s for the same conceptual failures.

---

## 4) Spec §4 Core concepts & contracts

### 4.1 App identifier

**Implemented**
- `AppIdentifier` extension type wraps a string and has `android(...)` / `ios(...)` constructors.
- Installed apps / picker return values feed into this identifier.

**Accepted?** Yes.

### 4.2 Restriction session

**Implemented (current interpretation)**
- “Configured” = restricted set non-empty (`isRestrictionSessionConfigured`)
- “Active now” = configured and not paused (`isRestrictionSessionActiveNow`)
- Session snapshot includes:
  - `isActiveNow`, `isPausedNow`, `pausedUntil`, `restrictedApps`

**Not accepted**
- The spec expects explicit APIs to start/stop enforcement independent of configuration.

**Fixable?** Yes (see §6.3 notes).

### 4.3 Shield experience

**Android**
- Full-screen overlay shield blocks interaction by covering the screen.
- Content is configurable (title/subtitle/colors/blur/icon/button labels).
- Buttons currently perform a fixed action: go Home + dismiss overlay (no host-app deep link support).

**iOS**
- Shield UI is system-controlled; plugin supports storing configuration for a Shield Configuration extension to use.

**Accepted?** Partially.
- Meets “blocks interaction” and “minimal configurable content”.
- Missing optional “open host app/deep link” behavior in Android.

### 4.4 Schedules

**Not implemented.**

---

## 5) Privacy, security, data handling (Spec §7)

**What’s implemented**
- No network transmission code observed in plugin.
- Local persistence:
  - Android: restricted packages + pause epoch stored in SharedPreferences.
  - iOS: desired restricted tokens + pause epoch stored in App Group `UserDefaults`.
  - iOS: shield configuration stored in App Group `UserDefaults` under `shieldConfiguration`.

**Accepted?** Generally yes.

---

## 6) Reliability & performance (Spec §8)

**Performance**
- Background isolate runner for large channel payload decoding exists and is used by Installed Apps and Usage Stats.
- Android native installed apps and usage stats handlers run on `Dispatchers.IO`.

**Reliability gaps vs spec**
- The plugin does not “fail safely” for enforcement:
  - Android restrictions can be configured even if Accessibility is disabled.
  - iOS restrictions can be configured/applied without verifying Screen Time authorization.
- iOS timed pause auto-resume is best-effort without host extension.

**Doable to improve?** Yes.
- Add enforcement “preflight” checks and return clear errors.
- Optionally add a “health check” API returning:
  - current permission/authorization statuses,
  - whether enforcement trigger components are enabled (Android accessibility),
  - whether extensions are expected/required (iOS).

---

## 7) Acceptance criteria checklist (Spec §9)

> This restates the spec’s acceptance list with current status.

- Detect and request required permissions/authorizations  
  - **iOS**: Done / Accepted  
  - **Android**: Done / Not accepted (request semantics + helper bug)
- Select apps to restrict (Android enumerate, iOS picker tokens)  
  - **Done / Accepted**
- Start/stop restrictions and observe state changes via events  
  - **Start/stop**: Not done as a distinct concept (clearing restrictions stops but loses configuration)  
  - **Events**: Out of scope (per request)
- Display a shield when a restricted app is opened  
  - **Android**: Done / Accepted (overlay shield)  
  - **iOS**: Done / Accepted only insofar as iOS shields are system-managed; custom UI requires host extension
- Pause enforcement for bounded duration and observe resume behavior  
  - **Android**: Done / Accepted  
  - **iOS**: Done / Partially accepted (best-effort resume without monitor extension)
- Register schedules that start/stop enforcement locally without network  
  - **Not done**
- Read Android usage aggregates for a date range  
  - **Done / Partially accepted** (schema ok; field semantics and no device-total API)
- Embed and display iOS usage reporting via a Flutter view  
  - **Done / Accepted**, requires host report extension

---

## 8) Concrete issues list (why some items are “not accepted”)

### Issue A — Android permission request returns “started”, not “granted”
- **Where:** `android/.../permissions/PermissionHandler.requestPermission(...)` + `lib/.../PermissionManager.requestAndroidPermission(...)`
- **Impact:** host app can’t rely on return value; spec calls for clear structured results.
- **Fix:** change API contract or implement a re-check / lifecycle callback strategy.

### Issue B — `PermissionHelper.requestAllRequiredPermissions()` is incorrect on Android
- **Where:** `lib/src/features/permissions/data/permission_helper.dart`
- **Impact:** returns `false` due to `queryAllPackages` always being unrequestable.
- **Fix:** remove `queryAllPackages` from the request set; treat it separately.

### Issue C — No explicit “start/stop enforcement”
- **Where:** `AppRestrictionManager` API surface and both native implementations.
- **Impact:** cannot “stop enforcing but keep configured restricted set”.
- **Fix:** add explicit session enable/disable state.

### Issue D — Active-state checks don’t validate prerequisites (“fail safe”)
- **Where:** Android `handleIsRestrictionSessionActiveNow`, iOS `handleIsRestrictionSessionActiveNow`
- **Impact:** UI may show “active” while enforcement is impossible (Accessibility off / authorization missing).
- **Fix:** incorporate permission/authorization checks or return richer state.

### Issue E — iOS App Group override likely not applied consistently
- **Where:** `ios/Classes/AppRestriction/AppGroupStore.swift` + `RestrictionStateStore.swift`
- **Impact:** shield config might be stored in one group while restriction state is stored/read from another.
- **Fix:** make all stores use a single resolved group ID (preferably `AppGroupStore.currentGroupIdentifier` after `configureShield`).

### Issue F — Android usage stats field semantics are confusing/likely wrong
- **Where:** `android/.../usage_stats/UsageStatsHandler.kt`
- **Impact:** `firstUsedMs`/`lastUsedMs` duplicates bucket timestamps; may mislead consumers.
- **Fix:** map to correct native fields or remove/rename.

### Issue G — Version mismatch between `pubspec.yaml` and `ios/pauza_screen_time.podspec`
- **Where:** `pubspec.yaml` (0.0.2) vs `ios/pauza_screen_time.podspec` (0.0.1)
- **Impact:** confusing release/versioning; can break expectations when publishing.
- **Fix:** align versions.

---

## 9) What is not implemented (and doability)

### 9.1 Scheduling (spec §6.5)

**Doable?** Yes, but requires design decisions:
- Data model for schedule windows (days-of-week, start/end local time, enabled).
- Interaction rules with:
  - manual enforcement toggle (which does not exist yet),
  - pause enforcement.
- Platform-specific background execution constraints:
  - Android exact alarms vs inexact work; OEM battery policies.
  - iOS strongly favors extension-based scheduling (`DeviceActivityMonitor`).

### 9.2 Events stream (spec §6.8)

**Out of scope now** (per request), but implementable later via:
- Android: internal event bus from service + method channel event stream.
- iOS: limited; could emit state changes on method invocations, plus extension-driven events via shared storage + polling.

---

## 10) Recommended next steps (if the goal is to meet `specs/specifications.md`)

1) Add explicit restriction session controls:
   - `startEnforcement()` / `stopEnforcement()` (preserve configured restricted set)
   - and update “session snapshot” to include prerequisite status (Accessibility enabled / authorization approved)
2) Fix permissions API contract:
   - make Android requests honest (settings navigation) and adjust helper accordingly
3) Fix iOS App Group consistency for restriction state storage
4) Decide whether scheduling is required now; if yes, design a cross-platform model and implement:
   - Android background scheduling
   - iOS `DeviceActivityMonitor` extension guidance + shared state contract
5) Tighten usage stats schema semantics (especially timestamps)

