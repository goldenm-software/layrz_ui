# LayrzCalendar — API Reference

Source: `lib/src/calendar/src/`
- `LayrzCalendar` class — `calendar.dart`
- `LayrzCalendarController` class — `calendar_controller.dart`
- `LayrzCalendarEntry` class — `calendar_entry.dart`
- `LayrzCalendarMode` enum — `calendar_mode.dart`

---

## Examples

```dart
// Month view (default), with disabled Sundays
LayrzCalendar(
  entries: entries,
  isDateDisabled: (date) => date.weekday == DateTime.sunday,
)

// Explicit controller starting in week view
final controller = LayrzCalendarController(
  initialDate: DateTime(2026, 9, 1),
  initialMode: .week,
);

LayrzCalendar(controller: controller, entries: entries)

// Monday-first grid, 12-hour clock
LayrzCalendar(
  entries: entries,
  firstDayOfWeek: DateTime.monday,
  timeFormat: .amPm,
)

// Reacting to internal navigation (mode switch, day-number/overflow-chip taps)
LayrzCalendar(
  entries: entries,
  onModeChanged: (mode) => print('Now viewing $mode'),
  onTap: (date) => _createEntry(date),
)

// Subclassed entry with its own onTap and extra field
class MyEvent extends LayrzCalendarEntry {
  const MyEvent({
    required this.recordId,
    required super.title,
    required super.start,
    required super.end,
    super.onTap,
  });

  final int recordId;

  @override
  bool operator ==(Object other) => other is MyEvent && super == other && recordId == other.recordId;

  @override
  int get hashCode => Object.hash(super.hashCode, recordId);
}
```

---

## Constructor

```dart
const LayrzCalendar({
  this.controller,
  this.entries = const [],
  this.isDateDisabled,
  this.initialMode = LayrzCalendarMode.month,
  this.initialDate,
  this.firstDayOfWeek = DateTime.sunday,
  this.timeFormat = LayrzTimeFormat.h24,
  this.dayNumberOpensDayView = true,
  this.showWeekNumbers = true,
  this.onModeChanged,
  this.onTap,
  super.key,
}) : assert(
       firstDayOfWeek >= DateTime.monday && firstDayOfWeek <= DateTime.sunday,
       'firstDayOfWeek must be between DateTime.monday (1) and DateTime.sunday (7).',
     );
```

---

## Properties

| Property | Type | Default | Notes |
|---|---|---|---|
| `controller` | `LayrzCalendarController?` | `null` | `null` means the calendar creates, owns, and disposes its own. Non-`null` means caller-owned disposal; swapping the instance on rebuild asserts. |
| `entries` | `List<LayrzCalendarEntry>` | `const []` | Placed wherever `entry.occupies(date)` is true; a multi-day entry appears once per day/column/hour-grid it spans. |
| `isDateDisabled` | `bool Function(DateTime date)?` | `null` | Predicate, not a bounded collection — expresses open-ended rules. Purely visual. |
| `initialMode` | `LayrzCalendarMode` | `LayrzCalendarMode.month` | Used only when `controller` is `null`. |
| `initialDate` | `DateTime?` | `null` | Used only when `controller` is `null`. `null` means the current date. |
| `firstDayOfWeek` | `int` | `DateTime.sunday` | One of `DateTime.monday` (1)–`DateTime.sunday` (7); asserted. Applies to month and week modes. |
| `timeFormat` | `LayrzTimeFormat` | `LayrzTimeFormat.h24` | Governs week/day hour-axis and timed-event labels. No effect on month view. |
| `dayNumberOpensDayView` | `bool` | `true` | Whether tapping a month cell's day number navigates to day view. `false` renders the number fully inert (no hover/cursor/semantics). Has no effect on the "+N" overflow chip. |
| `showWeekNumbers` | `bool` | `true` | Whether an ISO-8601 week-number gutter renders left of the month grid, tappable to jump to week view. |
| `onModeChanged` | `void Function(LayrzCalendarMode mode)?` | `null` | Notification (mode already changed). Also fires from internal day-number/overflow-chip/week-number navigation. |
| `onTap` | `void Function(DateTime date)?` | `null` | Fires only for a tap on empty calendar surface — never for an entry, the day number, or the overflow chip. See Key behaviors for payload precision. |

---

## `LayrzCalendarController` — Constructor & Members

