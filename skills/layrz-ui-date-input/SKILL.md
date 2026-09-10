---
name: layrz-ui-date-input
description: Use LayrzDateInput in a layrz_ui Flutter widget. Apply when adding a single-date selection field — read-only anchor field that opens a day-grid dialog/sheet, Cancel/Save commit, firstDay/lastDay/disabledDays bounds, strftime-pattern display.
---

> **Dart syntax:** This library requires Dart ≥ 3.13. Use dot shorthand for all enum values (e.g. `.someValue`) — never the fully-qualified form (`SomeEnum.someValue`).

> **Full constructor and property reference:** read `references/api.md` in this skill's directory.

---

## When to use

- Any single-date form field: birthdate, start date, due date, event date.
- Use `firstDay`/`lastDay`/`disabledDays` to restrict *which dates are selectable* on the grid — this is a selection-surface concern, supported directly.
- Business-rule validation on an already-chosen date (e.g. "must be a weekday") is **not** a selection concern — enforce it via `errors`, not via the picker's bounds.
- **Do not use** for a start+end span — use `LayrzDateRangeInput` instead.
- **Do not use** when time-of-day also matters — use `LayrzDateTimeInput` instead.

---

## Minimal usage

```dart
LayrzDateInput(
  labelText: LayrzUiL10n.of(context).save,
  value: startDate,
  onChanged: (value) {
    startDate = value;
    if (context.mounted) onChanged.call();
  },
)
```

---

## Key behaviors

- `value` (`DateTime?`) is the committed date; `null` renders the field empty (shows `hintText` if set).
- **Cancel/Save, not commit-on-tap.** Tapping a day in the grid only updates the dialog/sheet's in-progress draft; `onChanged` fires exactly once, when the user presses **Save**, with the drafted date. Escape and a barrier tap behave like Cancel and discard the draft.
- **No Clear action** — a single date has nothing to reset to "empty" independently of Cancel, so the actions row is Cancel/Save only.
- Reopening the picker always re-seeds the grid from the current `value`, never from wherever the user last browsed without saving.
- `firstDayOfWeek` defaults to `DateTime.monday` (deliberately differs from `LayrzCalendar`'s `DateTime.sunday` default); must be within `DateTime.monday..DateTime.sunday`.
- `showWeekNumbers` (default `true`) shows the ISO week-number gutter.
- Display text is formatted with the house `strftime`-style formatter (`pattern`, default `'%Y-%m-%d'`) — Python `datetime` directives (`%Y %m %d %H %M %S %B %b %A %a %p`, etc.), **not** `intl`/`DateFormat`. Pass `formatter` for full-control override instead.
- `value` and the date reported via `onChanged` preserve `TZDateTime` zones (via `sameZoneDate`) — a caller passing a `package:timezone` value gets the same zone back, never silently re-anchored to local time.
- Keyboard: arrow keys move focus by one day (`ArrowUp`/`ArrowDown` by week), `Home`/`End` move within the focused row, `PageUp`/`PageDown` step the month, `Enter`/`Space` selects. Disabled cells are skipped, never landed on.
- At least one of `labelText`/`hintText` must be non-null — debug assertion.

---

## Common patterns

```dart
// 1. Bounded to today-or-later
LayrzDateInput(
  labelText: LayrzUiL10n.of(context).save,
  value: bookingDate,
  firstDay: DateTime.now(),
  errors: bookingDateErrors,
  onChanged: (value) {
    bookingDate = value;
    if (context.mounted) onChanged.call();
  },
)

// 2. Custom pattern
LayrzDateInput(
  labelText: 'Due date',
  value: dueDate,
  pattern: '%d/%m/%Y',
  onChanged: (value) => setState(() => dueDate = value),
)

// 3. With individually disabled dates
LayrzDateInput(
  labelText: 'Delivery date',
  value: deliveryDate,
  disabledDays: blackoutDates,
  onChanged: (value) => setState(() => deliveryDate = value),
)

// 4. Disabled field
LayrzDateInput(
  labelText: 'Locked date',
  value: fixedDate,
  disabled: true,
)
```

---

## Form conventions

- Guard async `onChanged` follow-ups with `if (context.mounted)`.
- Localize `labelText`/`hintText`/`helpTitleText`/`helpContentText` via `LayrzUiL10n.of(context)` when the string is a real product string.
- Pass `errors: <List<String>>` computed and owned by your own form validation — there is no `context.getErrors` in layrz_ui.
- Separate stacked inputs with `const SizedBox(height: 10)`.
- Keep the `pattern` string stable across the app for consistent date display; prefer `formatter` only when the display truly can't be expressed as a strftime pattern.
