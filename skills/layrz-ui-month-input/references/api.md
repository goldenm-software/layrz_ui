# LayrzMonthInput — API Reference

Source: `lib/src/pickers/src/month/month_input.dart`
- `LayrzMonthInput` class — line 30

Model: `lib/src/pickers/src/models/month.dart`
- `LayrzMonth` class — line 14

---

## Examples

```dart
// Minimal
LayrzMonthInput(
  labelText: 'Billing period',
  value: month,
  onChanged: (value) => setState(() => month = value),
)

// Bounded selectable range
LayrzMonthInput(
  labelText: 'Reporting month',
  value: month,
  minimum: LayrzMonth(year: 2025, month: 1),
  maximum: LayrzMonth(year: 2026, month: 12),
  onChanged: (value) => setState(() => month = value),
)

// Individually disabled months
LayrzMonthInput(
  labelText: 'Maintenance window',
  value: month,
  disabledMonths: {LayrzMonth(year: 2026, month: 12)},
  onChanged: (value) => setState(() => month = value),
)

// Custom formatter
LayrzMonthInput(
  labelText: 'Period',
  value: month,
  formatter: (m) => '${m.month.toString().padLeft(2, '0')}/${m.year}',
  onChanged: (value) => setState(() => month = value),
)

// Required field with errors
LayrzMonthInput(
  labelText: 'Period',
  isRequired: true,
  value: month,
  errors: month == null ? ['Period is required'] : const [],
  onChanged: (value) => setState(() => month = value),
)
```

---

## Constructor

```dart
const LayrzMonthInput({
  super.key,
  this.value,
  this.onChanged,
  this.labelText,
  this.hintText,
  this.isRequired = false,
  this.errors = const [],
  this.hideDetails = false,
  this.disabled = false,
  this.minimum,
  this.maximum,
  this.disabledMonths = const {},
  this.formatter,
  this.controller,
  this.focusNode,
  this.dense = false,
  this.helpTitleText,
  this.helpContentText,
}) : assert(labelText != null || hintText != null, 'At least one of labelText or hintText must be non-null.');
```

---

## Properties

| Property | Type | Default | Notes |
|---|---|---|---|
| `value` | `LayrzMonth?` | `null` | The currently selected month. |
| `onChanged` | `ValueChanged<LayrzMonth>?` | `null` | Called with the drafted month once the user presses Save. Never fires on a mere tap. |
| `labelText` | `String?` | `null` | The label text displayed above the field. One of `labelText`/`hintText` is required. |
| `hintText` | `String?` | `null` | Placeholder shown when empty. |
| `isRequired` | `bool` | `false` | Whether the field is marked as required. |
| `errors` | `List<String>` | `[]` | Error messages displayed below the field. |
| `hideDetails` | `bool` | `false` | Whether to hide the error/help detail block. |
| `disabled` | `bool` | `false` | Whether the field is non-interactive. |
| `minimum` | `LayrzMonth?` | `null` | Earliest selectable month, inclusive. |
| `maximum` | `LayrzMonth?` | `null` | Latest selectable month, inclusive. |
| `disabledMonths` | `Set<LayrzMonth>` | `{}` | Individually disabled months. |
| `formatter` | `String Function(LayrzMonth)?` | `null` | Full-control override for formatting `value`. Defaults to `'%B %Y'` (e.g. "September 2026") via the house `strftime` formatter when omitted. |
| `controller` | `TextEditingController?` | `null` | The anchor field's text controller. Created and disposed internally if omitted. |
| `focusNode` | `FocusNode?` | `null` | The anchor field's focus node. Created and disposed internally if omitted. |
| `dense` | `bool` | `false` | Whether the field uses the dense density variant. |
| `helpTitleText` | `String?` | `null` | Title text for the help affordance tooltip. |
| `helpContentText` | `String?` | `null` | Content text for the help affordance tooltip. |

---

## `LayrzMonth` model

An immutable `(year, month)` pair — not `DateTime` — with no day, hour, or timezone component.

| Member | Signature | Notes |
|---|---|---|
| `year` | `final int year` | Four-digit calendar year, e.g. `2026`. |
| `month` | `final int month` | `1` (January) through `12` (December); asserted in debug builds. |
| `LayrzMonth(...)` | `const LayrzMonth({required int year, required int month})` | Primary constructor. |
| `LayrzMonth.fromDateTime` | `factory LayrzMonth.fromDateTime(DateTime dateTime)` | Discards day, time-of-day, and timezone. |
| `toDateTime()` | `DateTime toDateTime()` | First day of the month at midnight (non-timezone-aware). |
| `copyWith` | `LayrzMonth copyWith({int? year, int? month})` | Returns a modified copy. |
| `next` | `LayrzMonth get next` | Following month; rolls the year over at December→January. |
| `previous` | `LayrzMonth get previous` | Preceding month; rolls the year back at January→December. |
| `compareTo` | `int compareTo(LayrzMonth other)` | Chronological ordering, year first then month. |
| `<`, `<=`, `>`, `>=` | operators | Chronological comparison operators. |

---

## Behavior notes

- **Commit model:** staged-with-Save. A month tap only updates the panel's in-progress draft — `onChanged` fires exactly once, on Save. Escape, a barrier tap, and Cancel all discard the draft. There is no Clear action; the `actions` row is Cancel/Save only, since a single month has nothing to reset independently of Cancel.
- **Container:** opens through `LayrzResponsiveModal.show` — a centered `LayrzDialog` at `>= 960px`, a `LayrzBottomSheet` below that (`context.isCompact`). Both carry a `LayrzPickerDialogHeader` (the field's `labelText` as title, plus a close "X") above the month grid.
- **Reopen behavior:** the grid always re-seeds from the current `value` on open, never from a year the user had merely browsed to in a previous, cancelled session.
- **Formatting:** month names resolve through the house `strftime` formatter's `%B`/`%b` directives, localized via `LayrzUiL10n` — never a hardcoded English switch statement.
- **Keyboard navigation (WCAG 2.1.1 Level A):** arrow keys move focus between month cells, `PageUp`/`PageDown` change the displayed year, `Enter`/`Space` selects the focused month.
- **Selection vs. validation:** `minimum`/`maximum`/`disabledMonths` are selection-surface concerns handled by the widget. Anything about whether an already-chosen month is acceptable is a validation concern for the caller via `errors`.
