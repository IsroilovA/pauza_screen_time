# Current State vs Specifications

**Repo:** `pauza_screen_time` (Flutter plugin)  
**Compared against:** `specs/specifications.md` (**Last updated:** 2026-02-07)  
**This assessment date:** 2026-02-08  
**Scope notes (from request):**
- Android usage stats **granularity is not required**.
- **Do not** analyze the `example/` app (not included below).
- **Events & observability are not required for now**.
- **Start/stop is not required** (host app will orchestrate “session lifecycle”).

---

## 0) Executive summary

### What is already implemented (high confidence)

**Dart API & architecture**
- A feature-based Dart API with managers:
  - `PermissionManager`, `InstalledAppsManager`, `AppRestrictionManager`, `UsageStatsManager`, plus `CoreManager`.
  - Source: `lib/pauza_screen_time.dart`, `lib/src/**`.
- Stable, typed error model with a **taxonomy-only** contract (`UNSUPPORTED`, `MISSING_PERMISSION`, `PERMISSION_DENIED`, `SYSTEM_RESTRICTED`, `INVALID_ARGUMENT`, `INTERNAL_FAILURE`).
  - Dart: `lib/src/core/pauza_error.dart`
  - Docs: `docs/errors.md`
- Method-channel split by feature (core / permissions / installed apps / restrictions / usage stats) and an iOS platform view for usage reports.
  - Dart channel names: `lib/src/core/method_channel_names.dart`
  - Android channel registrars: `android/src/main/kotlin/com/example/pauza_screen_time/**/method_channel/*Registrar.kt`
  - iOS channel registrars: `ios/Classes/**/MethodChannel/*Registrar.swift`
- Background isolate decoding for large Android payloads (installed apps and usage stats), with cancel + timeout support.
  - `lib/src/core/background_channel_runner.dart`

**Android**
- Installed apps enumeration with metadata (package id, name, optional icon bytes, category, system app flag).
  - Dart: `lib/src/features/installed_apps/**`
  - Native: `android/src/main/kotlin/com/example/pauza_screen_time/installed_apps/**`
- Usage stats as **aggregated** per-app data for a caller-provided `[startDate, endDate]`, including:
  - total foreground duration, launch count, bucket timestamps, last used/visible.
  - Dart: `lib/src/features/usage_stats/**`
  - Native: `android/src/main/kotlin/com/example/pauza_screen_time/usage_stats/**`
- App restriction via an `AccessibilityService` that detects foreground app changes and shows a full-screen shield overlay (Compose) for restricted apps.
  - Service: `android/src/main/kotlin/com/example/pauza_screen_time/app_restriction/AppMonitoringService.kt`
  - Overlay: `android/src/main/kotlin/com/example/pauza_screen_time/app_restriction/ShieldOverlayManager.kt`
  - Persistent state: `android/src/main/kotlin/com/example/pauza_screen_time/app_restriction/RestrictionManager.kt`
- Pause/resume enforcement implemented using a persisted `paused_until_epoch_ms` and shield suppression while paused.

**iOS (iOS 16+)**
- Screen Time authorization checks + request (`FamilyControls.AuthorizationCenter`).
  - `ios/Classes/Permissions/PermissionHandler.swift`
- App selection via `FamilyActivityPicker` returning **opaque** base64-encoded `ApplicationToken`s.
  - `ios/Classes/InstalledApps/FamilyActivityPickerHandler.swift`
- Restrictions via `ManagedSettingsStore.shield.applications` using decoded `ApplicationToken`s.
  - `ios/Classes/AppRestriction/ShieldManager.swift`
- Restriction session persistence in **App Group** defaults (desired tokens + pause-until timestamp).
  - `ios/Classes/AppRestriction/AppGroupStore.swift`
  - `ios/Classes/AppRestriction/RestrictionStateStore.swift`
- Shield configuration storage for a host Shield Configuration extension (plugin provides a reusable data source implementation).
  - Store: `ios/Classes/AppRestriction/ShieldConfigurationStore.swift`
  - Extension data source helper: `ios/Classes/AppRestriction/ShieldConfigurationExtension.swift`
- Usage reporting as an embeddable iOS platform view wrapping SwiftUI `DeviceActivityReport`.
  - Widget: `lib/src/features/usage_stats/widget/usage_report_view.dart`
  - Native: `ios/Classes/UsageStats/*`

### What is **not** implemented vs `specs/specifications.md`

**Not implemented**
- **Scheduling** APIs / local schedule windows (register/update/cancel/query) are not present in Dart or native code.
- **Events & observability** stream is not present (but also explicitly not required right now per scope notes).

