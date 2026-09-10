# LayrzDateTimeInput — API Reference

Source: `lib/src/pickers/src/datetime/datetime_input.dart`
- `LayrzDateTimeInput` class

Enum source: `lib/src/pickers/src/datetime/datetime_presentation.dart`
- `LayrzDateTimeInputPresentation` enum (deprecated, inert)

Companion source (surface, not directly constructed by callers): `lib/src/pickers/src/datetime/datetime_surface.dart` (`LayrzDateTimeSurface`).

---

## Examples

```dart
// Minimal
LayrzDateTimeInput(
  labelText: 'Appointment',
  value: appointment,
  onChanged: (value) => setState(() => appointment = value),
)

// Bounded date part + seconds shown
LayrzDateTimeInput(
  labelText: 'Scheduled send',
  value: scheduledAt,
  firstDay: DateTime.now(),
  showSeconds: true,
  onChanged: (value) => setState(() => scheduledAt = value),
)

// 12-hour clock
LayrzDateTimeInput(
  labelText: 'Reminder',
  value: reminderAt,
  use24HourFormat: false,
  onChanged: (value) => setState(() => reminderAt = value),
)
```

---

## Constructor

```dart
const LayrzDateTimeInput({
  super.key,
  this.value,
  this.onChanged,
  @Deprecated('Ignored as of DESIGN-49 ...')
  LayrzDateTimeInputPresentation presentation = LayrzDateTimeInputPresentation.tabbed,
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
| `value` | `DateTime?` | `null` | The currently selected datetime. |
| `onChanged` | `ValueChanged<DateTime>?` | `null` | Called with the combined date and time once the user presses Save. Never called before the date part is set; the time part may be the seeded midnight default. |
| `presentation` | `LayrzDateTimeInputPresentation` | `.tabbed` | **`@Deprecated`, fully inert as of DESIGN-98.** Accepted for migration continuity only — see the enum section below. |
| `labelText` | `String?` | `null` | Label displayed above the field. |
| `hintText` | `String?` | `null` | Placeholder shown when empty. |
| `isRequired` | `bool` | `false` | Whether the field is marked as required. |
| `errors` | `List<String>` | `[]` | Error messages displayed below the field. |
| `hideDetails` | `bool` | `false` | Whether to hide the error/help detail block. |
| `disabled` | `bool` | `false` | Whether the field is non-interactive. |
| `firstDay` | `DateTime?` | `null` | Earliest selectable date, inclusive. |
| `lastDay` | `DateTime?` | `null` | Latest selectable date, inclusive. |
| `disabledDays` | `Set<DateTime>` | `{}` | Individually disabled dates. |
| `firstDayOfWeek` | `int` | `DateTime.monday` | Which weekday starts each week in the date grid. |
| `showWeekNumbers` | `bool` | `true` | Whether the date grid's ISO week-number gutter renders. |
| `showSeconds` | `bool` | `false` | Whether the seconds field is shown on the Time tab. |
| `use24HourFormat` | `bool` | `true` | Whether the hour field uses 24-hour form. |
| `pattern` | `String` | `'%Y-%m-%d %H:%M'` | `strftime`-style pattern used to format `value` for display. |
| `formatter` | `String Function(DateTime)?` | `null` | Full-control override for formatting `value`, takes precedence over `pattern`. |
| `controller` | `TextEditingController?` | `null` | Anchor field's text controller. |
| `focusNode` | `FocusNode?` | `null` | Anchor field's focus node. |
| `dense` | `bool` | `false` | Whether the field uses the dense density variant. |
| `helpTitleText` | `String?` | `null` | Title text for the help affordance tooltip. |
| `helpContentText` | `String?` | `null` | Content text for the help affordance tooltip. |

At least one of `labelText`/`hintText` must be non-null; `firstDayOfWeek` must be within `DateTime.monday..DateTime.sunday` (both asserted).

---

## `LayrzDateTimeInputPresentation` enum

**Deprecated and fully inert as of DESIGN-98.** Both values compile and are accepted, but change nothing — `LayrzDateTimeSurface` accepts and ignores the parameter entirely. Kept only so an existing caller passing `presentation:` explicitly does not hit a breaking removal with no migration signal.

| Value | Historical meaning | Current effect |
|---|---|---|
| `.tabbed` (default) | Date grid and time fields sat behind two selectable tab headers in the same panel. | None — identical to `.stepped`. |
| `.stepped` | Date grid shown first; selecting a date advanced to a separate time step. | None — identical to `.tabbed`. |

---

## Behavior notes

- **Composition**: composes `LayrzInputChrome` directly (D63), label/error text hoisted outside the chrome.
- **Container**: opens via `LayrzResponsiveModal.show` — dialog at `>= 960px`, `LayrzBottomSheet` below `isCompact`. Both branches carry a `LayrzPickerDialogHeader` above a `LayrzTabView` with two tabs, "Date" and "Time".
- **Why tabs, not a stacked scroll**: an earlier revision stacked the date grid and time panel in one scrollable column; that read as visually heavy once the dialog header was added on top, so the current surface splits them into two `LayrzTabView` tabs instead. This is a separate, later layout decision from the deprecated `presentation` (tabbed/stepped) split above — that split was about *separate screens*, this is about tabs within one screen.
- **Commit model — in-panel Save, despite being single-valued.** Committing a `DateTime` requires both the date and time parts to be genuinely set, which is a two-part coordinated commit exactly like a range's two endpoints. Committing on the date tap (as `LayrzDateInput` does) would close the drawer before the user ever reached the time fields.
- **Midnight is a valid, committable value.** The time part seeds from `value`'s own time when `value` is non-null; when `value` is `null`, the time part seeds to midnight (`00:00`) rather than staying unset. Save's enablement follows the **date** part alone — it never checks whether the time was independently touched. This is DESIGN-98/D76 behavior, reversing an earlier D75 "no midnight default" ruling.
- **Formatting**: house `strftime`-style formatter; pattern strings carry over unchanged from `ThemedDateTimePicker`/`ThemedDateTimeSteppedPicker`.
- **Timezone handling**: the committed value is built via `sameZoneDateTime`, threaded through `value` (or, when `value` is `null`, through whichever date the surface reports first).
- **Keyboard navigation** (WCAG 2.1.1 Level A): Date tab uses the same arrow/`Home`/`End`/`PageUp`/`PageDown`/`Enter`/`Space` contract as `LayrzDateInput`. Time tab uses the same digit-box contract as `LayrzTimeInput` (`Tab` moves hour → minute → optional second → meridiem). The two tabs themselves are switched via the `LayrzTabView` tab headers.
- **Validation vs. selection**: date-part bounds (`firstDay`/`lastDay`/`disabledDays`) are supported directly. Restricted time windows are a validation concern via `errors`.
- **Migration from `ThemedDateTimePicker`/`ThemedDateTimeSteppedPicker`**: both collapse into `LayrzDateTimeInput`. `presentation` still accepts either value but is fully inert — there is no separate widget class for the stepped variant and no remaining tabbed/stepped layout distinction. The time part now seeds to midnight when unset and Save gates on the date part alone (reverses the D75-era "Save disabled until both parts are genuinely set" behavior). `pattern` carries over unchanged.

## Discrepancy note (wiki vs. source, resolved by code)

`datetime_input.dart`'s own class doc still describes an older "single scrollable surface" layout and a "no midnight default" commit model — both stale relative to the current `datetime_surface.dart`, whose class doc and the wiki page agree on the **Date/Time tab layout with a midnight-default, date-gated Save**. This reference follows `datetime_surface.dart` (the live surface implementation) and the wiki, since `datetime_input.dart`'s comment was not updated after the DESIGN-98/tab-view change.
