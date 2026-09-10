# LayrzTimeInput — API Reference

Source: `lib/src/pickers/src/time/time_input.dart`
- `LayrzTimeInput` class

Model type source: `lib/src/pickers/src/models/time_of_day.dart`
- `LayrzTimeOfDay` class

Companion source (surface, not directly constructed by callers): `lib/src/pickers/src/time/time_surface.dart` (`LayrzTimeSurface`), `lib/src/pickers/src/shared/time_fields_panel.dart` (`LayrzPickersTimeFieldsPanel`).

---

## Examples

```dart
// Minimal
LayrzTimeInput(
  labelText: 'Departure time',
  value: departureTime,
  onChanged: (value) => setState(() => departureTime = value),
)

// With seconds
LayrzTimeInput(
  labelText: 'Precise time',
  value: preciseTime,
  showSeconds: true,
  onChanged: (value) => setState(() => preciseTime = value),
)

// 12-hour clock, custom pattern
LayrzTimeInput(
  labelText: 'Reminder',
  value: reminderTime,
  use24HourFormat: false,
  pattern: '%I:%M %p',
  onChanged: (value) => setState(() => reminderTime = value),
)

// Constructing a LayrzTimeOfDay
const midnight = LayrzTimeOfDay(hour: 0, minute: 0);
final fromDt = LayrzTimeOfDay.fromDateTime(DateTime.now());
```

---

## Constructor

```dart
const LayrzTimeInput({
  super.key,
  this.value,
  this.onChanged,
  this.labelText,
  this.hintText,
  this.isRequired = false,
  this.errors = const [],
  this.hideDetails = false,
  this.disabled = false,
  this.showSeconds = false,
  this.use24HourFormat = true,
  this.pattern = '%H:%M',
  this.formatter,
  this.controller,
  this.focusNode,
  this.dense = false,
  this.helpTitleText,
  this.helpContentText,
}) : assert(labelText != null || hintText != null, 'At least one of labelText or hintText must be non-null.');
```

```dart
// LayrzTimeOfDay
const LayrzTimeOfDay({required this.hour, required this.minute, this.second = 0})
  : assert(hour >= 0 && hour <= 23, ...),
    assert(minute >= 0 && minute <= 59, ...),
    assert(second >= 0 && second <= 59, ...);

factory LayrzTimeOfDay.fromDateTime(DateTime dateTime);
```

---

## Properties

### `LayrzTimeInput`

| Property | Type | Default | Notes |
|---|---|---|---|
| `value` | `LayrzTimeOfDay?` | `null` | The currently selected time. |
| `onChanged` | `ValueChanged<LayrzTimeOfDay>?` | `null` | Called with the drafted time once the user presses Save. |
| `labelText` | `String?` | `null` | Label displayed above the field. |
| `hintText` | `String?` | `null` | Placeholder shown when empty. |
| `isRequired` | `bool` | `false` | Whether the field is marked as required. |
| `errors` | `List<String>` | `[]` | Error messages displayed below the field. |
| `hideDetails` | `bool` | `false` | Whether to hide the error/help detail block. |
| `disabled` | `bool` | `false` | Whether the field is non-interactive. |
| `showSeconds` | `bool` | `false` | Whether the seconds field is shown, without layout reflow. |
| `use24HourFormat` | `bool` | `true` | Whether the hour field uses 24-hour form. |
| `pattern` | `String` | `'%H:%M'` | `strftime`-style pattern used to format `value` for display. |
| `formatter` | `String Function(LayrzTimeOfDay)?` | `null` | Full-control override for formatting `value`. |
| `controller` | `TextEditingController?` | `null` | Anchor field's text controller. |
| `focusNode` | `FocusNode?` | `null` | Anchor field's focus node. |
| `dense` | `bool` | `false` | Whether the field uses the dense density variant. |
| `helpTitleText` | `String?` | `null` | Title text for the help affordance tooltip. |
| `helpContentText` | `String?` | `null` | Content text for the help affordance tooltip. |

### `LayrzTimeOfDay`

| Property/Member | Type | Notes |
|---|---|---|
| `hour` | `int` | 24-hour form, `0`–`23`. Asserted in debug builds. |
| `minute` | `int` | `0`–`59`. Asserted. |
| `second` | `int` | `0`–`59`, defaults to `0`. Always carried, regardless of whether `showSeconds` displays it. |
| `LayrzTimeOfDay({required hour, required minute, second = 0})` | constructor | — |
| `LayrzTimeOfDay.fromDateTime(dateTime)` | factory | Discards date and timezone components. |
| `hour12` | `int` getter | `1`–`12`; both midnight and noon map to `12`. |
| `isPm` | `bool` getter | `true` when `hour >= 12`. |
| `copyWith({hour, minute, second})` | method | Returns a modified copy. |
| `compareTo(other)` / `<` `<=` `>` `>=` | `Comparable<LayrzTimeOfDay>` | Chronological ordering within a day (hour, then minute, then second). |

---

## Behavior notes

- **Composition**: composes `LayrzInputChrome` directly (D63), label/error text hoisted outside the chrome.
- **Container**: opens via `LayrzResponsiveModal.show` — dialog at `>= 960px`, `LayrzBottomSheet` below `isCompact`. Both branches carry a `LayrzPickerDialogHeader`.
- **Commit model — Cancel/Save (DESIGN-98).** Before DESIGN-98 this widget reported continuously: every field edit fired `onChanged` live with no discrete commit gesture at all (D75). DESIGN-98 retired that — editing a field now only updates the draft; `onChanged` fires exactly once, on Save. Cancel discards edits and reverts to `value`. There is no Clear action.
- **Save is always enabled**, unlike every other picker in this family. An unset `value` seeds the fields to midnight (`00:00`) rather than leaving them blank; midnight is itself a valid, committable time — there is no "has the user touched this" gate.
- **Digital-clock layout**: the surface renders big editable `HH : MM` digit boxes (plus optional `: SS`), each a bare chrome-free editable text box — not `LayrzNumberInput`, not `LayrzTextInput`. In 12-hour mode an AM/PM toggle renders below the digit row. No interval snapping. Each digit group accepts free typing while focused; the typed value clamps into range and reports only on blur/submit, not on every keystroke. Out-of-range typed input is clamped, not dropped.
- **Formatting**: house `strftime`-style formatter (`%H`, `%I`, `%M`, `%S`, `%p`, etc.), not `intl`. Migration continuity: `ThemedTimePicker`'s pattern strings carry over unchanged.
- **Keyboard navigation** (WCAG 2.1.1 Level A): each digit box accepts direct digit entry (digits only, two characters max) with normal caret movement. `Tab` moves hour → minute → (optional) second → meridiem in source order (Flutter's default focus traversal, no custom policy needed). No arrow-key up/down stepping on the digit boxes.
- **Validation vs. selection**: restricted/blacked-out time windows are out of scope for the picker — enforce via `errors`.
- **Migration from `ThemedTimePicker`**: the old clock/dial UI is gone; time entry is the digital-clock digit-box layout described above (an earlier revision briefly used `LayrzNumberInput` field rows — also gone). `use24HourFormat` default flipped from 12-hour to 24-hour. `pattern` carries over unchanged.
