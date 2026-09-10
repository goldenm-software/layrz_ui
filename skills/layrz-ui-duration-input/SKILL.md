---
name: layrz-ui-duration-input
description: Use LayrzDurationInput in a layrz_ui Flutter widget. Apply when picking a Duration value via a day/hour/minute/second picker — configurable visibleUnits, .long/.short summary format, and a dialog (desktop, Cancel/Reset/Save) or bottom sheet (mobile, live-commit) surface.
---

> **Dart syntax:** This library requires Dart ≥ 3.13. Use dot shorthand for all enum values (e.g. `.long`, `.short`, `.day`) — never the fully-qualified form (`LayrzDurationFormat.long`).

> **Full constructor and property reference:** read `references/api.md` in this skill's directory.

---

## When to use

- Picking a time span: a timeout, a shift length, a polling interval, a reminder delay.
- Displays a humanized summary in a read-only field (e.g. "2 days, 3 hours"); tapping opens a picker with one numeric field per visible unit.
- **Do not use** for a specific point in time — use a date/time picker instead (`LayrzDatePicker`, `LayrzTimeInput`, etc.).
- **Do not use** for a plain numeric quantity with no time meaning — use `LayrzNumberInput` instead.

---

## Minimal usage

```dart
LayrzDurationInput(
  labelText: 'Timeout',
  value: timeoutDuration,
  onChanged: (value) {
    setState(() => timeoutDuration = value);
  },
)
```

---

## Key behaviors

- `visibleUnits` (default: day, hour, minute, second — all four) controls which fields appear; must be non-empty (enforced by assertion). Year/month/week are not supported — they are not fixed-length and cannot map to `Duration`.
- Unit bounds: day is unbounded, hour is 0–23, minute/second are 0–59. Unit fields are integers only — no decimals.
- **Desktop and mobile keep genuinely different commit models**:
  - **Desktop (dialog, ≥960px)**: draft-then-Save. Field edits update an in-dialog draft only; `onChanged` fires exactly once, on Save. Cancel discards the draft. Reset is a separate "clear and close" gesture — it zeroes the draft, reports it immediately, and closes in one action.
  - **Mobile (bottom sheet, <960px)**: live-commit. Every field edit forwards straight to `onChanged` with no buffered draft; Reset is the sheet's only closing action.
- Summary formatting is controlled by `format`: `.long` (default, e.g. "2 days, 3 hours") or `.short` (e.g. "2d 3h"). A non-null `value` equal to `Duration.zero` shows a zero reading of the smallest visible unit (e.g. "0s"), staying visually distinct from "no value".
- There is no `readOnly` parameter — the field is always non-editable by nature (opens a picker on tap); it exposes no prefix/suffix slot parameters at all.

---

## Common patterns

```dart
// 1. Short-form summary
LayrzDurationInput(
  labelText: 'Interval',
  format: .short,
  value: interval,
  onChanged: (value) => setState(() => interval = value),
)

// 2. Restrict visible units (hours + minutes only)
LayrzDurationInput(
  labelText: 'Shift length',
  visibleUnits: const {LayrzDurationUnit.hour, LayrzDurationUnit.minute},
  value: shiftLength,
  onChanged: (value) => setState(() => shiftLength = value),
)

// 3. Required, with error
LayrzDurationInput(
  labelText: 'Reminder delay',
  isRequired: true,
  value: reminderDelay,
  errors: reminderDelay == null ? const ['A delay is required'] : const [],
  onChanged: (value) => setState(() => reminderDelay = value),
)

// 4. Disabled
LayrzDurationInput(
  labelText: 'Locked timeout',
  value: const Duration(minutes: 30),
  disabled: true,
)
```

---

## Form conventions

- Use `LayrzUiL10n.of(context)` for `labelText`/`hintText` — never hardcode strings.
- Pass `errors: [...]` for validation state — never `context.getErrors`.
- Prefer `.long` for forms where clarity matters more than density; `.short` for compact summaries (tables, chips).
- Separate stacked duration inputs with `SizedBox(height: 10)`.
