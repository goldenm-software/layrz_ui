# LayrzMonthRangeInput — API Reference

Source: `lib/src/pickers/src/month/month_range_input.dart`
- `LayrzMonthRangeInput` class — line 44

Model: `lib/src/pickers/src/models/month_range.dart`
- `LayrzMonthRange` class — line 20

---

## Examples

```dart
// Arbitrary (default) multi-select
LayrzMonthRangeInput(
  labelText: 'Reporting months',
  arbitraryValue: months,
  onArbitraryChanged: (value) => setState(() => months = value),
)

// Consecutive (contiguous) range mode
LayrzMonthRangeInput(
  labelText: 'Fiscal quarter',
  consecutive: true,
  rangeValue: quarter,
  onRangeChanged: (value) => setState(() => quarter = value),
)

// Bounded selectable window, arbitrary mode
LayrzMonthRangeInput(
  labelText: 'Closed months',
  arbitraryValue: closedMonths,
  minimum: LayrzMonth(year: 2026, month: 1),
  maximum: LayrzMonth(year: 2026, month: 12),
  onArbitraryChanged: (value) => setState(() => closedMonths = value),
)

// Custom formatters for both modes
LayrzMonthRangeInput(
  labelText: 'Period',
  arbitraryValue: months,
  arbitraryFormatter: (list) => '${list.length} months',
  onArbitraryChanged: (value) => setState(() => months = value),
)

// Required field with errors
LayrzMonthRangeInput(
  labelText: 'Coverage',
  isRequired: true,
  consecutive: true,
  rangeValue: coverage,
  errors: coverage == null ? ['Coverage period is required'] : const [],
  onRangeChanged: (value) => setState(() => coverage = value),
)
```

---

## Constructor

```dart
const LayrzMonthRangeInput({
  super.key,
  this.consecutive = false,
  this.arbitraryValue = const [],
  this.rangeValue,
  this.onArbitraryChanged,
  this.onRangeChanged,
  this.labelText,
  this.hintText,
  this.isRequired = false,
  this.errors = const [],
  this.hideDetails = false,
  this.disabled = false,
  this.minimum,
  this.maximum,
  this.disabledMonths = const {},
  this.arbitraryFormatter,
  this.rangeFormatter,
  this.arbitraryPattern = '%b %Y',
  this.rangePattern = '%B %Y',
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
| `consecutive` | `bool` | `false` | Whether this widget operates in consecutive (contiguous) mode rather than arbitrary multi-select. |
| `arbitraryValue` | `List<LayrzMonth>` | `[]` | Currently selected months in arbitrary mode. Ignored when `consecutive` is `true`. |
| `rangeValue` | `LayrzMonthRange?` | `null` | Currently committed range in consecutive mode. Ignored when `consecutive` is `false`. |
| `onArbitraryChanged` | `ValueChanged<List<LayrzMonth>>?` | `null` | Called with the new sorted month list when the user presses Save in arbitrary mode. |
| `onRangeChanged` | `ValueChanged<LayrzMonthRange>?` | `null` | Called with the new range when the user presses Save in consecutive mode. |
| `labelText` | `String?` | `null` | The label text displayed above the field. One of `labelText`/`hintText` is required. |
| `hintText` | `String?` | `null` | Placeholder shown when empty. |
| `isRequired` | `bool` | `false` | Whether the field is marked as required. |
| `errors` | `List<String>` | `[]` | Error messages displayed below the field. |
| `hideDetails` | `bool` | `false` | Whether to hide the error/help detail block. |
| `disabled` | `bool` | `false` | Whether the field is non-interactive. |
| `minimum` | `LayrzMonth?` | `null` | Earliest selectable month, inclusive. |
| `maximum` | `LayrzMonth?` | `null` | Latest selectable month, inclusive. |
| `disabledMonths` | `Set<LayrzMonth>` | `{}` | Individually disabled months. **Ignored in consecutive mode.** |
| `arbitraryFormatter` | `String Function(List<LayrzMonth>)?` | `null` | Full-control override for formatting the arbitrary selection. Takes precedence over `arbitraryPattern`. |
| `rangeFormatter` | `String Function(LayrzMonthRange)?` | `null` | Full-control override for formatting the consecutive range. Takes precedence over `rangePattern`. |
| `arbitraryPattern` | `String` | `'%b %Y'` | `strftime`-style pattern for each month in the arbitrary comma-joined summary. |
| `rangePattern` | `String` | `'%B %Y'` | `strftime`-style pattern for each endpoint of the consecutive summary. |
| `controller` | `TextEditingController?` | `null` | The anchor field's text controller. Created and disposed internally if omitted. |
| `focusNode` | `FocusNode?` | `null` | The anchor field's focus node. Created and disposed internally if omitted. |
| `dense` | `bool` | `false` | Whether the field uses the dense density variant. |
| `helpTitleText` | `String?` | `null` | Title text for the help affordance tooltip. |
| `helpContentText` | `String?` | `null` | Content text for the help affordance tooltip. |

---

## `LayrzMonthRange` model

An immutable, always-valid, always-contiguous span between two `LayrzMonth` values. Models only the contiguous case — arbitrary mode uses `List<LayrzMonth>` instead.

| Member | Signature | Notes |
|---|---|---|
| `start` | `final LayrzMonth start` | First month of the range, inclusive. |
| `end` | `final LayrzMonth end` | Last month of the range, inclusive. |
| `LayrzMonthRange(...)` | `const LayrzMonthRange({required LayrzMonth start, required LayrzMonth end})` | Documented caller contract: `start` must not be after `end` (not a runtime assertion). |
| `LayrzMonthRange.fromUnordered` | `factory LayrzMonthRange.fromUnordered(LayrzMonth a, LayrzMonth b)` | Normalizing constructor; swaps `a`/`b` if necessary so `start <= end`. |
| `lengthInMonths` | `int get lengthInMonths` | Inclusive span in whole months; a single-month range returns `1`, not `0`. |
| `contains` | `bool contains(LayrzMonth month)` | Whether `month` falls within the range, inclusive of both endpoints. |
| `toList` | `List<LayrzMonth> toList()` | Every month in the range, inclusive, in chronological order. |
| `copyWith` | `LayrzMonthRange copyWith({LayrzMonth? start, LayrzMonth? end})` | Returns a modified copy. |

---

## Behavior notes

- **Commit model:** staged-with-Save, in both modes. Cancel/Save live inside the panel visible from the first frame. Involuntary close (Escape, barrier tap) discards the draft; reopening always starts clean from `arbitraryValue`/`rangeValue`.
- **Container:** opens through `LayrzResponsiveModal.show` — a centered `LayrzDialog` at `>= 960px`, a `LayrzBottomSheet` below that. Both carry a `LayrzPickerDialogHeader` above the month grid.
- **Arbitrary-mode overflow:** past 4 selected months, the anchor summary collapses from a comma-joined list to a localized count. This threshold is flagged for maintainer review, not a firm ruling — do not treat `4` as load-bearing in generated code.
- **Formatting:** month names resolve through the house `strftime` formatter's `%B`/`%b` directives in both modes, localized via `LayrzUiL10n` — never a hardcoded English switch statement.
- **Keyboard navigation (WCAG 2.1.1 Level A):** shares the month-grid contract with `LayrzMonthInput` — arrow keys move focus, `PageUp`/`PageDown` change the displayed year, `Enter`/`Space` selects/adjusts the focused month per whichever mode is active.
- **Selection vs. validation:** anything shaped like "is this selection valid" (e.g. a maximum span in consecutive mode) is a caller validation concern surfaced via `errors`, not something the widget encodes.
