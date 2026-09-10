# LayrzConnectionIndicator — API Reference

Source: `lib/src/connection/src/connection_indicator.dart`
- `LayrzConnectionIndicator` class
- `lib/src/connection/src/connection_indicator_mode.dart` — `LayrzConnectionIndicatorMode` enum
- `lib/src/connection/src/connection_state.dart` — `LayrzConnectionState` enum, `resolveLayrzConnectionState`
- `lib/src/connection/src/connection_times.dart` — `LayrzConnectionTimes`

---

## Examples

```dart
// Dot mode
LayrzConnectionIndicator(
  receivedAt: device.lastTelemetryAt,
  mode: LayrzConnectionIndicatorMode.dot,
)

// Full mode, wrapping caller content
LayrzConnectionIndicator(
  receivedAt: device.lastTelemetryAt,
  mode: LayrzConnectionIndicatorMode.full,
  child: Text(device.name),
)

// Custom thresholds
LayrzConnectionIndicator(
  receivedAt: device.lastTelemetryAt,
  mode: LayrzConnectionIndicatorMode.dot,
  connection: const LayrzConnectionTimes(
    online: Duration(minutes: 5),
    idle: Duration(minutes: 30),
  ),
)

// No data (receivedAt null) — resolves to the no-data state unconditionally
LayrzConnectionIndicator(
  receivedAt: null,
  mode: LayrzConnectionIndicatorMode.dot,
)

// Deterministic clock, for tests
LayrzConnectionIndicator(
  receivedAt: DateTime(2026, 1, 1, 11, 50),
  mode: LayrzConnectionIndicatorMode.dot,
  clock: () => DateTime(2026, 1, 1, 12, 0),
)

// Pure state resolution, no widget tree
final state = resolveLayrzConnectionState(
  receivedAt: DateTime(2026, 1, 1, 11, 50),
  now: DateTime(2026, 1, 1, 12, 0),
);
```

---

## Constructor

```dart
const LayrzConnectionIndicator({
  super.key,
  required this.receivedAt,
  this.connection,
  required this.mode,
  this.child,
  this.clock,
}) : assert(
       mode != LayrzConnectionIndicatorMode.dot || child == null,
       'LayrzConnectionIndicator.dot must not be given a child — it always renders its own bare '
       'dot visual. Use LayrzConnectionIndicatorMode.full to wrap custom content.',
     ),
     assert(
       mode != LayrzConnectionIndicatorMode.full || child != null,
       'LayrzConnectionIndicator.full requires a non-null child to wrap with the state chrome.',
     );
```

---

## Properties

| Property | Type | Default | Notes |
|---|---|---|---|
| `receivedAt` | `DateTime?` | required | Last time telemetry/data was received. `null` resolves unconditionally to the no-data state, regardless of `connection` or `clock`. |
| `connection` | `LayrzConnectionTimes?` | `null` | Optional online/idle thresholds. `null` uses `LayrzConnectionTimes.defaults()` (15 min online, 60 min idle). |
| `mode` | `LayrzConnectionIndicatorMode` | required | `.dot` or `.full` — see the enum table below. |
| `child` | `Widget?` | `null` | Content wrapped by the state chrome in `.full` mode. Must be `null` for `.dot`, non-null for `.full` (asserted at construction). |
| `clock` | `DateTime Function()?` | `null` | Clock used to resolve "now" against `receivedAt`. `null` resolves to `DateTime.now` at build time. Inject a fixed closure for deterministic tests. |

---

## `LayrzConnectionIndicatorMode` enum

| Value | Description |
|---|---|
| `.dot` | Renders a small colored dot (`LayrzBadgeVisual`) wrapped in a `LayrzTooltip` announcing the resolved state plus a humanized "time ago" string (e.g. `"Connected (2 minutes ago)"`). Must not receive a `child`. A `Semantics` wrapper carries the same announcement on the dot. |
| `.full` | Wraps the given `child` in a colored pill/chrome — background tinted to the resolved state color, foreground/icon color forced to that color's contrast via a hard `DefaultTextStyle`/`IconTheme`. Requires a non-null `child`; the widget never invents its own label/timestamp content in this mode. |

