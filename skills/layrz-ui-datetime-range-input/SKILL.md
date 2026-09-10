---
name: layrz-ui-datetime-range-input
description: Use LayrzDateTimeRangeInput in a layrz_ui Flutter widget. Apply when adding a start/end datetime-span field — Date/Time tab surface (Time tab holds both Start and End clusters), in-panel Cancel/Clear/Save gated on date-range completeness, midnight-default time parts.
---

> **Dart syntax:** This library requires Dart ≥ 3.13. Use dot shorthand for all enum values (e.g. `.someValue`) — never the fully-qualified form (`SomeEnum.someValue`).

> **Full constructor and property reference:** read `references/api.md` in this skill's directory.

---

## When to use

- Any start/end field that needs both dates and times: event window, shift with exact start/end, maintenance outage window.
- **Do not use** for a date-only span — use `LayrzDateRangeInput` instead.
- **Do not use** for a time-only span (same day) — use `LayrzTimeRangeInput` instead.
- **Do not use** for a single datetime — use `LayrzDateTimeInput` instead.

---

## Minimal usage

```dart
LayrzDateTimeRangeInput(
  labelText: LayrzUiL10n.of(context).save,
  startValue: eventStart,
  endValue: eventEnd,
  onChanged: (start, end) {
    eventStart = start;
    eventEnd = end;
    if (context.mounted) onChanged.call();
  },
)
```

---

## Key behaviors

- `startValue`/`endValue` (`DateTime?`) are always the committed endpoints — `onChanged` reports a `(DateTime start, DateTime end)` positional pair, not a wrapper type.
- Coordinates **four** parts (start date, start time, end date, end time) inside a single Save. `onChanged` fires exactly once, on Save.
- Surface layout: a `LayrzTabView` with two tabs. Tab 1 is the range calendar (same endpoint-adjust model as `LayrzDateRangeInput`); Tab 2 holds **both** the Start and End time clusters together, so each tab's own content fits the dialog's default height.
- **Midnight is a valid, committable value** for each endpoint's time part — it seeds from `startValue`/`endValue`'s own time when non-null, else to `00:00`. Save's enablement follows the **date range's completeness alone** — it never checks whether either endpoint's time was independently touched.
- **Clear** resets the in-progress date range to empty (enabled once a selection exists); **Cancel** discards the whole draft. An involuntary close (Escape, barrier tap) also discards the draft; reopening starts clean from `startValue`/`endValue`.
- `showSeconds`/`use24HourFormat` control both time clusters identically, exactly like `LayrzTimeRangeInput`.
- Display text formats each endpoint via house `strftime` `pattern` (default `'%Y-%m-%d %H:%M'`), joined by the localized range separator; `formatter` overrides fully as `String Function(DateTime start, DateTime end)`.
- Endpoints preserve `TZDateTime` zones via `sameZoneDateTime`.
- At least one of `labelText`/`hintText` must be non-null — debug assertion.

---

## Common patterns

```dart
// 1. Bounded date range with seconds shown
LayrzDateTimeRangeInput(
  labelText: 'Maintenance window',
  startValue: windowStart,
  endValue: windowEnd,
  firstDay: DateTime.now(),
  showSeconds: true,
  errors: windowErrors,
  onChanged: (start, end) {
    windowStart = start;
    windowEnd = end;
    if (context.mounted) onChanged.call();
  },
)

// 2. 12-hour clock
LayrzDateTimeRangeInput(
  labelText: 'Shift window',
  startValue: shiftStart,
  endValue: shiftEnd,
  use24HourFormat: false,
  onChanged: (start, end) => setState(() {
    shiftStart = start;
    shiftEnd = end;
  }),
)
```

---

## Form conventions

- Guard async `onChanged` follow-ups with `if (context.mounted)`.
- Localize `labelText`/`hintText`/`helpTitleText`/`helpContentText` via `LayrzUiL10n.of(context)`.
- Pass `errors: <List<String>>` computed and owned by your own form validation.
- Enforce range-length limits and restricted time windows yourself via `errors` — the picker never rejects on either.
- Separate stacked inputs with `const SizedBox(height: 10)`.