**Spec items that are implemented differently than written**
- Spec expects explicit **start/stop** APIs. The plugin currently models “session” as:
  - “configured” = restricted identifiers exist,
  - “active now” = configured AND prerequisites satisfied AND not paused,
  - “stop” equivalent = `clearAllRestrictions()`.
  This is likely acceptable under the scope note “host orchestrates session lifecycle”, but it is a mismatch with the current spec text.
- Spec mentions Android usage stats “granularity model” and selecting granularity. Current API does not expose interval selection (uses `INTERVAL_BEST` natively) and returns per-app aggregates; this aligns with the scope note that granularity is not required.

### Doability snapshot (missing items)

- **Scheduling:** Doable on Android (AlarmManager/WorkManager), possible on iOS but realistically requires a host extension approach (DeviceActivityMonitor) and a design decision about where schedules live (plugin vs host). This is the biggest missing area.
- **Events:** Doable (Dart `EventChannel` or method-channel polling + stream) but deferred by scope note.

---

## 1) How the plugin is currently structured (“how it is done”)

### 1.1 Dart package structure

- Public entrypoint exports:
  - `lib/pauza_screen_time.dart` exports `src/core/core.dart` and feature modules.
- “Core” (shared utilities):
  - `AppIdentifier` as an opaque wrapper: `lib/src/core/app_identifier.dart`
  - typed errors & mapping from `PlatformException`: `lib/src/core/pauza_error.dart`
  - background isolate runner for heavy method-channel decoding: `lib/src/core/background_channel_runner.dart`
- Features:
  - permissions: `lib/src/features/permissions/**`
  - installed apps: `lib/src/features/installed_apps/**`
  - restrictions: `lib/src/features/restrict_apps/**`
  - usage stats: `lib/src/features/usage_stats/**`

### 1.2 Channels and API boundaries

**Dart** defines stable channel names and per-feature method name lists, then each manager delegates to a platform interface:
- Core: `pauza_screen_time/core`
- Permissions: `pauza_screen_time/permissions`
- Installed apps: `pauza_screen_time/installed_apps`
- Usage stats: `pauza_screen_time/usage_stats`
- Restrictions: `pauza_screen_time/restrictions`

Implementation details:
- Method-channel names: `lib/src/core/method_channel_names.dart`
- Each feature has:
  - an abstract platform interface (e.g. `PermissionPlatform`),
  - a method-channel implementation (e.g. `PermissionsMethodChannel`),
  - a manager that enforces platform guards (`Platform.isAndroid` / `Platform.isIOS`) and converts results into typed models.

### 1.3 Error model (taxonomy-only, typed in Dart)

**Native layers** return `FlutterError` / `result.error(code, message, details)` using only stable taxonomy codes.

**Dart layer**:
- Wraps and re-throws platform errors as typed `PauzaError` subclasses.
- Pattern: all manager methods call `...throwTypedPauzaError()` to guarantee typed exceptions.
- Source: `lib/src/core/pauza_error.dart`

Conformance to spec:
- This matches `specs/specifications.md` §6.9 “Error model” well (stable taxonomy, structured details).

### 1.4 Persistence model (important for “local-first”)

**Android**
- Restricted packages are persisted in `SharedPreferences` as JSON under:
  - key `blocked_apps` containing `{"blockedApps":[...]}`
  - pause stored under `paused_until_epoch_ms`
  - Source: `android/src/main/kotlin/com/example/pauza_screen_time/app_restriction/RestrictionManager.kt`
- Motivation: the `AccessibilityService` reads the same storage even when the Flutter UI is not running.

**iOS**
- Uses an **App Group** `UserDefaults(suiteName: ...)` store:
  - desired restricted tokens key: `desiredRestrictedApps`
  - pause-until key: `pausedUntilEpochMs`
  - Source: `ios/Classes/AppRestriction/RestrictionStateStore.swift`
- Shield UI configuration stored separately for extensions under key `shieldConfiguration`.
  - Source: `ios/Classes/AppRestriction/ShieldConfigurationStore.swift`
- App Group id resolution:
  1) `ShieldConfiguration(appGroupId: ...)` (Dart)
  2) `Info.plist` `AppGroupIdentifier`
  3) fallback `group.<bundleId>`
  - Source: `ios/Classes/AppRestriction/AppGroupStore.swift`

---

## 2) Requirements-by-requirements comparison to `specs/specifications.md`

This section follows the spec headings and answers, for each requirement:
- **Status:** Done / Partial / Not implemented / Deferred by scope notes
- **Conformance:** Whether the current implementation matches the spec intent
- **Fixability:** If not conforming, whether it is fixable, and what would be needed

### 2.1 §1 Overview (single Flutter-facing API)

**Spec intent:** one Flutter-facing API that covers permissions, selection, restriction/shield, scheduling, pause, usage insights.

