---
name: layrz-ui-month-input
description: Use LayrzMonthInput in a layrz_ui Flutter widget. Apply when adding a single month+year selection field — opens a dialog/bottom-sheet month grid with year navigation, Cancel/Save commit.
---

> **Dart syntax:** This library requires Dart ≥ 3.13. Use dot shorthand for all enum values (e.g. `.someValue`) — never the fully-qualified form (`SomeEnum.someValue`).

> **Full constructor and property reference:** read `references/api.md` in this skill's directory.

---

## When to use

- A single month+year field with no day component — billing periods, report months, subscription cycles.
- Any case where a `DateTime`'s incidental day-of-month would be a footgun — `LayrzMonth` has no day field to accidentally rely on.
- **Do not use** for a full calendar date — use `LayrzDateInput` instead.
- **Do not use** for multiple months or a month span — use `LayrzMonthRangeInput` instead.

---

## Minimal usage

```dart
LayrzMonthInput(
  labelText: 'Billing period',
  value: month,
  errors: monthErrors,
  onChanged: (value) {
    month = value;
    if (context.mounted) onChanged.call();
  },
)
```

---

## Key behaviors

- **Staged with Save — not commit-on-tap.** Tapping a month cell in the grid only updates an in-progress draft; `onChanged` fires exactly once, when the user presses Save. Cancel, Escape, and a barrier tap all discard the draft and close with nothing reported.
- **No Clear action.** The panel's `actions` row is Cancel/Save only — a single month has nothing to reset to empty independently of Cancel.
- Reopening always re-seeds the grid from the current `value`, never from a year the user had merely browsed to without selecting.
- `value` (and the range's endpoints) are `LayrzMonth` — a pure `(year, month)` pair, not `DateTime`. Use `LayrzMonth.fromDateTime(dateTime)` to convert in, and `.toDateTime()` to convert out.
- `minimum`/`maximum`/`disabledMonths` constrain the selectable surface; anything shaped like "is this already-chosen month valid" is a caller-side validation concern surfaced via `errors`, not a widget concept.
- Default display format is fixed to `'%B %Y'` (e.g. "September 2026") resolved through the house `strftime` formatter, localized via `LayrzUiL10n` — there is no `pattern` parameter, only `formatter` for full override.
- `disabled: true` makes the field fully non-interactive; tapping it does nothing.
- On viewports `>= 960px` the picker opens as a centered dialog; below that it opens as a bottom sheet — both automatic via `context.isCompact`, never something you branch on yourself.

---

## Common patterns

```dart
// 1. Constrained to the last 12 months
LayrzMonthInput(
  labelText: 'Reporting month',
  value: reportMonth,
  minimum: LayrzMonth.fromDateTime(DateTime.now()).copyWith(
    month: DateTime.now().month - 11,
  ),
  maximum: LayrzMonth.fromDateTime(DateTime.now()),
  errors: reportMonthErrors,
  onChanged: (value) {
    reportMonth = value;
    if (context.mounted) onChanged.call();
  },
)

// 2. Custom formatter (short form)
LayrzMonthInput(
  labelText: 'Period',
  value: period,
  formatter: (month) => '${month.month}/${month.year}',
  onChanged: (value) => setState(() => period = value),
)

// 3. Disabled, pre-filled
LayrzMonthInput(
  labelText: 'Locked period',
  value: LayrzMonth(year: 2026, month: 1),
  disabled: true,
)
```

---

## Form conventions

- Guard async `onChanged` follow-ups with `if (context.mounted)` before calling the parent callback.
- Localize `labelText`/`hintText`/`helpTitleText`/`helpContentText` via `LayrzUiL10n.of(context)` for real product strings.
- Pass `errors: <List<String>>` from your own form validation state — layrz_ui inputs have no `context.getErrors`; the caller owns and computes the list.
- Separate stacked inputs with `SizedBox(height: 10)` (or the host app's own spacing tokens).
- At least one of `labelText`/`hintText` is required — an assertion enforces this at construction.