---

## `LayrzConnectionState` enum (internal 5-state model)

Exposed for testing via `resolveLayrzConnectionState` — not constructed directly by callers of the widget.

| Value | Elapsed since `receivedAt` | `colorOf(tokens)` |
|---|---|---|
| `.online` | 0 – `LayrzConnectionTimes.online` (default 15 min) | `tokens.colors.success` |
| `.idle` | up to `LayrzConnectionTimes.idle` (default 60 min) | `tokens.colors.warning` |
| `.offline` | up to `kLayrzConnectionOfflineBoundary` (30 days, fixed) | `tokens.colors.danger` |
| `.disconnected` | 30 days or more | `tokens.colors.fg1` (flat foreground token, not a semantic swatch — signals "gone", not "in trouble") |
| `.noData` | `receivedAt == null` | `tokens.colors.contextual` |

`resolveLayrzConnectionState({required DateTime? receivedAt, required DateTime now, LayrzConnectionTimes times = const LayrzConnectionTimes.defaults()})` is a pure, testable, `BuildContext`-free top-level function. `receivedAt == null` returns `.noData` unconditionally, regardless of `now`/`times`.

---

## `LayrzConnectionTimes`

Immutable config class (`@immutable`, `copyWith`, `==`/`hashCode`, `toString`). `layrz_ui` has no dependency on `layrz_models` and defines this type independently rather than accepting `layrz_models`' `Connection` class.

| Field | Type | Default (`LayrzConnectionTimes.defaults()`) | Notes |
|---|---|---|---|
| `online` | `Duration` | 15 minutes (`kLayrzConnectionDefaultOnline`) | Max elapsed time for the online state. Must be less than `idle`. |
| `idle` | `Duration` | 60 minutes (`kLayrzConnectionDefaultIdle`) | Max elapsed time for the idle state (beyond `online`). |

Constructors: `LayrzConnectionTimes({required online, required idle})` and `LayrzConnectionTimes.defaults()`.

Only `online`/`idle` are configurable — the 30-day offline→disconnected boundary and the no-data state are fixed constants; no caller has asked for those to vary.

---

## Static members

| Member | Signature | Notes |
|---|---|---|
| `kLayrzConnectionIndicatorTickInterval` | `const Duration(minutes: 1)` | How often the widget re-resolves its state via an internal `Timer.periodic`. |
| `kLayrzConnectionOfflineBoundary` | `const Duration(days: 30)` | Fixed elapsed-time boundary between offline and disconnected. Not configurable. |
| `kLayrzConnectionDefaultOnline` | `const Duration(minutes: 15)` | Default `online` threshold. |
| `kLayrzConnectionDefaultIdle` | `const Duration(minutes: 60)` | Default `idle` threshold. |

---

## Behavior notes

- **Live updates.** A `Timer.periodic` ticks every `kLayrzConnectionIndicatorTickInterval` (1 minute) and calls `setState` so the resolved state stays current without caller polling. Created in `initState`, unconditionally cancelled in `dispose`.
- **Clock source.** Elapsed time is measured against wall-clock duration only — no timezone-database dependency (`package:timezone`). This keeps the widget dependency-light; only elapsed duration matters for the 5-state boundaries, not calendar-local wall time.
- **`.full` mode contrast enforcement.** The hard `DefaultTextStyle`/`IconTheme` (not `.merge`) guarantees legibility on every state color, including the dark `fg1` Disconnected pill, even when the caller's `child` carries its own explicit text color.
- Downstream packages already modeling connection thresholds via `layrz_models`' `Connection` class are expected to bind their own type to `LayrzConnectionTimes` via an extension method — this conversion is outside `layrz_ui`'s scope.