**Current state:**
- ✅ Permissions: `PermissionManager`
- ✅ Selection: `InstalledAppsManager`
- ✅ Restriction/shield: `AppRestrictionManager` + `ShieldConfiguration`
- ✅ Pause: `pauseEnforcement(...)` / `resumeEnforcement()`
- ✅ Usage insights:
  - Android data: `UsageStatsManager`
  - iOS UI: `UsageReportView` platform view
- ❌ Scheduling: not implemented

**Conformance:** Partial (missing scheduling only; other pieces exist).

**Fixability:** Scheduling is fixable but needs a deliberate product decision (see §2.6 / “Scheduling”).

### 2.2 §2 Goals

#### Goal: reliable, local-first enforcement during an active session

**Android:** ✅
- Enforcement is local; overlay triggered by `AccessibilityService` and blocklist persisted in `SharedPreferences`.
- Works without network, and can work without the Flutter UI running (service is separate from Flutter isolate).

**iOS:** ✅ / 🟡
- Local enforcement via `ManagedSettingsStore`.
- Persisted desired tokens in App Group defaults.
- **Caveat:** timed resume after pause is not guaranteed if the app never runs again after pause start (explicitly documented as requiring a host monitor extension).

**Conformance:** Mostly matches spec, but “reliable fixed-time pause resume” is only fully achievable on iOS with a host extension approach.

**Fixability:** Yes, with a Device Activity Monitor extension in the host app (documented in `docs/ios-setup.md`).

#### Goal: consistent Dart API without hiding platform limitations

✅ Implemented and documented:
- Android uses package ids; iOS uses tokens.
- iOS “usage stats as data” is explicitly unsupported (Dart throws `PauzaUnsupportedError`).
- Docs repeatedly emphasize iOS limitations.

#### Goal: permissions discoverable and actionable

✅ Implemented:
- Typed permission status checks.
- Request flows open Settings (Android) or prompt (iOS).
- Direct settings open methods exist.

#### Goal: offline operation for enforcement and schedules

- Enforcement: ✅
- Schedules: ❌ (no scheduling feature exists yet)

### 2.3 §3 Platform scope & constraints

#### §3.1 Android required capabilities

| Requirement | Status | Notes |
|---|---|---|
| Enumerate installed apps | ✅ | PackageManager-based enumeration, optional icons/categories. |
| Query usage aggregates | ✅ | `UsageStatsManager.queryUsageStats(...)` + `queryEvents` for launches. |
| Enforce hard restrictions | ✅ | Accessibility service + full-screen overlay shield. |
| Helpers to reach settings | ✅ | `PermissionHandler` opens Usage Access / Accessibility. |

**Conformance notes:**
- The “hard restriction” is achieved as “overlay blocks interaction” rather than OS-level app disablement. That matches typical Android constraints but should be considered a “shield overlay enforcement” model, not a true OS lockout.

#### §3.2 iOS required capabilities

| Requirement | Status | Notes |
|---|---|---|
| Request/check Screen Time authorization | ✅ | `AuthorizationCenter` (iOS 16+). |
| Present system app picker, return tokens | ✅ | `FamilyActivityPicker` returns base64 tokens. |
| Enforce restrictions via system controls | ✅ | `ManagedSettingsStore.shield.applications`. |
| Usage reporting as embeddable UI view | ✅ | Platform view wraps `DeviceActivityReport`. |

**Conformance notes:**
- iOS 16+ requirement is enforced at podspec level (`ios/` platform is 16.0).

### 2.4 §4 Core concepts & data contracts

#### §4.1 App identifier

**Spec:** Android = package id, iOS = opaque token. Dart treats as opaque.

**Current state:** ✅
- `AppIdentifier` is an opaque wrapper around `String`.
  - `AppIdentifier.android(...)` and `.ios(...)` constructors exist but still store an opaque string.
  - Source: `lib/src/core/app_identifier.dart`
- Installed app models also expose identifiers:
  - Android: `AndroidAppInfo.packageId`
  - iOS: `IOSAppInfo.applicationToken`
  - Source: `lib/src/features/installed_apps/model/app_info.dart`

**Conformance:** Matches spec intent well.

#### §4.2 Restriction session

**Spec (as written):**
- At most one active session.
- Explicit start and stop APIs.
- Explicit pause for a bounded duration.

**Current state:**
- ✅ “At most one session” is true by design:
  - Android: one persisted blocklist + pause timestamp.
  - iOS: one persisted desired set + pause timestamp per App Group.
- ✅ Pause/resume exists:
  - Dart API: `pauseEnforcement(Duration)`, `resumeEnforcement()`, `getRestrictionSession()`
  - Android persistence: `paused_until_epoch_ms`
  - iOS persistence: `pausedUntilEpochMs`
- 🟡 Explicit start/stop is not a distinct API:
  - “Start” is effectively `restrictApps(...)` (configures the restricted set).
  - “Stop” is effectively `clearAllRestrictions()`.
  - There is no separate “start session” independent of restricted set content.

