---
name: layrz-ui-calendar
description: Use LayrzCalendar in a layrz_ui Flutter widget. Apply when rendering a navigable month/week/day calendar surface — single- and multi-day event chips, disabled dates, mode switching via LayrzCalendarController, or a tap-to-coordinate onTap callback.
---

> **Dart syntax:** This library requires Dart ≥ 3.13. Use dot shorthand for all enum values (e.g. `.month`, `.week`, `.day`) — never the fully-qualified form (`LayrzCalendarMode.month`).

> **Full constructor and property reference:** read `references/api.md` in this skill's directory.

---

## When to use

- Any month/week/day calendar surface that displays events and lets the user navigate periods.
- Use `entries` (a `List<LayrzCalendarEntry>`, typically subclassed) to render single- and multi-day events.
- Use `isDateDisabled` for visual-only disabled dates (weekends, past dates) — it is a predicate, not a bounded collection.
- Use `controller` (`LayrzCalendarController`) when you need to drive navigation programmatically (jump to a date, switch mode from outside the widget) or share state across multiple calendar surfaces.
- **Do not use** as a date picker — there is no persisted selection model and no return value from tapping a date. For a single/range date field, use `LayrzDateInput`/`LayrzDateRangeInput` instead.
- **Do not use** for a bare event list with no grid — a `LayrzTable`/`ListView` of events is simpler when no calendar grid is needed.

---

## Minimal usage

```dart
LayrzCalendar(
  entries: [
    LayrzCalendarEntry(
      title: 'Team standup',
      start: DateTime(2026, 8, 28, 9),
      end: DateTime(2026, 8, 28, 9, 30),
    ),
  ],
)
```

---

## Key behaviors

- **Not a selection surface** — `onTap` hands back a `DateTime` on every tap of empty calendar space; the calendar never remembers "the chosen one" and has no return value.
- **Tapping an event fires the entry's own `onTap`, never `LayrzCalendar.onTap`.** There is no `onEntryTap` on the calendar — `LayrzCalendarEntry.onTap` is wired per-instance by whoever constructs the entry.
- **Subclass `LayrzCalendarEntry`** to carry app data (a record ID, a domain object) — the base class is deliberately minimal (title, start, end, color, `isPreview`, `onTap`). A subclass adding fields meaningful to equality must override both `operator ==` and `hashCode`, folding in `super ==`/`super.hashCode`.
- `onTap`'s payload precision depends on mode: month view snaps to **midnight**; week/day view snaps to the nearest **15-minute** boundary at or before the tapped offset.
- `firstDayOfWeek` defaults to `DateTime.sunday` (not Monday) — pass `DateTime.monday` explicitly if you need a Monday-first grid.
- `dayNumberOpensDayView` (default `true`) and `showWeekNumbers` (default `true`) both navigate internally (day/week view) rather than calling any caller callback — observe them only through `onModeChanged`.
- All three `LayrzCalendarMode` values (`.month`, `.week`, `.day`) render and are reachable from the header's mode switcher. There is no year view.
- Lifecycle mirrors `LayrzStepper`: if `controller` is `null`, the calendar owns and disposes its own; if non-`null`, the caller owns disposal and the instance must never be swapped on rebuild (asserted).

---

## Common patterns

```dart
// 1. Subclassing LayrzCalendarEntry for domain data
class ShiftEntry extends LayrzCalendarEntry {
  const ShiftEntry({
    required this.shiftId,
    required super.title,
    required super.start,
    required super.end,
    super.color,
    VoidCallback? onTap,
  }) : super(onTap: onTap);

  final String shiftId;

  @override
  bool operator ==(Object other) =>
      other is ShiftEntry && super == other && shiftId == other.shiftId;

  @override
  int get hashCode => Object.hash(super.hashCode, shiftId);
}

// 2. Controller-driven navigation from outside the widget
final controller = LayrzCalendarController(initialMode: .week);

LayrzButton(
  labelText: 'Jump to today',
  onTap: controller.goToToday,
)

LayrzCalendar(controller: controller, entries: entries)

// 3. Disabled dates + tap-to-create
LayrzCalendar(
  entries: entries,
  isDateDisabled: (date) => date.weekday == DateTime.sunday,
  onTap: (date) => _openCreateEntryDialog(initialDate: date),
)

// 4. Preview (ghost) entry while a create flow is open
LayrzCalendarEntry(
  title: draftTitle,
  start: draftStart,
  end: draftEnd,
  isPreview: true,
)
```

---

## Usage conventions

- Wire `LayrzCalendarEntry.onTap` per entry at construction — never try to intercept taps via `LayrzCalendar.onTap`, which never fires for entry taps.
- Keep `LayrzCalendarEntry`/subclass construction pure and cheap — `LayrzCalendar` never reconstructs or copies an entry, so the instance you build is the exact one that reaches `onTap`.
- Ensure `end` is never before `start` on every entry — this is a caller obligation, not asserted at construction (to preserve `const` entry lists).
- All dates passed to one calendar (`entries`, `isDateDisabled`, the controller's `initialDate`) are expected to share a single timezone.
- Localize via `LayrzUiL10n.of(context)` — month names and AM/PM markers already resolve through it automatically; don't hardcode English month names elsewhere in the surrounding UI.
