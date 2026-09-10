---
name: layrz-ui-time-input
description: Use LayrzTimeInput in a layrz_ui Flutter widget. Apply when adding a single time-of-day field — digital-clock digit-box surface (no dial/spinner), Cancel/Save always-enabled commit, 12h/24h and seconds toggles.
---

> **Dart syntax:** This library requires Dart ≥ 3.13. Use dot shorthand for all enum values (e.g. `.someValue`) — never the fully-qualified form (`SomeEnum.someValue`).

> **Full constructor and property reference:** read `references/api.md` in this skill's directory.

---

## When to use

- Any single time-of-day field with no date component: daily opening time, reminder time, shift start.
- **Do not use** for a start/end time span — use `LayrzTimeRangeInput` instead.
- **Do not use** when a date is also needed — use `LayrzDateTimeInput` instead.
- **Do not use** for an elapsed duration (e.g. "2 hours 30 minutes") — that is a `Duration`, a different concept from a wall-clock reading; this widget's value type explicitly excludes `Duration`.

---

## Minimal usage

```dart
LayrzTimeInput(
  labelText: LayrzUiL10n.of(context).save,
  value: departureTime,
  onChanged: (value) {
    departureTime = value;
    if (context.mounted) onChanged.call();
  },
)
```

---

## Key behaviors

- `value` is a `LayrzTimeOfDay?` — an immutable `(hour, minute, second)` value, distinct from Flutter's Material `TimeOfDay` (unusable here — Material-free) and from `Duration` (an elapsed span, not a wall-clock reading).
- **Cancel/Save, not live-committing.** Editing a digit field only updates the dialog/sheet's in-progress draft; `onChanged` fires exactly once, when the user presses Save, with whatever the fields currently hold. Cancel reverts to `value`. Escape and a barrier tap both behave like Cancel.
- **Save is always enabled** — the one widget in this family without a gate. An unset `value` seeds the fields to midnight (`00:00`), and midnight is itself a valid, committable time.
- **No Clear action** — same reasoning as `LayrzDateInput`: a single time value has nothing to reset to empty independently of Cancel.
- **Digital-clock digit boxes, not a dial or spinner.** Big editable `HH : MM` boxes (plus `: SS` when `showSeconds` is true); in 12-hour mode a horizontal AM/PM toggle renders below. No interval snapping — any minute/second 0–59 is accepted.
- Each digit box lets the user type freely while focused; the typed value is clamped into range and reported only on blur/submit (Enter / keyboard "done"), never on every keystroke.
- `use24HourFormat` defaults to `true` — deliberately reversed from `ThemedTimePicker`'s old 12-hour default.
- Display text formats via house `strftime` `pattern` (default `'%H:%M'`); `formatter` overrides fully.
- At least one of `labelText`/`hintText` must be non-null — debug assertion.

---

## Common patterns

```dart
// 1. With seconds shown
LayrzTimeInput(
  labelText: 'Departure time',
  value: departureTime,
  showSeconds: true,
  errors: departureTimeErrors,
  onChanged: (value) {
    departureTime = value;
    if (context.mounted) onChanged.call();
  },
)

// 2. 12-hour clock
LayrzTimeInput(
  labelText: 'Reminder time',
  value: reminderTime,
  use24HourFormat: false,
  onChanged: (value) => setState(() => reminderTime = value),
)

// 3. Custom pattern
LayrzTimeInput(
  labelText: 'Opening time',
  value: openingTime,
  pattern: '%I:%M %p',
  use24HourFormat: false,
  onChanged: (value) => setState(() => openingTime = value),
)
```

---

## Form conventions

- Guard async `onChanged` follow-ups with `if (context.mounted)`.
- Localize `labelText`/`hintText`/`helpTitleText`/`helpContentText` via `LayrzUiL10n.of(context)`.
- Pass `errors: <List<String>>` computed and owned by your own form validation — restricted time windows (e.g. "no bookings before 9am") are a validation concern, not something this widget enforces.
- Separate stacked inputs with `const SizedBox(height: 10)`.
- Because Save is always enabled and defaults to midnight, treat a saved `00:00` as a real user choice, not a sentinel for "nothing picked" — track "untouched" separately in your own form state if that distinction matters to your product.