**Conformance:** Under the scope note “start/stop not needed”, this is acceptable. Against the literal spec text, this is a mismatch.

**Fixability:**
- If the spec still wants explicit start/stop, it is fixable by adding:
  - a persisted “sessionEnabled” flag separate from “restricted set exists”
  - and adding start/stop methods in Dart and native
  - plus updating `isRestrictionSessionActiveNow` semantics accordingly.
- If the spec is updated to match the scope note, no change needed.

#### §4.3 Shield experience

**Spec requirements:** blocks interaction, configurable minimal content, no “disable restrictions” control, optional deep link to host app.

**Current state:**

Android shield:
- ✅ Blocks interaction via full-screen `TYPE_ACCESSIBILITY_OVERLAY` window.
- ✅ Configurable content:
  - title/subtitle
  - colors
  - optional blur
  - optional icon bytes
  - optional primary/secondary labels
  - Source: `lib/src/features/restrict_apps/model/shield_configuration.dart`
  - Android mapping: `android/src/main/kotlin/com/example/pauza_screen_time/app_restriction/model/ShieldConfig.kt`
  - UI: `android/src/main/kotlin/com/example/pauza_screen_time/app_restriction/overlay/ShieldOverlayContent.kt`
- 🟡 “Action to open host app” is not implemented:
  - Current behavior: any button tap navigates to **Home screen** and hides the shield.
  - Source: `android/src/main/kotlin/com/example/pauza_screen_time/app_restriction/ShieldOverlayManager.kt`

iOS shield:
- ✅ The plugin supports configuring shield appearance via an App Group store.
- ✅ A reusable Shield Configuration extension data source is provided in plugin code.
- 🟡 Actual shield UI is owned by the **host extension target** (as required by iOS), so the plugin can only provide:
  - stored configuration payload,
  - sample/ready-to-copy data source implementation.
  - Source: `ios/Classes/AppRestriction/ShieldConfigurationExtension.swift`

**Conformance:**
- Blocking + configurability: yes.
- Deep link / “bring host app to foreground”: not present (Android currently goes Home; iOS depends on extension implementation).

**Fixability (if needed):**
- Android: add an optional “open host app” action that uses a configured deep link / activity intent (must be designed carefully to avoid loops and OS restrictions).
- iOS: document/implement in the host extension; plugin could add fields in shield config payload for a deep link, but the extension must decide what it’s allowed to do.

#### §4.4 Schedules

**Spec:** recurring local schedule windows (days of week, start/end, enabled), run locally offline.

**Current state:** ❌ Not implemented (no Dart APIs, no native schedulers, no persistence).

**Fixability / doability:** See §2.6 “Scheduling”.

### 2.5 §5 Usage data & reporting

#### §5.5 Usage data (Android)

**Spec:** aggregated usage data over a period, optional bucketed aggregations, and a granularity model.

**Current state:**
- ✅ Aggregated per-app totals exist:
  - `UsageStats.totalDuration` (foreground time)
  - `UsageStats.totalLaunchCount` (computed from events)
  - plus timestamps: `bucketStart`, `bucketEnd`, `lastTimeUsed`, `lastTimeVisible`
  - Dart model: `lib/src/features/usage_stats/model/app_usage_stats.dart`
  - Android implementation: `android/src/main/kotlin/com/example/pauza_screen_time/usage_stats/UsageStatsHandler.kt`
- 🟡 “Total device screen time” is not directly provided.
  - It can be approximated by summing per-app foreground durations returned, but it is not exposed as a first-class output.
- 🟡 Granularity selection is not exposed.
  - Native uses `UsageStatsManager.INTERVAL_BEST` and returns system buckets.
  - This is acceptable under the scope note “granularity not needed”.

**Conformance:** Partial vs spec text, but likely acceptable under the provided scope notes.

**Fixability:**
- If needed later, add:
  - a Dart “interval/granularity” parameter,
  - map to `UsageStatsManager.INTERVAL_DAILY` / `INTERVAL_WEEKLY` / etc,
  - or implement explicit bucketing in Dart/native.

#### §5.6 Usage reporting (iOS)

**Spec:** embeddable view component for usage reporting.

**Current state:** ✅
- Dart widget: `UsageReportView` / `IOSUsageReportView`
  - `lib/src/features/usage_stats/widget/usage_report_view.dart`
- iOS platform view:
  - `ios/Classes/UsageStats/UsageReportPlatformView.swift`
  - `ios/Classes/UsageStats/UsageReportContainerView.swift`
  - Implements `DeviceActivityReport(context, filter: ...)` with `daily`/`hourly` segment.

**Conformance:** Matches spec intent.

