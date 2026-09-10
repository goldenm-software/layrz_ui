# LayrzDurationInput — API Reference

Source: `lib/src/inputs/src/duration/duration_input.dart` (+ `duration_picker_panel.dart`, `duration_format.dart`, `duration_unit.dart`)
- `LayrzDurationInput` class — line 158
- `LayrzDurationFormat` enum — `duration_format.dart`, line 14
- `LayrzDurationUnit` enum — `duration_unit.dart`, line 6

> **Note:** the wiki page for this widget (`wiki/Widgets/LayrzDurationInput.md`) is largely a stale
> pre-implementation design sketch (`LDurationUnit`, humanization library, `readOnly` parameter,
> etc.) that does not match the shipped API. This reference describes the actual, shipped source —
> code wins.

---

## Examples

```dart
// Basic duration input, all four units
LayrzDurationInput(
  labelText: 'Timeout',
  value: timeout,
  onChanged: (value) => setState(() => timeout = value),
)

// Short-form summary ("2d 3h" instead of "2 days, 3 hours")
LayrzDurationInput(
  labelText: 'Interval',
  format: .short,
  value: interval,
  onChanged: (value) => setState(() => interval = value),
)

// Only hour + minute fields visible
LayrzDurationInput(
  labelText: 'Shift length',
  visibleUnits: const {LayrzDurationUnit.hour, LayrzDurationUnit.minute},
  value: shiftLength,
  onChanged: (value) => setState(() => shiftLength = value),
)

// Required with validation error
LayrzDurationInput(
  labelText: 'Reminder delay',
  isRequired: true,
  value: delay,
  errors: delay == null ? const ['A delay is required'] : const [],
  onChanged: (value) => setState(() => delay = value),
)

// Disabled
LayrzDurationInput(
  labelText: 'Locked timeout',
  value: const Duration(minutes: 30),
  disabled: true,
)

// With help tooltip
LayrzDurationInput(
  labelText: 'Poll interval',
  helpTitleText: 'Poll interval',
  helpContentText: 'How often the device reports.',
  value: pollInterval,
  onChanged: (value) => setState(() => pollInterval = value),
)
```

---

## Constructor

```dart
LayrzDurationInput({
  super.key,
  this.value,
  this.onChanged,
  this.visibleUnits = _kDefaultVisibleUnits, // {day, hour, minute, second}
  this.format = LayrzDurationFormat.long,
  this.labelText,
  this.hintText,
  this.isRequired = false,
  this.errors = const [],
  this.hideDetails = false,
  this.disabled = false,
  this.controller,
  this.focusNode,
  this.dense = false,
  this.helpTitleText,
  this.helpContentText,
}) : assert(
       visibleUnits.isNotEmpty,
       'visibleUnits must not be empty.',
     );
```

Note: not `const` — the constructor is a plain (non-const) constructor because the default `visibleUnits` value is a top-level `const` set constant, not an inline literal.

---

## Properties

| Property | Type | Default | Notes |
|---|---|---|---|
| `value` | `Duration?` | `null` | Currently selected duration. `null` shows empty anchor text. |
| `onChanged` | `ValueChanged<Duration?>?` | `null` | Fires when the duration changes (edit or reset). Not called if the picker closes with no change. |
| `visibleUnits` | `Set<LayrzDurationUnit>` | `{day, hour, minute, second}` | Which fields appear in the picker and summary. Must be non-empty. |
| `format` | `LayrzDurationFormat` | `.long` | Summary text format. See enum table below. |
| `labelText` | `String?` | `null` | Label above the field. |
| `hintText` | `String?` | `null` | Placeholder shown when the field is empty. |
| `isRequired` | `bool` | `false` | Renders a red `*` beside the label. |
| `errors` | `List<String>` | `[]` | Rendered below the field. |
| `hideDetails` | `bool` | `false` | Hides the error message block. |
| `disabled` | `bool` | `false` | Field is not interactive. |
| `controller` | `TextEditingController?` | `null` | Internal one created/disposed when omitted. |
| `focusNode` | `FocusNode?` | `null` | Internal one created/disposed when omitted. |
| `dense` | `bool` | `false` | `false`: 14px padding compact / 10px regular. `true`: 10px compact / 6px regular. |
| `helpTitleText` | `String?` | `null` | Title of the two-part help tooltip. |
| `helpContentText` | `String?` | `null` | Content of the two-part help tooltip. |

There is no `readOnly`, `prefixIcon`, `suffixIcon`, or `label` widget parameter — the field exposes
no prefix/suffix slots at all (the affordance icon is an external sibling, not a slot).

---

## `LayrzDurationFormat` enum

| Value | Example | Description |
|---|---|---|
| `.long` | `"2 days, 3 hours"` | Fully spelled-out, `", "`-joined. Default — preserves the summary this widget rendered before the enum existed. |
| `.short` | `"2d 3h"` | Abbreviated (no space between number and unit), joined with a single space. |

## `LayrzDurationUnit` enum

| Value | Range | Description |
|---|---|---|
| `.day` | unbounded | 24-hour increment. |
| `.hour` | 0–23 | Computed as `duration.inHours % 24` when filled from a stored `Duration`. |
| `.minute` | 0–59 | Computed as `duration.inMinutes % 60`. |
| `.second` | 0–59 | Computed as `duration.inSeconds % 60`. |

Year, month, and week are not supported — not fixed-length, cannot map to `Duration`.

---

## Behavior notes

- **Surface**: `LayrzResponsiveModal.show` resolves to a `LayrzDialog` on desktop (`≥960px`) with a `LayrzPickerDialogHeader` (title, close "X") and a Cancel/Reset/Save `actions` row, or a `LayrzBottomSheet` below that with an inline Reset button and no `actions` row.
- **Commit models differ by branch** — this is the single most important behavioral fact:
  - Desktop: edits buffer into a local draft; `onChanged` fires exactly once on Save. Cancel discards the draft with no callback. Reset zeroes the draft, calls `onChanged` immediately, and closes — in one gesture, distinct from Save.
  - Mobile: every field edit calls `onChanged` immediately (no draft). Reset is the sheet's only closing action.
  - **Save is always enabled** on the desktop branch — unlike date/time pickers, a `Duration.zero` draft is a valid, committable value with no "has the user touched this" gate needed.
- **Dialog width forces a two-column layout**: the dialog's default 480px width leaves ~432px for the picker's fields, which fits two fields per row using short-form unit labels (not the long-form labels a wider anchor-matched panel used to allow).
- **External clock affordance**: a decorative `MdiIcons.clockOutline` icon renders as an external sibling to the chrome (never inside `prefixSlot`/`suffixSlot`, both of which stay empty and free for future use) — composed the same way `LayrzNumberInput` composes its step buttons. Colour tracks the chrome's own `LayrzInputStyleSpec` state; excluded from semantics.
- **Error styling works correctly**: the field passes `readOnly: false` into its own style resolution (with `suppressReadOnlyLock: true` to still hide the lock icon) so a danger border renders correctly when `errors` is non-empty — an earlier version regressed this by hardcoding `readOnly: true`, which out-ranks error in the style resolver's precedence.
