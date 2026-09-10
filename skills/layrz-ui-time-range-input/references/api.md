# LayrzTimeRangeInput — API Reference

Source: `lib/src/pickers/src/time/time_range_input.dart`
- `LayrzTimeRangeInput` class

Model type source: `lib/src/pickers/src/models/time_of_day.dart`
- `LayrzTimeOfDay` class (see `layrz-ui-time-input`'s api.md for its full member table)

Companion source (surface, not directly constructed by callers): `lib/src/pickers/src/time/time_range_surface.dart` (`LayrzTimeRangeSurface`).

---

## Examples

```dart
// Minimal
LayrzTimeRangeInput(
  labelText: 'Shift window',
  startValue: shiftStart,
  endValue: shiftEnd,
  onChanged: (start, end) => setState(() {
    shiftStart = start;
    shiftEnd = end;
  }),
)

// With seconds
LayrzTimeRangeInput(
  labelText: 'Precise window',
  startValue: preciseStart,
  endValue: preciseEnd,
  showSeconds: true,
  onChanged: (start, end) => setState(() {
    preciseStart = start;
    preciseEnd = end;
  }),
)

// 12-hour clock, custom pattern
LayrzTimeRangeInput(
  labelText: 'Quiet hours',
  startValue: quietStart,
  endValue: quietEnd,
  use24HourFormat: false,
  pattern: '%I:%M %p',
  onChanged: (start, end) => setState(() {
    quietStart = start;
    quietEnd = end;
  }),
)
```

---

## Constructor

```dart
const LayrzTimeRangeInput({
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

---

## Properties

| Property | Type | Default | Notes |
|---|---|---|---|
| `startValue` | `LayrzTimeOfDay?` | `null` | The currently committed start time. |
| `endValue` | `LayrzTimeOfDay?` | `null` | The currently committed end time. |
| `onChanged` | `void Function(LayrzTimeOfDay start, LayrzTimeOfDay end)?` | `null` | Called with the new pair when the user presses Save. |
| `labelText` | `String?` | `null` | Label displayed above the field. |
| `hintText` | `String?` | `null` | Placeholder shown when empty. |
| `isRequired` | `bool` | `false` | Whether the field is marked as required. |
| `errors` | `List<String>` | `[]` | Error messages displayed below the field. |
| `hideDetails` | `bool` | `false` | Whether to hide the error/help detail block. |
| `disabled` | `bool` | `false` | Whether the field is non-interactive. |
| `showSeconds` | `bool` | `false` | Whether the seconds fields are shown. |
| `use24HourFormat` | `bool` | `true` | Whether the hour fields use 24-hour form. |
| `pattern` | `String` | `'%H:%M'` | `strftime`-style pattern used to format each endpoint. |
| `formatter` | `String Function(LayrzTimeOfDay start, LayrzTimeOfDay end)?` | `null` | Full-control override for formatting the pair. |
| `controller` | `TextEditingController?` | `null` | Anchor field's text controller. |
| `focusNode` | `FocusNode?` | `null` | Anchor field's focus node. |
| `dense` | `bool` | `false` | Whether the field uses the dense density variant. |
| `helpTitleText` | `String?` | `null` | Title text for the help affordance tooltip. |
| `helpContentText` | `String?` | `null` | Content text for the help affordance tooltip. |

---

## Behavior notes

- **Composition**: composes `LayrzInputChrome` directly (D63), label/error text hoisted outside the chrome.
- **Container**: opens via `LayrzResponsiveModal.show` — dialog at `>= 960px`, `LayrzBottomSheet` below `isCompact`. Both branches carry a `LayrzPickerDialogHeader` above the Start/End clusters.
- **Commit model — in-panel Cancel/Save.** Carries a Cancel/Save footer despite being built from two single-time field clusters rather than a grid — the "one atomic value vs. multiple coordinated parts" rule applies (a start time and an end time are two coordinated parts). `onChanged` fires exactly once, on Save, with both `start` and `end`. An involuntary close (Escape, barrier tap) discards the draft; reopening starts clean from `startValue`/`endValue`.
- **Midnight is a valid value; Save is always reachable.** An unset `startValue`/`endValue` seeds its cluster to midnight (`00:00`) rather than leaving it blank; there is no gate on Save requiring either cluster to have been touched first. This reverses D75's original "no silent default, Save disabled until touched" ruling (superseded by D76). Saving without touching either cluster commits `00:00`–`00:00` as a genuine, intentional value — the same way the old layrz_theme picker's `9:00`–`17:00` default worked, just with a different default pair.
- **Time entry**: same digital-clock digit-box layout as `LayrzTimeInput`, rendered once for Start and once for End: big editable `HH : MM` (plus `: SS` when `showSeconds`) digit boxes, with an AM/PM toggle below each cluster in 12-hour mode — no clock, dial, or spinner. No interval snapping. Each digit box clamps out-of-range typed input on blur/submit, not on every keystroke.
- **Formatting**: each endpoint formats through the house `strftime`-style formatter, joined with the localized range separator. Pattern strings carry over unchanged from `ThemedTimeRangePicker`.
- **Keyboard navigation** (WCAG 2.1.1 Level A): same digit-box contract as `LayrzTimeInput`, applied to both clusters — each box accepts direct digit entry (clamped on blur/submit), `Tab` moves hour → minute → (optional) second → meridiem → the next cluster in source order.
- **Validation vs. selection**: whether `end` must be after `start`, and any restricted time windows, are validation concerns owned by the caller via `errors` — not enforced or encoded by the widget.
- **Migration from `ThemedTimeRangePicker`**: the `9:00`–`17:00` default is gone; an untouched range now defaults to `00:00`–`00:00` and is saveable as-is. The old clock/dial UI is gone; time entry is the digital-clock digit-box layout described above. `pattern` carries over unchanged.