**One nuance:** the spec asks for explicit “unsupported/unavailable” states via recoverable error/result. Current Dart widget:
- renders a `fallback`/empty widget on non-iOS,
- relies on native view behavior on iOS.
If explicit error surfacing is needed later, the widget API would need to be expanded (e.g., a `Future<bool> isSupported()` or a visible error placeholder).

### 2.6 §6 Functional requirements (Dart API surface)

#### §6.1 Permissions & authorization

**Current state:** ✅
- Status checks:
  - Android: `checkAndroidPermission(AndroidPermission)`
  - iOS: `checkIOSPermission(IOSPermission)`
- Request flows:
  - Android: opens settings screens (Usage Access / Accessibility) and returns after intent dispatch
  - iOS: prompts system authorization via `AuthorizationCenter.requestAuthorization(...)`
- Settings deep links:
  - Android: `openAndroidPermissionSettings(...)`
  - iOS: `openPermissionSettings` opens app settings
- Structured errors:
  - native layers use taxonomy codes and include `details` with `feature/action/platform/(missing/status/diagnostic)`

**Conformance:** Good.

**Notes / edge cases:**
- Android “request permission” is not synchronous (by design); this is documented in `docs/permissions.md`.
- Android `QUERY_ALL_PACKAGES` is treated as non-runtime requestable (correct), but the plugin manifest currently declares it (see §7 Privacy/Policy notes).

#### §6.2 Installed apps & selection

**Android current state:** ✅
- Provides: package id, display name, icon bytes (optional), system-app flag, category (optional).
- Dart model: `AndroidAppInfo` in `lib/src/features/installed_apps/model/app_info.dart`.

**iOS current state:** ✅
- Provides a picker returning opaque `ApplicationToken` strings.
- No name/icon in Dart (correct per platform constraint).

**Conformance:** Matches spec well.

**Policy note:** Android app enumeration uses `QUERY_ALL_PACKAGES` (declared in plugin manifest). This may be unacceptable for some Play Store categories unless justified; see `docs/android-setup.md`.

#### §6.3 Restrict / unblock apps

**Current state:** ✅
- Apply restrictions:
  - `restrictApps(List<AppIdentifier>)` (sets full list)
  - `restrictApp(AppIdentifier)` (add one)
- Remove restrictions:
  - `unrestrictApp(AppIdentifier)` (remove one)
  - `clearAllRestrictions()` (remove all)
- Query:
  - `getRestrictedApps()`
  - `isAppRestricted(...)`
  - session snapshot APIs:
    - `isRestrictionSessionActiveNow()`
    - `isRestrictionSessionConfigured()`
    - `getRestrictionSession()`
- Update while active:
  - supported by add/remove APIs on both platforms.

**Conformance:** Matches spec intent (even if start/stop is not explicit).

**Important behavior choice (Android):**
- On Android, attempting to apply restrictions while Accessibility is disabled fails with `MISSING_PERMISSION` and does **not** persist the desired restricted list.
  - Conforms to “fail safely” but prevents “preconfigure then enable later”.
  - If host wants “configure now, enforce later”, this behavior would need a change.

#### §6.4 Pause enforcement

**Current state:** ✅
- API exists on both platforms:
  - `pauseEnforcement(Duration)`
  - `resumeEnforcement()`
- Session snapshot includes pause state and pause-until timestamp.

**Android behavior:** ✅
- Pause persists as an absolute epoch timestamp; `AccessibilityService` suppresses overlay while paused.
- After pause expires, enforcement resumes automatically because checks are time-based in `AppMonitoringService`.

**iOS behavior:** 🟡
- Pause stores a pause-until epoch timestamp, clears restrictions immediately, and relies on subsequent plugin execution to re-apply when no longer paused.
- For **reliable** timed auto-resume while the app is backgrounded/terminated, the host must implement a Device Activity Monitor extension (documented in `docs/ios-setup.md`).

**Conformance:** Meets spec in concept; reliability on iOS depends on host extension setup.

**Fixability:** Yes (host extension + shared app group state).

#### §6.5 Scheduling

**Current state:** ❌
- No schedule window model in Dart.
- No native scheduling/persistence.

**Doability & recommended approach:**

Android:
- Doable. Typical implementations:
  - `AlarmManager` + `BroadcastReceiver` to trigger restrict/unrestrict at fixed local times.
  - `WorkManager` for more flexible + OS-friendly scheduling, but it is not a strict “exact time” mechanism.
- Requires a persistence model for schedule definitions (SharedPreferences/Room).
- Requires defining how schedules interact with “manual overrides”.

iOS:
- “Real” scheduling that survives termination is typically implemented via:
  - Device Activity Monitor extension with `DeviceActivitySchedule`, and re-applying ManagedSettings based on schedule callbacks.
- This is feasible but significantly increases host integration requirements.

Given the scope note “host will do start/stop”, the cleanest design may be:
- plugin provides primitives (restrict set, pause),
- host owns schedules (and can call plugin at schedule boundaries),
unless there is a strong reason to embed scheduling inside the plugin.

