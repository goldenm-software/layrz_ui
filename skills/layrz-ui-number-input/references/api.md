# LayrzNumberInput — API Reference

Source: `lib/src/inputs/src/number/number_input.dart`, `lib/src/inputs/src/number/decimal_separator.dart`

- `LayrzNumberInput` class — line 53
- `LayrzDecimalSeparator` enum — `decimal_separator.dart` line 6

---

## Examples

```dart
// Basic bounded quantity
LayrzNumberInput(
  labelText: 'Quantity',
  value: quantity,
  minimum: 0,
  maximum: 999,
  onChanged: (value) => quantity = value,
)

// Currency, comma separator, custom display format
LayrzNumberInput(
  labelText: 'Price',
  value: price,
  decimalSeparator: .comma,
  format: (n) => n.toStringAsFixed(2),
  prefixText: 'S/',
  onChanged: (value) => price = value,
)

// Fractional step, limited precision
LayrzNumberInput(
  labelText: 'Weight (kg)',
  value: weight,
  step: 0.1,
  maximumDecimalDigits: 2,
  onChanged: (value) => weight = value,
)

// No step buttons — plain numeric field
LayrzNumberInput(
  labelText: 'Year',
  value: year,
  hideStepButtons: true,
  maximumDecimalDigits: 0,
  onChanged: (value) => year = value,
)

// Suffix unit + custom formatters override
LayrzNumberInput(
  labelText: 'Distance',
  value: distance,
  suffixText: 'km',
  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
  onChanged: (value) => distance = value,
)

// Read-only display of a computed number
LayrzNumberInput(
  labelText: 'Total',
  value: total,
  readOnly: true,
)
```

---

## Constructor

```dart
const LayrzNumberInput({
  super.key,
  this.value,
  this.onChanged,
  this.decimalSeparator = LayrzDecimalSeparator.dot,
  this.format,
  this.minimum,
  this.maximum,
  this.step = 1,
  this.maximumDecimalDigits = 4,
  this.hideStepButtons = false,
  this.prefixIcon,
  this.prefix,
  this.prefixText,
  this.onPrefixTap,
  this.suffixIcon,
  this.suffix,
  this.suffixText,
  this.onSuffixTap,
  this.labelText,
  this.hintText,
  this.isRequired = false,
  this.disabled = false,
  this.readOnly = false,
  this.errors = const [],
  this.hideDetails = false,
  this.helperText,
  this.helpTitleText,
  this.helpContentText,
  this.onFocusChanged,
  this.onTap,
  this.onSubmit,
  this.controller,
  this.focusNode,
  this.dense = false,
  this.autofocus = false,
  this.inputFormatters,
}) : assert(
       maximumDecimalDigits >= 0 && maximumDecimalDigits <= 15,
       'maximumDecimalDigits must be between 0 and 15 inclusive.',
     ),
     assert(
       (prefixIcon == null || prefix == null) &&
           (prefix == null || prefixText == null) &&
           (prefixIcon == null || prefixText == null),
       'At most one of prefixIcon, prefix, or prefixText may be non-null.',
     ),
     assert(
       (suffixIcon == null || suffix == null) &&
           (suffix == null || suffixText == null) &&
           (suffixIcon == null || suffixText == null),
       'At most one of suffixIcon, suffix, or suffixText may be non-null.',
     );
```

---

## Properties

