# LayrzDateInput — API Reference

Source: `lib/src/pickers/src/date/date_input.dart`
- `LayrzDateInput` class

Companion source (surface, not directly constructed by callers): `lib/src/pickers/src/date/date_surface.dart` (`LayrzDateSurface`).

---

## Examples

```dart
// Minimal
LayrzDateInput(
  labelText: 'Start date',
  value: startDate,
  onChanged: (value) => setState(() => startDate = value),
)

// Bounded range with disabled days
LayrzDateInput(
  labelText: 'Delivery date',
  value: deliveryDate,
  firstDay: DateTime.now(),
  lastDay: DateTime.now().add(const Duration(days: 90)),
  disabledDays: blackoutDates,
  onChanged: (value) => setState(() => deliveryDate = value),
)

// Custom weekday start + no week numbers
LayrzDateInput(
  labelText: 'Report date',
  value: reportDate,
  firstDayOfWeek: DateTime.sunday,
  showWeekNumbers: false,
  onChanged: (value) => setState(() => reportDate = value),
)

// Full-control formatter override
LayrzDateInput(
  labelText: 'Event date',
  value: eventDate,
  formatter: (date) => '${date.day} de ${monthName(date.month)}',
  onChanged: (value) => setState(() => eventDate = value),
)
```

---

## Constructor

```dart
const LayrzDateInput({
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
}) : assert(
       labelText != null || hintText != null,
       'At least one of labelText or hintText must be non-null.',
     ),
     assert(
       firstDayOfWeek >= DateTime.monday && firstDayOfWeek <= DateTime.sunday,
       'firstDayOfWeek must be between DateTime.monday (1) and DateTime.sunday (7), got $firstDayOfWeek.',
     );
```

---

## Properties

| Property | Type | Default | Notes |
|---|---|---|---|
| `value` | `DateTime?` | `null` | The currently selected date. |
| `onChanged` | `ValueChanged<DateTime>?` | `null` | Called with the drafted date once the user presses Save. |
| `labelText` | `String?` | `null` | Label displayed above the field. |
| `hintText` | `String?` | `null` | Placeholder shown when empty and no `labelText` is set. |
| `isRequired` | `bool` | `false` | Whether the field is marked as required. |
| `errors` | `List<String>` | `[]` | Error messages displayed below the field. |
| `hideDetails` | `bool` | `false` | Whether to hide the error/help detail block. |
| `disabled` | `bool` | `false` | Whether the field is non-interactive. |
| `firstDay` | `DateTime?` | `null` | Earliest selectable date, inclusive. `null` = no lower bound. |
| `lastDay` | `DateTime?` | `null` | Latest selectable date, inclusive. `null` = no upper bound. |
| `disabledDays` | `Set<DateTime>` | `{}` | Individually disabled dates, in addition to `firstDay`/`lastDay`. |
| `firstDayOfWeek` | `int` | `DateTime.monday` | Which `DateTime` weekday constant starts each week. Asserted within `monday..sunday`. |
| `showWeekNumbers` | `bool` | `true` | Whether the ISO week-number gutter renders. |
| `pattern` | `String` | `'%Y-%m-%d'` | `strftime`-style pattern used to format `value` for display, when `formatter` is not supplied. |
| `formatter` | `String Function(DateTime)?` | `null` | Full-control override for formatting `value`, takes precedence over `pattern`. |
| `controller` | `TextEditingController?` | `null` | Anchor field's text controller. Created/disposed internally if omitted. |
| `focusNode` | `FocusNode?` | `null` | Anchor field's focus node. Created/disposed internally if omitted. |
| `dense` | `bool` | `false` | Whether the field uses the dense density variant. |
| `helpTitleText` | `String?` | `null` | Title text for the help affordance tooltip. |
| `helpContentText` | `String?` | `null` | Content text for the help affordance tooltip. |

At least one of `labelText`/`hintText` must be non-null; `firstDayOfWeek` must be within `DateTime.monday..DateTime.sunday` (both asserted).

---

## Behavior notes

- **Composition**: composes `LayrzInputChrome` directly (D63) — never wraps or extends `LayrzTextInput`. Label and footer (error text) are hoisted into a `Column` around the chrome, so the chrome's own box stays the anchor's rect.
- **Container**: opens via `LayrzResponsiveModal.show` — a centered `LayrzDialog` at `>= 960px`, a `LayrzBottomSheet` below `context.isCompact`. Both branches carry a `LayrzPickerDialogHeader` (label as title, plus a close "X") above the day grid.
- **Commit model — Cancel/Save (DESIGN-98).** Historically this widget committed immediately on tap with no Save step (D75); DESIGN-98 retired that. Tapping a day now only updates the draft; `onChanged` fires exactly once, on Save. Cancel discards the draft. Escape and barrier tap both behave like Cancel. There is no Clear action.
- **Formatting**: house `strftime`-style formatter (`lib/src/formatting/`) — Python `datetime` directives (`%Y %y %m %d %H %I %M %S %B %b %A %a %p %j %%`), not `intl`/`DateFormat`. Malformed/unsupported directives pass through literally rather than throwing. Migration continuity: `ThemedDatePicker`'s existing `pattern: '%Y-%m-%d'` strings carry over unchanged.
- **Timezone handling**: `value` and every date reported via `onChanged` are constructed via `sameZoneDate`, so a `TZDateTime` round-trips in the same zone rather than being re-anchored to the host's local zone.
- **Keyboard navigation** (WCAG 2.1.1 Level A): arrow keys move focus by one day (`ArrowUp`/`ArrowDown` by week), `Home`/`End` move to the first/last day of the focused row, `PageUp`/`PageDown` step the displayed month, `Enter`/`Space` selects the focused day. Disabled cells are skipped by navigation, never landed on inert.
- **Validation vs. selection**: `firstDay`/`lastDay`/`disabledDays` restrict *which* dates are selectable (a selection-surface concern, supported directly). "Is this already-chosen value valid" business-rule checks are a validation concern owned by the caller via `errors`.
- **Migration from `ThemedDatePicker`**: `*Picker` suffix retired. Composition changed from a Material dialog to the shared dialog/bottom-sheet container — no dialog-only variant. `pattern` carries over unchanged (the one continuity in an otherwise-breaking migration). There is no `padding` parameter — every input uses the same padding regardless of viewport.