#### §6.6 Usage stats (Android)

**Current state:** ✅
- API: `UsageStatsManager.getUsageStats(...)` and `.getAppUsageStats(...)`.
- Schema: documented in `docs/usage-stats.md` and implemented in `UsageStats.fromMap`.

**Granularity:** not exposed (acceptable per scope note).

**Permission failure semantics:** ✅
- Native usage stats preflights `android.usageStats` before querying.
- If Usage Access is missing, method-channel calls return taxonomy code `MISSING_PERMISSION` with structured details (`missing=["android.usageStats"]`, `status={"android.usageStats":"denied"}`), which maps to `PauzaMissingPermissionError` in Dart.

#### §6.7 Usage report view (iOS)

**Current state:** ✅
- Provided as a widget + iOS platform view.
- Supports daily/hourly segmentation.

**Conformance:** Good.

#### §6.8 Events & observability

**Current state:** ❌ (and **deferred** by scope note)

**Doability:** Yes, but requires design:
- what events exist on each platform,
- how they are delivered (EventChannel vs polling),
- privacy implications (blocked attempt events can be sensitive).

#### §6.9 Error model

**Current state:** ✅
- Stable taxonomy and typed Dart mapping exists.
- Docs match implementation.

---

## 3) Acceptance criteria (spec §9) — evaluated with scope notes applied

Spec acceptance criteria list (paraphrased) vs current implementation:

- Detect and request permissions/authorizations: ✅
- Select apps to restrict using platform-appropriate mechanism: ✅
- Start/stop restrictions and observe state changes via events:
  - Start/stop: 🟡 (no explicit start/stop; restrict/clear equivalents exist; scope note says start/stop not needed)
  - Events: ❌ (explicitly not needed now per scope note)
- Display a shield when restricted app is opened: ✅
- Pause for bounded duration and observe resume:
  - Android: ✅
  - iOS: 🟡 (resume reliability depends on host extension)
- Register schedules that start/stop enforcement locally: ❌
- Read Android usage aggregates for a date range (granularity optional): ✅
- Embed and display iOS usage reporting UI: ✅

---

## 4) What the spec currently says that we likely should change (based on scope notes)

These are “spec deltas” that are not implemented **because they are not required** per the notes, and the spec should be updated to avoid tracking them as gaps:

1) **Start/stop APIs**
   - Spec currently requires explicit start/stop methods (§4.2 / acceptance criteria).
   - Scope note: host orchestrates; plugin does not need start/stop.
   - Recommendation: rewrite spec to define session as “restricted set + prerequisites + pause state”, and treat `clearAllRestrictions()` as “stop”.

2) **Events & observability**
   - Spec requires an events stream (§6.8).
   - Scope note: not needed now.
   - Recommendation: mark as deferred/non-goal for the current version.

3) **Android usage stats granularity selection**
   - Spec requires granularity model and selection (§5.5, §6.6).
   - Scope note: not needed.
   - Recommendation: remove granularity selection requirement (or mark as optional/future).

---

## 5) Remaining gaps (if we still want full spec compliance later)

### 5.1 Scheduling (largest gap)

**Gap:** no schedule window APIs or implementation.

**Is it doable?** Yes, but scope decisions matter:
- If schedules belong to the host app, the plugin can remain as-is.
- If schedules belong to the plugin, both platforms need persistence + background execution design, and iOS likely requires extension-based scheduling.