| Property | Type | Default | Notes |
|---|---|---|---|
| `value` | `num?` | `null` | Current value. `null` renders empty — "no value yet", not `0`. |
| `onChanged` | `ValueChanged<num?>?` | `null` | Fires `null` on empty/unparseable input, the parsed `num` otherwise. Never fires from internal formatting. |
| `decimalSeparator` | `LayrzDecimalSeparator` | `.dot` | Explicit; does not respond to device locale. |
| `format` | `String Function(num)?` | `null` | Formats the parsed value for display, e.g. `(n) => n.toStringAsFixed(2)`. Plain callback, not `intl`'s `NumberFormat`. |
| `minimum` | `num?` | `null` | Disables the decrement button at this bound. Does not block typed input. |
| `maximum` | `num?` | `null` | Disables the increment button at this bound. Does not block typed input. |
| `step` | `num` | `1` | Amount changed per step-button press or arrow key; may be fractional. |
| `maximumDecimalDigits` | `int` | `4` | Must be 0–15 (debug assertion). |
| `hideStepButtons` | `bool` | `false` | When `true`, renders a plain text field — prefix/suffix stay, `+`/`−` disappear. |
| `prefixIcon` | `IconData?` | `null` | Rendered after the `−` button. Mutually exclusive with `prefix`/`prefixText`. |
| `prefix` | `Widget?` | `null` | Mutually exclusive with `prefixIcon`/`prefixText`. |
| `prefixText` | `String?` | `null` | Mutually exclusive with `prefixIcon`/`prefix`. |
| `onPrefixTap` | `VoidCallback?` | `null` | Fires on prefix tap; ignored when `disabled`. |
| `suffixIcon` | `IconData?` | `null` | Rendered before the `+` button. Mutually exclusive with `suffix`/`suffixText`. |
| `suffix` | `Widget?` | `null` | Mutually exclusive with `suffixIcon`/`suffixText`. |
| `suffixText` | `String?` | `null` | Mutually exclusive with `suffixIcon`/`suffix`. |
| `onSuffixTap` | `VoidCallback?` | `null` | Fires on suffix tap; ignored when `disabled`. |
| `labelText` | `String?` | `null` | Label above the field. |
| `hintText` | `String?` | `null` | Placeholder shown when empty. |
| `isRequired` | `bool` | `false` | Renders a red `*` beside the label. |
| `disabled` | `bool` | `false` | Not editable; step buttons are hidden entirely. |
| `readOnly` | `bool` | `false` | Not editable; step buttons are disabled but still visible. |
| `errors` | `List<String>` | `[]` | Caller-owned validation messages. |
| `hideDetails` | `bool` | `false` | Hides the error/helper block below the field. |
| `helperText` | `String?` | `null` | Hidden whenever `errors` is non-empty. |
| `helpTitleText` | `String?` | `null` | Title of the help-affordance tooltip. |
| `helpContentText` | `String?` | `null` | Body of the help-affordance tooltip. |
| `onFocusChanged` | `ValueChanged<bool>?` | `null` | Fires on focus gain/loss. |
| `onTap` | `VoidCallback?` | `null` | Fires on tap. |
| `onSubmit` | `ValueChanged<String>?` | `null` | Fires on submit (e.g. Enter). |
| `controller` | `TextEditingController?` | `null` | Caller-owned if supplied (never disposed); created+disposed internally otherwise. |
| `focusNode` | `FocusNode?` | `null` | Same disposal contract as `controller`. |
| `dense` | `bool` | `false` | Drops internal padding one ramp, identically on every viewport. |
| `autofocus` | `bool` | `false` | Requests focus on first build. |
| `inputFormatters` | `List<TextInputFormatter>?` | `null` | When `null`, the built-in numeric formatter applies (uses `decimalSeparator`/`minimum`/`maximumDecimalDigits`). When set, **fully replaces** it — the caller owns all keystroke filtering. |

There is **no** `keyboardType` parameter (the field's own numeric formatter owns keystroke
filtering unless `inputFormatters` is overridden), and no `hidePrefixSuffixActions` — the real name
is `hideStepButtons`.

---

## `LayrzDecimalSeparator` enum

Source: `lib/src/inputs/src/number/decimal_separator.dart`

| Value | Format | Notes |
|---|---|---|
| `.dot` | `"3.14"` | Default. |
| `.comma` | `"3,14"` | Explicit choice, independent of device locale. |

---

## Behavior notes

- **Keyboard stepping**: while focused, `ArrowUp`/`ArrowDown` step by `step`; `PageUp`/`PageDown` step by `step * 10`. Both respect `minimum`/`maximum` clamping and are disabled while `readOnly`/`disabled`.
- **Clamp vs. validate**: step buttons and keyboard stepping always clamp to `minimum`/`maximum`; typed keyboard input is never blocked by those bounds. If out-of-range typed values are unacceptable, surface that via `errors`.
- **Formatter override is total**: supplying `inputFormatters` removes the built-in numeric enforcement entirely, including the `decimalSeparator` and `maximumDecimalDigits` behavior — you re-implement whatever subset you need.
- **`format` vs. `decimalSeparator` order**: `format` runs first to produce the display string, then the decimal separator substitution (`.` → `,` when `.comma`) is applied on top of the formatter's output.
- **Composition**: composes `LayrzInputChrome` + `LayrzEditableField` directly (like `LayrzTextInput` does), not `LayrzTextInput` itself — an internal detail, but relevant if you were expecting `LayrzTextInput`'s full parameter surface (e.g. `shortcut`, `actions`) to be present here; it is not.
- **Value contract**: `null` is a legitimate, common state (empty field) — never coerce it to `0` before passing back to this widget's `value` parameter unless `0` is actually what you mean.