```dart
LayrzCalendarController({
  DateTime? initialDate,
  LayrzCalendarMode initialMode = LayrzCalendarMode.month,
})
```

| Member | Signature | Notes |
|---|---|---|
| `focusedDate` | `DateTime get` | The date currently in view; always midnight-normalized. |
| `mode` | `LayrzCalendarMode get` | Current view mode. |
| `nextMonth()` / `previousMonth()` | `void` | Moves `focusedDate` by one calendar month. |
| `nextWeek()` / `previousWeek()` | `void` | Moves by exactly 7 calendar days via field arithmetic (DST-safe, never `Duration`). |
| `nextDay()` / `previousDay()` | `void` | Moves by exactly one calendar day, same DST-safe stepping. |
| `goToToday()` | `void` | Sets `focusedDate` to today. |
| `goToDate(DateTime date)` | `void` | Sets `focusedDate` to `date` (time-of-day discarded). |
| `setMode(LayrzCalendarMode newMode)` | `void` | Sets `mode`; no-op if unchanged. |
| `dispose()` | `void` | Caller-owned if caller-supplied; calendar-owned otherwise. |

---

## `LayrzCalendarEntry` — Constructor & Properties

```dart
const LayrzCalendarEntry({
  required this.title,
  required this.start,
  required this.end,
  this.color,
  this.isPreview = false,
  this.onTap,
});
```

| Property | Type | Default | Notes |
|---|---|---|---|
| `title` | `String` | — | Required. Shown on cell/chip/bar/block. |
| `start` | `DateTime` | — | Required. |
| `end` | `DateTime` | — | Required. Must not be before `start` — a **caller obligation**, not asserted (would block `const` lists). |
| `color` | `Color?` | `null` | `null` falls back to a token-resolved default. |
| `isPreview` | `bool` | `false` | Renders as a ghost (reduced opacity + outline) while occupying a normal layout slot — no geometry difference from a committed entry. |
| `onTap` | `VoidCallback?` | `null` | Parameterless — the closure's own scope already has the entry's data. Excluded from `==`/`hashCode`. `null` renders the entry non-interactive. |

| Member | Signature | Notes |
|---|---|---|
| `isMultiDay` | `bool get` | Compares only year/month/day of `start`/`end`. |
| `occupies(DateTime date)` | `bool` | Date-only comparison over the inclusive `[start, end]` range. |
| `copyWith({...})` | `LayrzCalendarEntry` | All params optional; no way to null out `color`/`onTap` — construct a new instance for that. A subclass override should return its own runtime type. |

---

## `LayrzCalendarMode` enum

| Value | Description |
|---|---|
| `.month` | Full grid, one row per week, seven columns, with leading/trailing adjacent-month days. |
| `.week` | Seven day columns sharing one hour axis and one all-day/multi-day band. |
| `.day` | Single column, fixed 00:00–23:00 hour axis, scrollable. |

`LayrzTimeFormat` (companion enum, `calendar_time_format.dart`): `.amPm` · `.h24` (default). Governs week/day hour-axis labels only.

---

## Behavior notes

- **Four-region month-cell tap contract**: date number → day view (gated by `dayNumberOpensDayView`); "+N" overflow chip → day view (always, regardless of `dayNumberOpensDayView`); an event chip/bar → that entry's own `onTap`; anywhere else in the cell → `LayrzCalendar.onTap` at midnight.
- **Multi-day events** render as one continuous bar per week row (month view), not a chip per day cell. Lane assignment is stable for the whole month, not re-derived per week row — a day can show blank reserved lanes above its content; this is deliberate.
- **Visible event cap** is derived from measured cell height (`kLayrzCalendarEventSlotHeight`), not a fixed constant. Overflow collapses into a tappable "+N" chip.
- **Overlapping timed events** (week/day view) split their column evenly; the later-starting event draws on top (ties broken alphabetically), and a covered event renders demoted (lighter, outlined).
- **Disabled dates and "no events" are distinct code paths** — a disabled date never dims its own events, and never shares a render branch with an ordinary empty day.
- **No text is selectable** anywhere in the calendar (`SelectionContainer.disabled` wraps the whole widget) — this affects only text selection, not tap/hover/semantics.
- **Accessibility**: each month cell merges chrome state into one `Semantics` announcement (e.g. "August 28, today, disabled, 2 events"); the date number, overflow chip, and an interactive event chip each carry their own independent semantics node.