**Recommended next step:** decide ownership:
- “Host owns schedules” (simpler, fits note #4)
- vs “Plugin owns schedules” (more turnkey, more complex, iOS host changes unavoidable)

### 5.2 iOS pause auto-resume reliability (only if required)

**Gap:** plugin alone cannot guarantee re-application after pause expiry if the host app is never invoked again.

**Doable?** Yes, but it’s a host integration requirement:
- Device Activity Monitor extension reads App Group stored desired restrictions + pause state and re-applies when schedule/monitor callbacks run.

### 5.3 Usage stats missing-permission signaling (Android)

**Status:** fixed.

- Implemented via Android preflight + explicit `MISSING_PERMISSION` method-channel mapping.

---

## 6) Appendix — notable implementation details worth knowing

### 6.1 Why large Android calls use a background isolate

Android installed apps and usage stats can return large lists, especially when including icons (byte arrays). The plugin decodes these method-channel payloads on a background isolate to avoid UI jank.

This is implemented by `BackgroundChannelRunner` and used by:
- `InstalledAppsMethodChannel.getInstalledApps(...)`
- `UsageStatsMethodChannel.queryUsageStats(...)`

### 6.2 Data contracts (selected)

- `ShieldConfiguration.toMap()` uses ARGB ints and passes optional icon bytes.
  - Dart: `lib/src/features/restrict_apps/model/shield_configuration.dart`
  - Android expects `Map<String, Any?>` and maps to `ShieldConfig`.
  - iOS stores configuration in App Group defaults for extensions.

- Restriction session snapshot contract:
  - Dart: `RestrictionSession` model (`isActiveNow`, `isPausedNow`, `pausedUntil`, `restrictedApps`)
- Native payload keys: `isActiveNow`, `isPausedNow`, `pausedUntilEpochMs`, `restrictedApps`

### 6.3 Test coverage (Dart)

There are small unit tests validating:
- error taxonomy mapping: `test/pauza_error_test.dart`
- manager typed error throwing: `test/manager_error_throwing_test.dart`
- usage stats timestamp parsing: `test/usage_stats_model_test.dart`
- restrictions session method-channel and delegation behavior: `test/restrictions_session_test.dart`

### 6.4 Channel + method surface (what exists today)

This is the practical API surface the host can rely on (and what native handlers currently implement).

- `pauza_screen_time/core`
  - `getPlatformVersion`
- `pauza_screen_time/permissions`
  - `checkPermission(permissionKey)`
  - `requestPermission(permissionKey)`
  - `openPermissionSettings(permissionKey)`
- `pauza_screen_time/installed_apps`
  - Android:
    - `getInstalledApps(includeSystemApps, includeIcons)`
    - `getAppInfo(packageId, includeIcons)`
  - iOS:
    - `showFamilyActivityPicker(preSelectedTokens)`
- `pauza_screen_time/usage_stats` (Android-only by design)
  - `queryUsageStats(startTimeMs, endTimeMs, includeIcons)`
  - `queryAppUsageStats(packageId, startTimeMs, endTimeMs, includeIcons)`
- `pauza_screen_time/restrictions`
  - `configureShield(configurationMap)`
  - `setRestrictedApps(identifiers[])`
  - `addRestrictedApp(identifier)`
  - `removeRestriction(identifier)`
  - `removeAllRestrictions()`
  - `getRestrictedApps()`
  - `isRestricted(identifier)`
  - session:
    - `isRestrictionSessionActiveNow()`
    - `isRestrictionSessionConfigured()`
    - `getRestrictionSession()`
  - pause:
    - `pauseEnforcement(durationMs)`
    - `resumeEnforcement()`

Sources:
- Dart: `lib/src/core/method_channel_names.dart`, `lib/src/core/method_names.dart`, plus per-feature `method_channel/method_names.dart`
- Android: `android/src/main/kotlin/com/example/pauza_screen_time/core/MethodNames.kt`
- iOS: `ios/Classes/Core/MethodNames.swift`

### 6.5 Android restriction enforcement — step-by-step

1) Host configures desired shield appearance (optional but recommended):
   - Dart calls `configureShield(ShieldConfiguration)` which serializes to a map.
   - Native stores the config in memory in `ShieldOverlayManager`.
2) Host applies restricted identifiers:
   - `restrictApps([...packageIds...])` persists the list into `SharedPreferences` via `RestrictionManager`.
   - If Accessibility is disabled, the call fails with `MISSING_PERMISSION` and does not persist.
3) Foreground detection:
   - `AppMonitoringService` listens to `TYPE_WINDOW_STATE_CHANGED` and `TYPE_WINDOWS_CHANGED`.
   - It tries to resolve the *focused* app using interactive windows (reduces false positives).
   - It debounces events (`EVENT_DEBOUNCE_MS = 500`) and avoids re-processing same package.
4) Blocking:
   - If paused (`paused_until_epoch_ms > now`), the service hides any overlay and does nothing.
   - If the app is in the restricted set, it shows a full-screen `TYPE_ACCESSIBILITY_OVERLAY`.
5) Shield dismissal:
   - If user navigates to launcher / host app, overlay is hidden.
   - Transient system UI / IME events are ignored to avoid flicker.
   - Button taps currently navigate to **Home** and hide the overlay (no “open host app” action yet).

Primary sources:
- Foreground monitor: `android/src/main/kotlin/com/example/pauza_screen_time/app_restriction/AppMonitoringService.kt`
- Persisted state: `android/src/main/kotlin/com/example/pauza_screen_time/app_restriction/RestrictionManager.kt`
- Overlay: `android/src/main/kotlin/com/example/pauza_screen_time/app_restriction/ShieldOverlayManager.kt`

### 6.6 iOS restriction enforcement — step-by-step

Conceptually there are *two* sets:
- **Desired** restrictions (persisted in App Group defaults): what the host asked to restrict.
- **Applied** restrictions (in `ManagedSettingsStore`): what iOS is currently shielding.

Flow:

1) Host requests Screen Time authorization:
   - `AuthorizationCenter.shared.requestAuthorization(for: .individual)` (iOS 16+).
