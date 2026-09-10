# LayrzDateTimeRangeInput — API Reference

Source: `lib/src/pickers/src/datetime/datetime_range_input.dart`
- `LayrzDateTimeRangeInput` class

Companion source (surface, not directly constructed by callers): `lib/src/pickers/src/datetime/datetime_range_surface.dart` (`LayrzDateTimeRangeSurface`).

Uses `LayrzDateRange` internally (`lib/src/pickers/src/models/date_range.dart`) to track the date-range draft, but the public API reports plain `DateTime start`/`end`, not `LayrzDateRange`.

---

## Examples

```dart
// Minimal
LayrzDateTimeRangeInput(
  labelText: 'Event window',
  startValue: eventStart,
  endValue: eventEnd,
  onChanged: (start, end) => setState(() {
    eventStart = start;
    eventEnd = end;
  }),
)

// Bounded date part + seconds shown
LayrzDateTimeRangeInput(
  labelText: 'Maintenance window',
  startValue: windowStart,
  endValue: windowEnd,
  firstDay: DateTime.now(),
  showSeconds: true,
  onChanged: (start, end) => setState(() {
    windowStart = start;
    windowEnd = end;
  }),
)

// Custom formatter override
LayrzDateTimeRangeInput(
  labelText: 'Custom window',
  startValue: start,
  endValue: end,
  formatter: (s, e) => '${e.difference(s).inHours}h window',
  onChanged: (start, end) => setState(() {}),
)
```

---

## Constructor

```dart
const LayrzDateTimeRangeInput({
  super.key,
  this.startValue,
  this.endValue,
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
  this.showSeconds = false,
  this.use24HourFormat = true,
  this.pattern = '%Y-%m-%d %H:%M',
  this.formatter,
  this.controller,
  this.focusNode,
  this.dense = false,
  this.helpTitleText,
  this.helpContentText,
}) : assert(labelText != null || hintText != null, 'At least one of labelText or hintText must be non-null.'),
     assert(
       firstDayOfWeek >= DateTime.monday && firstDayOfWeek <= DateTime.sunday,
       'firstDayOfWeek must be between DateTime.monday (1) and DateTime.sunday (7), got $firstDayOfWeek.',
     );
```

---

## Properties

| Property | Type | Default | Notes |
|---|---|---|---|
| `startValue` | `DateTime?` | `null` | The currently committed start datetime. |
| `endValue` | `DateTime?` | `null` | The currently committed end datetime. |
| `onChanged` | `void Function(DateTime start, DateTime end)?` | `null` | Called with the new pair when the user presses Save. |
| `labelText` | `String?` | `null` | Label displayed above the field. |
| `hintText` | `String?` | `null` | Placeholder shown when empty. |
| `isRequired` | `bool` | `false` | Whether the field is marked as required. |
| `errors` | `List<String>` | `[]` | Error messages displayed below the field. |
| `hideDetails` | `bool` | `false` | Whether to hide the error/help detail block. |
| `disabled` | `bool` | `false` | Whether the field is non-interactive. |
| `firstDay` | `DateTime?` | `null` | Earliest selectable date, inclusive. |
| `lastDay` | `DateTime?` | `null` | Latest selectable date, inclusive. |
| `disabledDays` | `Set<DateTime>` | `{}` | Individually disabled dates. |
| `firstDayOfWeek` | `int` | `DateTime.monday` | Which weekday starts each week in the day grid. |
| `showWeekNumbers` | `bool` | `true` | Whether the day grid's ISO week-number gutter renders. |
| `showSeconds` | `bool` | `false` | Whether the seconds fields are shown. |
| `use24HourFormat` | `bool` | `true` | Whether the hour fields use 24-hour form. |
| `pattern` | `String` | `'%Y-%m-%d %H:%M'` | `strftime`-style pattern used to format each endpoint. |
| `formatter` | `String Function(DateTime start, DateTime end)?` | `null` | Full-control override for formatting the pair. |
| `controller` | `TextEditingController?` | `null` | Anchor field's text controller. |
| `focusNode` | `FocusNode?` | `null` | Anchor field's focus node. |
| `dense` | `bool` | `false` | Whether the field uses the dense density variant. |
| `helpTitleText` | `String?` | `null` | Title text for the help affordance tooltip. |
| `helpContentText` | `String?` | `null` | Content text for the help affordance tooltip. |

At least one of `labelText`/`hintText` must be non-null; `firstDayOfWeek` must be within `DateTime.monday..DateTime.sunday` (both asserted).

---

## Behavior notes

- **Composition**: composes `LayrzInputChrome` directly (D63), label/error text hoisted outside the chrome.
- **Container**: opens via `LayrzResponsiveModal.show` — dialog at `>= 960px`, `LayrzBottomSheet` below `isCompact`. Both branches carry a `LayrzPickerDialogHeader` above a `LayrzTabView` with two tabs: Tab 1 is the range calendar, Tab 2 holds *both* the Start and End time clusters together. Splitting into tabs keeps each tab's content within the dialog's default height — stacking the calendar plus both time clusters in one scroll ran taller than the dialog's default max height before any date was even selected.
- **Container history (DESIGN-98)**: the maintainer explicitly ruled a shared drawer/sheet-then-dialog container here (over a dedicated dialog) for uniformity across the whole range-widget batch.
- **Commit model — in-panel Cancel/Clear/Save.** Coordinates four parts (start date, start time, end date, end time) inside a single Save. `onChanged` fires exactly once, on Save, with both complete `DateTime` endpoints. Clear resets the in-progress date range to empty (available once a selection exists); Cancel discards the whole draft.
- **Midnight is a valid, committable value.** Each endpoint's time part seeds from `startValue`/`endValue`'s own time when non-null, else midnight (`00:00`). Save's enablement follows the date range's completeness alone (`LayrzDateTimeRangeSurfaceState.canSave => _draft.isComplete`) — never gated on whether either time was independently touched. This is DESIGN-98/D76 behavior, reversing an earlier D75 "no midnight default" ruling.
- **Range selection**: the date grid uses the same endpoint-adjust contiguous-range model as `LayrzDateRangeInput` — empty → anchor → complete-with-auto-swap → re-tap adjusts nearest edge → interior tap visibly rejected → outside tap extends the nearer endpoint. Contiguous-only. Visually identical bar rendering to `LayrzDateRangeInput`.
- **Formatting**: each endpoint formats through the house `strftime`-style formatter, joined with the localized range separator. Pattern strings carry over unchanged from `ThemedDateTimeRangePicker`.
- **Timezone handling**: committed endpoints are built via `sameZoneDateTime`.
- **Keyboard navigation** (WCAG 2.1.1 Level A): same day-grid contract as `LayrzDateRangeInput` on the Date tab, same digit-box contract as `LayrzTimeRangeInput` on the Time tab (both clusters render together there). Switching tabs is via the `LayrzTabView` tab headers.
- **Validation vs. selection**: range-length limits and restricted time windows are out of scope for the picker surface — enforce via `errors`.
- **Migration from `ThemedDateTimeRangePicker`**: an unset time part now seeds to midnight and Save gates on date-range completeness alone (reverses the D75-era "Save disabled until every part is genuinely set" behavior). Selection model changed to endpoint-adjust. `pattern` carries over unchanged.
