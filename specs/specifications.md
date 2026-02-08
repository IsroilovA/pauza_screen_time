# Screen Time & App Restriction Plugin — Specifications

**Status:** Draft  
**Last updated:** 2026-02-07

## 1) Overview

This plugin provides a single Flutter-facing API for:

- Requesting and checking platform authorizations required for **app usage monitoring** and **app restriction / blocking**.
- Helping the host app select apps to restrict:
  - Android: enumerate installed apps.
  - iOS: present the system app picker and return opaque selection tokens.
- Enforcing restrictions (including a “shield” experience when a restricted app is opened).
- Scheduling restriction windows to start/stop locally on-device.
- Pausing restrions when restrion session is active.
- Exposing usage insights:
  - Android: usage statistics as data (aggregates).
  - iOS: usage reporting as an embeddable system UI view.

## 2) Goals

- Provide **reliable, local-first** enforcement of app restrictions while a restriction session is active.
- Expose a **consistent Dart API** that abstracts platform differences without hiding platform limitations.
- Make permissions and settings requirements **discoverable and actionable** (status checks + deep links to system settings).
- Support **offline operation** for enforcement and schedules (no server required).
- Support **reliable** fixed-time pauses to the restrictions while a restriction session is active. (ex: pause restrictions for 5 minutes).


## 3) Platform scope & constraints

### 3.1 Android

The plugin must be able to:

- Enumerate installed applications for selection.
- Query app usage statistics as **aggregated** data over a time range.
- Enforce hard restrictions that prevent use of selected apps while restrictions are active.
- Provide helpers to reach required system settings screens when user action is needed.

### 3.2 iOS

The plugin must be able to:

- Request and check the system authorization required for Screen Time-based restrictions.
- Present the system app picker and return **opaque selection tokens**.
- Enforce restrictions via system-managed controls while restrictions are active.
- Provide usage reporting as an embeddable system UI view.

The plugin must clearly support (and document) these constraints:

- iOS does not provide general-purpose “installed apps enumeration” for third-party apps; selection must be done via the system picker and stored as tokens.
- iOS usage reporting is provided primarily as a system UI visualization; the plugin must not promise programmatic access to raw per-app usage timelines where the platform does not allow it.

## 4) Core concepts & data contracts

### 4.1 App identifier

The plugin must represent “an app” using a platform-appropriate identifier:

- **Android:** application package identifier.
- **iOS:** opaque selection token produced by the system picker.

The Dart API must treat identifiers as opaque strings (or typed wrappers) and avoid implying cross-platform equivalence.

### 4.2 Restriction session

A restriction session is the period during which restrictions are actively enforced. The plugin must:

- Support at most one active restriction session at a time per device (unless explicitly designed otherwise).
- Provide an explicit API to start and stop enforcement.
- Provide an explicit API to temporarily pause enforcement for a bounded duration.

### 4.3 Shield experience

When the user attempts to open a restricted app during an active restriction session, the plugin must show a shield experience that:

- Blocks interaction with the restricted app.
- Provides minimal, configurable content (e.g., title/subtitle; changing color/transparancy).
- Does not include controls that directly disable restrictions.
- May provide a single configurable action to open/bring-to-foreground the host app (or a configured deep link).

### 4.4 Schedules

A schedule window is a recurring local rule that can start/stop enforcement automatically. Each schedule window must support:

- Days of week.
- Start time and end time (local time).
- Enabled/disabled flag.

Schedules must run locally and remain effective without network connectivity.

### 5.5 Usage data (Android)

Usage data returned by the plugin must be **aggregated**, not raw event streams. At minimum:

- Total device screen time over a period (when feasible).
- Per-app usage totals over a period.
- Optional bucketed aggregations (e.g., hourly buckets).

The plugin must define a clear granularity model (e.g., daily/hourly) and specify how partial-day ranges are handled.

### 5.6 Usage reporting (iOS)

On iOS, the plugin must provide an embeddable view component that renders system usage reporting for a given date range and/or context.

## 6) Functional requirements (Dart API surface)

### 6.1 Permissions & authorization

The plugin must provide:

