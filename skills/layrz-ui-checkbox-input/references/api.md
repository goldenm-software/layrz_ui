# LayrzCheckboxInput — API Reference

Source: `lib/src/inputs/src/checkbox/checkbox_input.dart`
- `LayrzCheckboxInput` class — line 29

---

## Examples

```dart
// Basic checkbox with label
LayrzCheckboxInput(
  labelText: 'Enable notifications',
  value: notificationsEnabled,
  onChanged: (value) => setState(() => notificationsEnabled = value),
)

// Bare checkbox, no label
LayrzCheckboxInput(
  value: isChecked,
  onChanged: (value) => setState(() => isChecked = value),
)

// Disabled (checked)
LayrzCheckboxInput(
  labelText: 'Locked setting',
  value: true,
  disabled: true,
)

// Disabled via null onChanged (equivalent effect)
LayrzCheckboxInput(
  labelText: 'Read-only setting',
  value: false,
  onChanged: null,
)

// With validation errors
LayrzCheckboxInput(
  labelText: 'I agree to the terms',
  value: agreed,
  errors: const ['You must agree to continue'],
  onChanged: (value) => setState(() => agreed = value),
)

// With a caller-supplied focus node
LayrzCheckboxInput(
  labelText: 'Auto-save',
  value: autoSave,
  focusNode: myFocusNode,
  onChanged: (value) => setState(() => autoSave = value),
)
```

---

## Constructor

```dart
const LayrzCheckboxInput({
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
| `labelText` | `String?` | `null` | Rendered beside the checkbox, tappable to toggle. `null` renders the bare control with no label. |
| `value` | `bool` | **required** | The current checked state. Always `true` or `false`, never `null` — no tristate support. |
| `onChanged` | `ValueChanged<bool>?` | `null` | Fires the new value on toggle. `null` disables the control (independent of `disabled`). |
| `focusNode` | `FocusNode?` | `null` | Internal node created/disposed when omitted. Caller-supplied nodes are never disposed. |
| `errors` | `List<String>` | `[]` | Rendered below the control via the shared footer slot. |
| `hideDetails` | `bool` | `false` | Hides the error message block. |
| `disabled` | `bool` | `false` | Disables the control independently of whether `onChanged` is set — either makes it inert. |

---

## Behavior notes

- **State precedence for the box's colors**: disabled > error (`errors.isNotEmpty`) > hover/focus-visible/pressed > default.
- **Focus-visible**: the border-color focus treatment shows only when focus was gained via keyboard, not via a pointer tap (tracked internally via a `_focusFromPointer` flag).
- **Checkmark glyph**: a non-colour indicator of checked state (WCAG 1.4.1) — an `MdiIcons.check` glyph fades in via `Opacity` as the toggle animates.
- **Semantics**: the control announces `checked`, `enabled`, and a tap action; `labelText` (when set) is the announced name. The label `Text` itself is excluded from semantics to avoid double-announcing.
- **Box size**: fixed 20×20 square with a 1px border and `tokens.radius.br1` corners — not configurable.
- **Disposal contract**: when `focusNode` is `null`, an internal `FocusNode` is created in `initState` and disposed in `dispose`; a caller-supplied node is never disposed by this widget.
