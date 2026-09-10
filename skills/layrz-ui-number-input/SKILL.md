---
name: layrz-ui-number-input
description: Use LayrzNumberInput in a layrz_ui Flutter widget. Apply when adding numeric entry — configurable min/maximum bounds, step (+/−) buttons, decimal precision and separator (.dot/.comma), or a custom display formatter.
---

> **Dart syntax:** This library requires Dart ≥ 3.13. Use dot shorthand for all enum values (e.g. `.dot`, `.comma`) — never the fully-qualified form (`LayrzDecimalSeparator.dot`).

> **Full constructor and property reference:** read `references/api.md` in this skill's directory.

---

## When to use

- Any numeric field: quantity, price, percentage, latitude/longitude, duration in units.
- Fields that benefit from `+`/`−` step buttons (counters, stock quantities, ratios).
- Fields needing a locale-independent decimal separator choice (`.dot` vs `.comma`) that stays stable regardless of device locale.
- **Do not use** for free text, even numeric-looking text like phone numbers or postal codes that should never be parsed as a `num` — use `LayrzTextInput` with `keyboardType: TextInputType.number` instead.
- **Do not use** for duration/time-span values — there is a dedicated duration input elsewhere in the design system; `LayrzNumberInput` only ever produces a `num?`.

---

## Minimal usage

```dart
LayrzNumberInput(
  labelText: 'Quantity',
  value: quantity,
  errors: quantityErrors,
  onChanged: (value) {
    quantity = value;
    if (context.mounted) onChanged.call();
  },
)
```

---

## Key behaviors

- **Value type is `num?`** — `null` means "no value yet", not a distinct state like `0`. `onChanged` fires `null` on empty/unparseable input, or the parsed `num` on valid input.
- **Step buttons clamp, typed input does not** — `minimum`/`maximum` disable the relevant `+`/`−` button at the bound, but a user can still type a value outside those bounds; validate it yourself via `errors`.
- **`decimalSeparator` is explicit, not locale-driven** — `.dot` (`"3.14"`) or `.comma` (`"3,14"`); it never reacts to device locale, so parsing stays stable across locale changes.
- **`inputFormatters` fully replaces** the built-in numeric keystroke filter when supplied — you then own all keystroke filtering, including interaction with `decimalSeparator`/`maximumDecimalDigits`.
- **`format` is a plain callback**, not `package:intl`'s `NumberFormat` — `String Function(num)`, e.g. `(n) => n.toStringAsFixed(2)`.
- `hideStepButtons: true` renders a plain field (prefix/suffix intact, no `+`/`−`); `disabled: true` also hides the buttons; `readOnly: true` disables (but does not hide) them.
- Arrow Up/Down and Page Up/Down keys step the value by `step` / `step * 10` respectively while focused — this is built in, not something you wire up.
- Composes the shared chrome directly (same primitive `LayrzTextInput` uses) rather than wrapping `LayrzTextInput` itself — this only matters if you're extending the widget, not for normal consumption.

---

## Common patterns

```dart
// 1. Bounded quantity with step buttons
LayrzNumberInput(
  labelText: 'Quantity',
  value: quantity,
  minimum: 0,
  maximum: 999,
  onChanged: (value) => quantity = value,
)

// 2. Currency with comma separator and a formatter
LayrzNumberInput(
  labelText: 'Price',
  value: price,
  decimalSeparator: .comma,
  format: (n) => n.toStringAsFixed(2),
  prefixText: 'S/',
  onChanged: (value) => price = value,
)

// 3. Fine-grained fractional step
LayrzNumberInput(
  labelText: 'Weight (kg)',
  value: weight,
  step: 0.1,
  maximumDecimalDigits: 2,
  onChanged: (value) => weight = value,
)

// 4. Plain numeric field, no step buttons
LayrzNumberInput(
  labelText: 'Year',
  value: year,
  hideStepButtons: true,
  maximumDecimalDigits: 0,
  onChanged: (value) => year = value,
)
```

---

## `LayrzDecimalSeparator` enum

| Value | Format | Notes |
|---|---|---|
| `.dot` | `"3.14"` | Default. |
| `.comma` | `"3,14"` | Use for locales where comma is the decimal mark; does not follow device locale automatically. |

---

## Form conventions

- Guard async `onChanged` follow-ups with `if (context.mounted)` before calling the parent callback.
- Pass `errors: <List<String>>` from your own bounds/format validation — typed input is never blocked by `minimum`/`maximum`, so out-of-range values must be caught here, not assumed impossible.
- Set `maximumDecimalDigits` to match the real precision the backing field accepts (default 4) rather than leaving it at the default for integer-only fields — pair with `hideStepButtons`/`step` as needed.
- Localize `labelText`/`hintText`/`helperText` via `LayrzUiL10n.of(context)` for real product strings.