- Status checks for each required authorization.
- A request flow that triggers the platform’s standard authorization prompts (when possible).
- A way to open the relevant system settings pages when manual enablement is required.
- Clear, structured error results for denied, restricted, and unavailable states.

### 6.2 Installed apps & selection

Android:

- Provide an API to list installed apps with at least:
  - stable identifier (package id),
  - display name,
  - icon (or a loadable icon handle),
  - flag(s) for system apps (if available).
  - app category

iOS:

- Provide an API to present the system picker and return selection results containing:
  - application token (opaque),
  - optional display metadata usable for UI (if the platform allows it).

### 6.3 Restrict / unblock apps

The plugin must provide APIs to:

- Apply restrictions to a set of app identifiers.
- Remove restrictions (unrestrict all or a provided subset).
- Query current restriction state (active/inactive, restricted set, and any remaining pause time).
- Update restrictions while enforcement is active (add/remove identifiers).

Behavior requirements:

- Enforcement changes must take effect promptly.
- Restrictions must remain effective across app restarts while the restriction session is active (within platform constraints).

### 6.4 Pause enforcement

The plugin must support pausing enforcement for a requested duration:

- During a pause, restricted apps must be usable.
- After the pause duration elapses, enforcement must automatically resume.
- The API must report whether pausing is supported on the current platform/device configuration.

### 6.5 Scheduling

The plugin must provide APIs to:

- Register schedule windows that start/stop enforcement locally.
- Update or cancel previously registered schedules.
- Query registered schedules.

The API must define how schedules interact with manual start/stop:

- Whether manual stop overrides an active schedule window.
- Whether schedule start can re-activate enforcement after a manual stop during the same window.

### 6.6 Usage stats (Android)

The plugin must provide APIs to:

- Query usage aggregates for a date range.
- Select granularity (e.g., daily totals, hourly buckets).
- Return data in a stable, documented schema.

The plugin must clearly specify:

- Time zone handling (device local vs provided zone).
- Rounding behavior for aggregates (e.g., minutes vs seconds).

### 6.7 Usage report view (iOS)

The plugin must provide a Flutter widget (or equivalent) that:

- Renders a system usage report for a given date range/context.
- Communicates “unsupported/unavailable” states via an explicit, recoverable error/result.

### 6.8 Events & observability

The plugin must expose an events stream that can include (as supported by the platform):

- Enforcement state changes (started/stopped/paused/resumed).
- Blocked attempt events when a restricted app is opened.
- Permission/authorization state changes detected by the plugin (when feasible).
- Schedule-triggered start/stop events.

Events must include:

- timestamp,
- event type,
- relevant identifiers (e.g., app identifier, session id if used),
- optional diagnostic payload.

### 6.9 Error model

The plugin must define a stable error taxonomy that differentiates:

- unsupported feature,
- missing permission / authorization,
- user denied permission,
- system restricted (e.g., parental/MDM limits),
- invalid arguments,
- internal failure.

Errors must be surfaced in a way that is compatible with Flutter best practices (typed results and/or typed exceptions).

## 7) Privacy, security, and data handling

- The plugin must minimize sensitive data collection and storage by default.
- The plugin must not transmit data off-device.
- If any local persistence is required for functionality (e.g., schedules, configuration), it must be documented and scoped to the minimum needed.
- Any identifiers returned by the platform (especially iOS selection tokens) must be treated as opaque and stored/handled securely by the host app.

## 8) Reliability & performance

- Enforcement must be resilient to host app lifecycle changes (backgrounding, termination, restart) within platform constraints.
- The plugin must fail safely:
  - If enforcement cannot be applied due to missing authorization, it must report a clear error and avoid silently “pretending” to restrict.
- Usage queries must accept a caller-provided date range and return aggregates within that range (subject to platform limits).

## 9) Acceptance criteria

- A Flutter app can:
  - detect and request required permissions/authorizations,
  - select apps to restrict on Android and iOS using platform-appropriate mechanisms,
  - start/stop restrictions and observe state changes via events,
  - display a shield when a restricted app is opened (where applicable),
  - pause enforcement for a bounded duration and observe resume behavior,
  - register schedules that start/stop enforcement locally without network connectivity,
  - read usage aggregates on Android for a given date range and granularity,
  - embed and display iOS system usage reporting via a Flutter view.