2) Host selects apps:
   - `FamilyActivityPicker` returns selected `ApplicationToken`s encoded as JSON then base64.
   - Tokens are opaque; Dart cannot show app name/icon without a native UI.
3) Host applies restrictions:
   - Tokens are decoded (fail-fast; if any are invalid, the call returns `INVALID_ARGUMENT`).
   - Desired base64 strings are persisted to App Group defaults (`desiredRestrictedApps`).
   - `applyDesiredRestrictionsIfNeeded()` sets `ManagedSettingsStore.shield.applications`.
4) Pause:
   - Stores `pausedUntilEpochMs` in App Group defaults.
   - Clears `ManagedSettingsStore` shields immediately.
   - Re-application after pause expiry requires code execution again (host app invocation or a host extension).

Primary sources:
- Desired store + pause store: `ios/Classes/AppRestriction/RestrictionStateStore.swift`
- Decoder + applied store: `ios/Classes/AppRestriction/ShieldManager.swift`
- Method logic: `ios/Classes/AppRestriction/MethodChannel/RestrictionsMethodHandler.swift`

### 6.7 Android usage stats query semantics (what the data actually means)

- Native queries via `UsageStatsManager.queryUsageStats(INTERVAL_BEST, start, end)`.
  - The interval is chosen by the system, not by the caller.
- Launch counts are computed by scanning `UsageStatsManager.queryEvents(start, end)` and counting `ACTIVITY_RESUMED`.
- Returned items are filtered to those with `totalTimeInForeground > 0`.
- Timestamps (`bucketStartMs`, `bucketEndMs`) are mapped from `UsageStats.firstTimeStamp` / `lastTimeStamp`.
  - These are *bucket* boundaries and should not be interpreted as “first use” / “last use” within the caller’s interval.

Primary source:
- `android/src/main/kotlin/com/example/pauza_screen_time/usage_stats/UsageStatsHandler.kt`

### 6.8 iOS usage report view semantics

- Dart passes `reportContext`, `segment` (`daily`/`hourly`), and `[startTimeMs, endTimeMs]`.
- iOS builds a `DeviceActivityFilter`:
  - `segment: .daily(during: interval)` or `.hourly(during: interval)`
  - `users: .all`, `devices: .all`
- If `endDate <= startDate`, native normalizes to a +1 hour interval.

Primary source:
- `ios/Classes/UsageStats/UsageReportContainerView.swift`

---

## 7) Overview (end): what is not done, and what should be improved

### 7.1 What is **not done** (per `specs/specifications.md`)

- **Scheduling feature (Dart API + native implementations)** — **NOT IMPLEMENTED**
  - Missing: schedule window model (days-of-week, start/end, enabled), plus register/update/cancel/query APIs.
  - Missing: Android scheduler + persistence.
  - Missing: iOS scheduling design (likely requires host extension / DeviceActivityMonitor).
  - Spec refs: §4.4, §6.5, §9.
- **Events & observability stream** — **NOT IMPLEMENTED** (and **explicitly out-of-scope for now**)
  - Missing: enforcement state change events, blocked attempts, permission changes, schedule-triggered events.
  - Spec refs: §6.8, §9.
- **Explicit “start/stop enforcement session” API** — **NOT IMPLEMENTED** as a first-class concept (but **explicitly out-of-scope for now**)
  - Current behavior: “start” ≈ apply restricted identifiers; “stop” ≈ `clearAllRestrictions()`.
  - Spec refs: §4.2, §9.

### 7.2 What should be **improved** (quality + spec alignment)

- **Shield action to open/foreground the host app (Android)** (optional / spec-alignment)
  - Current behavior: shield button taps navigate to **Home** and hide shield.
  - Spec suggests a single action may open/bring-to-foreground host app (or deep link).
  - Spec refs: §4.3.
- **Android restrictions: consider “configure now, enforce when prerequisites enabled”** (product decision)
  - Current behavior: if Accessibility is disabled, `restrictApps(...)` fails with `MISSING_PERMISSION` and does not persist desired restrictions.
  - Alternative: persist desired list even when prerequisites are missing, but mark session inactive until enabled.
  - Spec refs: §6.3 behavior, §8 (“fail safely”).
- **iOS pause auto-resume reliability** (only if we decide it must be reliable without app running)
  - Current behavior: pause stores `pausedUntilEpochMs` and clears restrictions; re-apply requires code execution again.
  - Improvement: document + provide a concrete host extension recipe (Device Activity Monitor extension) that re-applies when pause ends.
  - Spec refs: §2 goals, §6.4.
- **Update `specs/specifications.md` to reflect current scope decisions** (recommended)
  - Remove/mark-deferred: events, explicit start/stop, Android granularity selection.
  - Add: “session = configured set + prerequisites + pause state” semantics (matches current implementation).
