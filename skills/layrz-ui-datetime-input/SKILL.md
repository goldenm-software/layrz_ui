---
name: layrz-ui-datetime-input
description: Use LayrzDateTimeInput in a layrz_ui Flutter widget. Apply when adding a single date+time field — Date/Time tab surface, in-panel Save gated on the date part alone (midnight-default time), 12h/24h and seconds toggles.
---

> **Dart syntax:** This library requires Dart ≥ 3.13. Use dot shorthand for all enum values (e.g. `.someValue`) — never the fully-qualified form (`SomeEnum.someValue`).

> **Full constructor and property reference:** read `references/api.md` in this skill's directory.

---

## When to use

- Any single field that needs both a date and a time-of-day: appointment, scheduled send, deadline with a specific hour.
- **Do not use** for a date-only field — use `LayrzDateInput` instead (lighter surface, no time tab).
- **Do not use** for a time-only field — use `LayrzTimeInput` instead.
- **Do not use** for a start/end datetime span — use `LayrzDateTimeRangeInput` instead.
- **Do not pass `presentation`** on new call sites — it is deprecated and has no visible effect (see Key behaviors). It exists only so an old `ThemedDateTimeSteppedPicker`/`ThemedDateTimePicker` migration doesn't break at the call site.

---

## Minimal usage

```dart
LayrzDateTimeInput(
  labelText: LayrzUiL10n.of(context).save,
  value: appointment,
  onChanged: (value) {
    appointment = value;
    if (context.mounted) onChanged.call();
  },
)
```

---

## Key behaviors

- `value` is a single `DateTime?`, but the widget still carries a Save button — the rule across this whole family is "one atomic value vs. multiple coordinated parts," not "single-valued vs. range." A date and a time are two coordinated parts here.
- **In-panel Save, gated on the date part alone.** Picking a date and pressing Save without ever touching the time fields commits that date **at midnight (`00:00`)** — a genuine, intentional value, not a placeholder for "unset." `onChanged` fires exactly once, on Save.
- Surface layout is a `LayrzTabView` with two tabs, "Date" and "Time", inside one dialog/bottom-sheet — not a single stacked scroll.
- `presentation` (`LayrzDateTimeInputPresentation`, default `.tabbed`) is **`@Deprecated` and fully inert** — passing `.tabbed` or `.stepped` compiles but changes nothing; both render identically as the Date/Time tab surface described above. There is no separate stepped-flow widget.
- `showSeconds` (default `false`) and `use24HourFormat` (default `true`) control the Time tab exactly like `LayrzTimeInput`.
- `firstDay`/`lastDay`/`disabledDays`/`firstDayOfWeek`/`showWeekNumbers` restrict the Date tab exactly like `LayrzDateInput`.
- Display text formats via house `strftime` `pattern` (default `'%Y-%m-%d %H:%M'`); `formatter` overrides fully.
- The committed value preserves `TZDateTime` zones via `sameZoneDateTime`.
- At least one of `labelText`/`hintText` must be non-null — debug assertion.

---

## Common patterns

```dart
// 1. With bounds and seconds shown
LayrzDateTimeInput(
  labelText: 'Scheduled send',
  value: scheduledAt,
  firstDay: DateTime.now(),
  showSeconds: true,
  errors: scheduledAtErrors,
  onChanged: (value) {
    scheduledAt = value;
    if (context.mounted) onChanged.call();
  },
)

// 2. 12-hour clock
LayrzDateTimeInput(
  labelText: 'Reminder',
  value: reminderAt,
  use24HourFormat: false,
  onChanged: (value) => setState(() => reminderAt = value),
)

// 3. Custom pattern
LayrzDateTimeInput(
  labelText: 'Deadline',
  value: deadline,
  pattern: '%d/%m/%Y %H:%M',
  onChanged: (value) => setState(() => deadline = value),
)
```

---

## Form conventions

- Guard async `onChanged` follow-ups with `if (context.mounted)`.
- Localize `labelText`/`hintText`/`helpTitleText`/`helpContentText` via `LayrzUiL10n.of(context)`.
- Pass `errors: <List<String>>` computed and owned by your own form validation.
- If your product needs to distinguish "user explicitly picked midnight" from "user never touched the time," track that separately in your own form state — the widget itself treats a Save with an untouched time tab as a genuine midnight commit.
- Separate stacked inputs with `const SizedBox(height: 10)`.
