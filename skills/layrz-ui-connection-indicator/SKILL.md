---
name: layrz-ui-connection-indicator
description: Use LayrzConnectionIndicator in a layrz_ui Flutter widget. Apply when rendering a live device/asset/connection status indicator — a 5-state (online/idle/offline/disconnected/no-data) resolution from elapsed time since last telemetry, as a bare dot or as a colored pill wrapping caller content.
---

> **Dart syntax:** This library requires Dart ≥ 3.13. Use dot shorthand for all enum values (e.g. `.dot`, `.full`) — never the fully-qualified form (`LayrzConnectionIndicatorMode.dot`).

> **Full constructor and property reference:** read `references/api.md` in this skill's directory.

---

## When to use

- Any live connection/telemetry status: device online/offline badges, asset trackers, last-seen indicators in a table or detail pane.
- Use `mode: .dot` for a compact colored dot with a tooltip announcing state + "time ago" — table cells, list rows, map markers.
- Use `mode: .full` to wrap arbitrary caller content (e.g. an asset name) in a state-colored pill — headers, cards, chips.
- **Do not use** for a generic network/API connectivity indicator unrelated to a specific entity's telemetry — this widget's 5-state model is specifically about elapsed time since `receivedAt`.
- **Do not use** for progress or loading feedback — use `LayrzProgressBar` instead.

---

## Minimal usage

```dart
// Dot mode — compact, with tooltip
LayrzConnectionIndicator(
  receivedAt: device.lastTelemetryAt,
  mode: .dot,
)
```

```dart
// Full mode — wraps caller content in a state-colored pill
LayrzConnectionIndicator(
  receivedAt: device.lastTelemetryAt,
  mode: .full,
  child: Text(device.name),
)
```

---

## Key behaviors

- **`mode: .dot` must NOT receive a `child`** — passing one throws an `AssertionError` at construction. Use `.full` to wrap content.
- **`mode: .full` REQUIRES a non-null `child`** — omitting one throws an `AssertionError` at construction.
- `receivedAt: null` always resolves to the no-data state, regardless of `connection` or `clock`.
- The widget re-renders itself once a minute via an internal `Timer.periodic` — no polling or manual rebuild needed from the caller.
- `.full` mode forces the child's text/icon color to the resolved state color's contrast color via a hard `DefaultTextStyle`/`IconTheme` (not `.merge`) — a caller-supplied `Text` with its own explicit color still renders legibly, most notably on the dark Disconnected pill.
- Elapsed time is measured against `DateTime.now()` in the local zone by default. Pass `clock` (a `DateTime Function()`) to inject a fixed time for tests — never rely on real wall-clock time in a test.
- Only the online/idle thresholds are configurable via `connection` (`LayrzConnectionTimes`); the 30-day offline→disconnected boundary is a fixed constant.

---

## The 5-state model

| State | Elapsed since `receivedAt` | Color |
|---|---|---|
| Online | 0 – `LayrzConnectionTimes.online` (default 15 min) | `tokens.colors.success` |
| Idle | up to `LayrzConnectionTimes.idle` (default 60 min) | `tokens.colors.warning` |
| Offline | up to 30 days (fixed) | `tokens.colors.danger` |
| Disconnected | 30 days or more (fixed) | `tokens.colors.fg1` |
| No data | `receivedAt == null` | `tokens.colors.contextual` |

---

## Common patterns

```dart
// Custom online/idle thresholds
LayrzConnectionIndicator(
  receivedAt: device.lastTelemetryAt,
  mode: .dot,
  connection: const LayrzConnectionTimes(
    online: Duration(minutes: 5),
    idle: Duration(minutes: 30),
  ),
)

// Full mode wrapping an icon + label row
LayrzConnectionIndicator(
  receivedAt: asset.lastSeenAt,
  mode: .full,
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Icon(MdiIcons.truck, size: 16),
      const SizedBox(width: 4),
      Text(asset.name),
    ],
  ),
)

// Deterministic clock for tests
LayrzConnectionIndicator(
  receivedAt: DateTime(2026, 1, 1, 11, 50),
  mode: .dot,
  clock: () => DateTime(2026, 1, 1, 12, 0),
)
```

---

## Usage conventions

- Never pass `layrz_models`' `Connection` object directly — this package has no dependency on `layrz_models`. Bind your own type to `LayrzConnectionTimes` in your own extension if you need to convert from a `Connection`.
- Don't build a custom "time ago" formatter for `.full` mode content — `.dot` mode already humanizes this internally; for `.full`, format your own caller-owned timestamp text consistently with the rest of your app.
- Prefer `.dot` in dense layouts (tables, lists); reserve `.full` for places where the entity's identity and its connection state should read as one visual unit.
- Do not wrap a `LayrzConnectionIndicator` in your own `Timer`/polling logic — the widget already refreshes itself every minute.
