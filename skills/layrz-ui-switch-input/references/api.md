# LayrzSwitchInput — API Reference

Source: `lib/src/inputs/src/switch/switch_input.dart`
- `LayrzSwitchInput` class — line 28

---

## Examples

```dart
// Basic switch with label
LayrzSwitchInput(
  labelText: 'Push notifications',
  value: pushEnabled,
  onChanged: (value) => setState(() => pushEnabled = value),
)

// Bare switch, no label
LayrzSwitchInput(
  value: isOn,
  onChanged: (value) => setState(() => isOn = value),
)

// Disabled (on)
LayrzSwitchInput(
  labelText: 'Always-on setting',
  value: true,
  disabled: true,
)

// Disabled via null onChanged (equivalent effect)
LayrzSwitchInput(
  labelText: 'Read-only setting',
  value: false,
  onChanged: null,
)

// With validation errors
LayrzSwitchInput(
  labelText: 'Marketing emails',
  value: subscribed,
  errors: const ['This preference could not be saved'],
  onChanged: (value) => setState(() => subscribed = value),
)

// With a caller-supplied focus node
LayrzSwitchInput(
  labelText: 'Auto-sync',
  value: autoSync,
  focusNode: myFocusNode,
  onChanged: (value) => setState(() => autoSync = value),
)
```

---

## Constructor

```dart
const LayrzSwitchInput({
  super.key,
  this.labelText,
  required this.value,
  this.onChanged,
  this.focusNode,
  this.errors = const [],
  this.hideDetails = false,
  this.disabled = false,
});
```

No asserts — every combination of parameters is valid.

---

## Properties

| Property | Type | Default | Notes |
|---|---|---|---|
| `labelText` | `String?` | `null` | Rendered beside the track, tappable to toggle. `null` renders the bare control with no label. |
| `value` | `bool` | **required** | The current toggled state. `true` = thumb on the right ("on"), `false` = thumb on the left ("off"). |
| `onChanged` | `ValueChanged<bool>?` | `null` | Fires the new value on toggle. `null` disables the control (independent of `disabled`). |
| `focusNode` | `FocusNode?` | `null` | Internal node created/disposed when omitted. Caller-supplied nodes are never disposed. |
| `errors` | `List<String>` | `[]` | Rendered below the control via the shared footer slot. |
| `hideDetails` | `bool` | `false` | Hides the error message block. |
| `disabled` | `bool` | `false` | Disables the control independently of whether `onChanged` is set — either makes it inert. |

---

## Behavior notes

- **Track geometry** (fixed, not configurable): 52×28 track, 20×20 thumb, 4px inset on all sides — 24px of horizontal thumb travel.
- **Colour precedence**: disabled > error (`errors.isNotEmpty`) > pressed/hover/focus-visible > default. See the colour-state table in `SKILL.md`.
- **Focus-visible**: the track-colour focus treatment shows only when focus was gained via keyboard, not via a pointer tap (tracked internally via a `_focusFromPointer` flag).
- **Non-colour indicator**: the thumb's own left/right position indicates on/off state, not colour alone (WCAG 1.4.1).
- **Semantics**: the control announces `toggled`, `enabled`, and a tap action; `labelText` (when set) is the announced name. The label `Text` itself is not separately excluded from semantics the way the checkbox's is (no `ExcludeSemantics` wrapper on the label `Text`), since the switch's `Semantics.label` already supplies the name.
- **Disposal contract**: when `focusNode` is `null`, an internal `FocusNode` is created in `initState` and disposed in `dispose`; a caller-supplied node is never disposed by this widget.
