# LayrzDateRangeInput — API Reference

Source: `lib/src/pickers/src/date/date_range_input.dart`
- `LayrzDateRangeInput` class

Model type source: `lib/src/pickers/src/models/date_range.dart`
- `LayrzDateRange` class

Companion source (surface, not directly constructed by callers): `lib/src/pickers/src/date/date_range_surface.dart` (`LayrzDateRangeSurface`).

---

## Examples

```dart
// Minimal
LayrzDateRangeInput(
  labelText: 'Booking window',
  value: bookingWindow,
  onChanged: (value) => setState(() => bookingWindow = value),
)

// Bounded, with disabled days
LayrzDateRangeInput(
  labelText: 'Report period',
  value: reportPeriod,
  firstDay: DateTime(2020),
  disabledDays: holidayDates,
  onChanged: (value) => setState(() => reportPeriod = value),
)

// Custom pattern + formatter override
LayrzDateRangeInput(
  labelText: 'Custom range',
  value: customRange,
  formatter: (range) => '${range.lengthInDays} days',
  onChanged: (value) => setState(() => customRange = value),
)

// Building a LayrzDateRange from two possibly-reversed dates
final range = LayrzDateRange.fromUnordered(tappedA, tappedB);

// Checking containment
if (range.contains(candidateDate)) { /* ... */ }
```

---

## Constructor

```dart
const LayrzDateRangeInput({
  super.key,
  this.value,
  this.onChanged,
  this.labelText,
  this.hintText,
  this.isRequired = false,
  this.errors = const [],
  this.hideDetails = false,
  this.disabled = false,
  this.firstDay,
  this.lastDay,
  this.disabledDays = const {},
  this.firstDayOfWeek = DateTime.monday,
  this.showWeekNumbers = true,
  this.pattern = '%Y-%m-%d',
  this.formatter,
  this.controller,
  this.focusNode,
  this.dense = false,
  this.helpTitleText,
  this.helpContentText,
}) : assert(labelText != null || hintText != null, 'At least one of labelText or hintText must be non-null.');
```

```dart
// LayrzDateRange
const LayrzDateRange({required this.start, required this.end});
factory LayrzDateRange.fromUnordered(DateTime a, DateTime b);
```

---

## Properties

### `LayrzDateRangeInput`

| Property | Type | Default | Notes |
|---|---|---|---|
| `value` | `LayrzDateRange?` | `null` | The currently committed range. |
| `onChanged` | `ValueChanged<LayrzDateRange>?` | `null` | Called with the new range when the user presses Save. |
| `labelText` | `String?` | `null` | Label displayed above the field. |
| `hintText` | `String?` | `null` | Placeholder shown when empty. |
| `isRequired` | `bool` | `false` | Whether the field is marked as required. |
| `errors` | `List<String>` | `[]` | Error messages displayed below the field. |
| `hideDetails` | `bool` | `false` | Whether to hide the error/help detail block. |
| `disabled` | `bool` | `false` | Whether the field is non-interactive. |
| `firstDay` | `DateTime?` | `null` | Earliest selectable date, inclusive. |
| `lastDay` | `DateTime?` | `null` | Latest selectable date, inclusive. |
| `disabledDays` | `Set<DateTime>` | `{}` | Individually disabled dates. |
| `firstDayOfWeek` | `int` | `DateTime.monday` | Which weekday starts each week. |
| `showWeekNumbers` | `bool` | `true` | Whether the ISO week-number gutter renders. |
| `pattern` | `String` | `'%Y-%m-%d'` | `strftime`-style pattern used to format each endpoint. |
| `formatter` | `String Function(LayrzDateRange)?` | `null` | Full-control override for formatting `value`. |
| `controller` | `TextEditingController?` | `null` | Anchor field's text controller. |
| `focusNode` | `FocusNode?` | `null` | Anchor field's focus node. |
| `dense` | `bool` | `false` | Whether the field uses the dense density variant. |
| `helpTitleText` | `String?` | `null` | Title text for the help affordance tooltip. |
| `helpContentText` | `String?` | `null` | Content text for the help affordance tooltip. |

### `LayrzDateRange`

| Property/Member | Type | Notes |
|---|---|---|
| `start` | `DateTime` | Inclusive start. Non-nullable. |
| `end` | `DateTime` | Inclusive end. Non-nullable. |
| `LayrzDateRange({required start, required end})` | constructor | `const`-compatible; ordering (`start <= end`) is a documented caller contract, not runtime-asserted. |
| `LayrzDateRange.fromUnordered(a, b)` | factory | Swaps `a`/`b` if necessary so `start` never falls after `end`. Use this when assembling from two independent taps. |
| `lengthInDays` | `int` getter | Inclusive span in whole days; same-day range returns `1`, not `0`. |
| `contains(DateTime date)` | `bool` method | Compares calendar-day fields only (year/month/day); time-of-day is ignored. |
| `copyWith({start, end})` | method | Returns a modified copy. |

---

## Behavior notes

- **Composition**: composes `LayrzInputChrome` directly (D63). Label/error text hoisted outside the chrome so the chrome's box stays the anchor's rect.
- **Container**: opens via `LayrzResponsiveModal.show` — dialog at `>= 960px`, `LayrzBottomSheet` below `isCompact`. Both branches carry a `LayrzPickerDialogHeader`.
- **Commit model**: in-panel Cancel/Clear/Save, visible from the first frame. The rule that decides Save-vs-commit-on-tap across this whole family is "one atomic value vs. multiple coordinated parts" — a range is the clearest multi-part case (two endpoints). An involuntary close (tap-outside, Escape) discards the draft; reopening always starts clean from `value`.
- **Selection model — endpoint-adjust** (retires layrz_theme's old "interior locked, only endpoints deselectable" model): empty → anchor → complete-with-auto-swap → re-tap adjusts nearest edge → interior tap visibly rejected (persistently non-interactive styling, not only after a rejected tap) → outside tap extends the nearer endpoint. All feedback is colour/opacity/cursor only (D15), never a geometry change.
- **Visuals**: a completed range renders as a flat, continuous `primary`-colored bar behind the row, rounded only at true start/end, square where the range continues into an adjacent week. Day numerals switch to the primary color's contrasting foreground. This was an explicit ruling favoring a bar over per-cell circles.
- **The `LayrzDateRange` type**: replaces the old layrz_theme `List<DateTime>` (runtime-asserted length 0 or 2) with a non-nullable, always-ordered pair. There is no library-wide generic range type — this class is scoped to date ranges.
- **Formatting**: each endpoint formats through the house `strftime`-style formatter, joined with the localized range separator (`l10n.dateTimePickerRangeSeparator`). Pattern carries over unchanged from `ThemedDateRangePicker`.
- **Timezone handling**: endpoints are constructed via `sameZoneDate`.
- **Keyboard navigation** (WCAG 2.1.1 Level A): same day-grid contract as `LayrzDateInput` — arrow keys, `Home`/`End`, `PageUp`/`PageDown`, `Enter`/`Space` select/adjust per the endpoint-adjust rules.
- **Validation vs. selection**: range-length limits are out of scope for the picker — enforce via `errors`.
- **Migration from `ThemedDateRangePicker`**: value type changed from a runtime-asserted `List<DateTime>` to the typed, non-nullable `LayrzDateRange`. Selection model changed from "interior locked" to endpoint-adjust — a genuine behavior change, not just a rename. `pattern` carries over unchanged.
