---
name: layrz-ui-date-range-input
description: Use LayrzDateRangeInput in a layrz_ui Flutter widget. Apply when adding a start/end date-span field — day-grid dialog/sheet with endpoint-adjust selection, in-panel Cancel/Clear/Save, and the typed LayrzDateRange value.
---

> **Dart syntax:** This library requires Dart ≥ 3.13. Use dot shorthand for all enum values (e.g. `.someValue`) — never the fully-qualified form (`SomeEnum.someValue`).

> **Full constructor and property reference:** read `references/api.md` in this skill's directory.

---

## When to use

- Any start/end date-span field: booking window, report period, filter range.
- Range-length limits (e.g. "no more than 30 days") are **not** enforced by the picker — validate via `errors` in the caller.
- **Do not use** for a single date — use `LayrzDateInput` instead.
- **Do not use** when time-of-day also matters for both endpoints — use `LayrzDateTimeRangeInput` instead.
- **Do not use** for a non-consecutive (arbitrary) multi-date selection — this widget is contiguous-only; `LayrzMonthRangeInput` is the only widget in the family offering non-consecutive selection, and only for months.

---

## Minimal usage

```dart
LayrzDateRangeInput(
  labelText: LayrzUiL10n.of(context).save,
  value: bookingWindow,
  onChanged: (value) {
    bookingWindow = value;
    if (context.mounted) onChanged.call();
  },
)
```

---

## Key behaviors

- `value` is a `LayrzDateRange?` — an immutable, non-nullable `(start, end)` pair, always ordered (`start <= end`). Build one from two possibly-reversed taps with `LayrzDateRange.fromUnordered(a, b)`; the plain constructor takes ordering as a caller contract.
- **In-panel Cancel/Clear/Save**, visible from the first frame. `onChanged` fires exactly once, on Save, with the completed `LayrzDateRange`. Clear resets the in-progress selection to empty (only enabled once a selection exists). An involuntary close (Escape, barrier tap) discards the draft; reopening always starts clean from `value`.
- **Endpoint-adjust selection model**: empty → tap sets the anchor; anchor → second tap completes the range (auto-swapping if the second tap lands before the anchor); complete → re-tapping either endpoint adjusts that edge, the other stays fixed; complete → tapping an interior cell is visibly rejected (styled persistently non-interactive); complete → tapping outside the range extends the nearer endpoint.
- Visual: a completed range renders as one unbroken `primary`-colored bar, rounded only at true start/end — not per-cell circles; endpoints are not visually distinguished from interior days.
- `firstDayOfWeek` defaults to `DateTime.monday`; `disabledDays`/`firstDay`/`lastDay` restrict selectable dates, same as `LayrzDateInput`.
- Display text formats each endpoint with the house `strftime`-style `pattern` (default `'%Y-%m-%d'`), joined by the localized range separator; `formatter` overrides fully.
- Endpoints preserve `TZDateTime` zones via `sameZoneDate`.
- At least one of `labelText`/`hintText` must be non-null — debug assertion.

---

## Common patterns

```dart
// 1. Bounded to the next 90 days
LayrzDateRangeInput(
  labelText: 'Booking window',
  value: bookingWindow,
  firstDay: DateTime.now(),
  lastDay: DateTime.now().add(const Duration(days: 90)),
  errors: bookingWindowErrors,
  onChanged: (value) {
    bookingWindow = value;
    if (context.mounted) onChanged.call();
  },
)

// 2. Assembling from two independently-picked dates
final range = LayrzDateRange.fromUnordered(pickedA, pickedB);

// 3. Custom pattern
LayrzDateRangeInput(
  labelText: 'Report period',
  value: reportPeriod,
  pattern: '%d/%m/%Y',
  onChanged: (value) => setState(() => reportPeriod = value),
)
```

---

## Form conventions

- Guard async `onChanged` follow-ups with `if (context.mounted)`.
- Localize `labelText`/`hintText`/`helpTitleText`/`helpContentText` via `LayrzUiL10n.of(context)`.
- Pass `errors: <List<String>>` computed and owned by your own form validation — there is no `context.getErrors` in layrz_ui.
- Enforce any range-length business rule (min/max span) yourself and surface it through `errors`; the picker never rejects a range on length.
- Separate stacked inputs with `const SizedBox(height: 10)`.
