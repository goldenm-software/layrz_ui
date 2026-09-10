# LayrzSearchInput — API Reference

Source: `lib/src/inputs/src/search/search_input.dart` (+ `search_input_mode.dart`)
- `LayrzSearchInput` class — line 44
- `LayrzSearchInputMode` enum — `search_input_mode.dart`, line 2

---

## Examples

```dart
// Default responsive mode
LayrzSearchInput(
  onSearch: (query) => filter(query),
)

// Always-field mode
LayrzSearchInput(
  mode: .field,
  hintText: 'Search devices…',
  onSearch: (query) => filter(query),
)

// Always-icon mode, opens panel to the left
LayrzSearchInput(
  mode: .icon,
  preferredSide: .left,
  onSearch: (query) => filter(query),
)

// No debounce — fires on every keystroke
LayrzSearchInput(
  debounce: null,
  onSearch: (query) => liveFilter(query),
)

// Custom debounce duration
LayrzSearchInput(
  debounce: const Duration(milliseconds: 500),
  onSearch: (query) => filter(query),
)

// Read-only (still opens/focuses but is not editable)
LayrzSearchInput(
  readOnly: true,
  value: 'locked query',
  onSearch: (query) => filter(query),
)

// With errors and help tooltip
LayrzSearchInput(
  errors: const ['Search index unavailable'],
  helpTitleText: 'Search',
  helpContentText: 'Matches by name, ID, or tag.',
  onSearch: (query) => filter(query),
)

// Field mode with a fixed max width
LayrzSearchInput(
  mode: .field,
  maxWidth: 320,
  onSearch: (query) => filter(query),
)
```

---

## Constructor

```dart
const LayrzSearchInput({
  super.key,
  this.mode = LayrzSearchInputMode.auto,
  this.value,
  this.onSearch,
  this.debounce = const Duration(milliseconds: 300),
  this.hintText,
  this.disabled = false,
  this.readOnly = false,
  this.errors = const [],
  this.helpTitleText,
  this.helpContentText,
  this.controller,
  this.focusNode,
  this.dense = false,
  this.maxWidth,
  this.preferredSide = LayrzPreferredSide.right,
});
```

No asserts on this constructor.

---

## Properties

| Property | Type | Default | Notes |
|---|---|---|---|
| `mode` | `LayrzSearchInputMode` | `.auto` | Presentation mode. See enum table below. |
| `value` | `String?` | `null` | Starting query text. `null` starts empty. |
| `onSearch` | `ValueChanged<String>?` | `null` | Fires per `debounce` timing. Ignored when `disabled`. |
| `debounce` | `Duration?` | `300ms` | `null` fires `onSearch` on every keystroke instead of debouncing. |
| `hintText` | `String?` | `null` | Falls back to a localized "Search" string. |
| `disabled` | `bool` | `false` | Field does not accept input or fire `onSearch`. |
| `readOnly` | `bool` | `false` | Not editable but still fires tap callbacks; renders a lock affordance. Does not affect the clear button. |
| `errors` | `List<String>` | `[]` | Non-empty renders a danger-colored border, a trailing error icon, and the messages below the field. |
| `helpTitleText` | `String?` | `null` | Title of the two-part help tooltip. Ignored unless `helpContentText` is also set. |
| `helpContentText` | `String?` | `null` | Content of the two-part help tooltip. When set and non-empty, a help icon appears in the trailing cluster. |
| `controller` | `TextEditingController?` | `null` | Internal one created/disposed when omitted. |
| `focusNode` | `FocusNode?` | `null` | Internal one created/disposed when omitted. |
| `dense` | `bool` | `false` | `false`: 10px padding. `true`: 6px padding. Identical on every viewport. |
| `maxWidth` | `double?` | `null` | Field-mode only; ignored in icon mode. Clamped to `≥0`. |
| `preferredSide` | `LayrzPreferredSide` | `.right` | Icon-mode panel side (including `.auto` on a compact viewport). Ignored in field mode. |

There is no `labelText`, `position`, `asField`, `customChild`, `inputPadding`, or `isRequired` — none of these exist on the shipped widget.

---

## `LayrzSearchInputMode` enum

| Value | Description |
|---|---|
| `.auto` | Picks between field and icon based on viewport width: icon mode below 960px, field mode at or above it. Default and recommended for responsive layouts. |
| `.icon` | Always a collapsed magnifier button. Opens an anchored panel containing the field; content-sized width (280–480px), not anchored to the button. Use in dense toolbars. |
| `.field` | Always an inline field with a magnifier prefix and a clear suffix (shown only when the field has text). Use in forms or when horizontal space is abundant. |

## `LayrzPreferredSide` enum (shared with tooltips/anchored panels)

| Value | Description |
|---|---|
| `.top` | Place the surface above the anchor. |
| `.bottom` | Place the surface below the anchor. |
| `.left` | Place the surface to the left of the anchor. |
| `.right` | Place the surface to the right of the anchor. Default for `LayrzSearchInput` specifically (differs from `LayrzAnchoredPanel`'s own `.bottom` default, chosen because the trigger is a compact icon button, not an inline field). |

---

## Behavior notes

- **Debounce**: if `debounce` is `null`, `onSearch` fires immediately on every keystroke. Otherwise it fires once after the duration elapses, regardless of keystroke count. A pending timer is always cancelled in `dispose`.
- **Clear affordance fix**: the clear icon reacts to a controller listener that triggers a rebuild only on the empty/non-empty transition — it correctly appears while typing into an initially-empty field, not only when seeded via `value`.
- **Icon mode focus ring**: `LayrzAnchoredPanel` paints its own border around the panel's capped viewport (via `LayrzAnchoredPanelBorder`) only while focused or errored — not a border the chrome itself grows, since the chrome inside the panel renders with `showBorder: false` to avoid a double-rounded-rectangle look.
- **Disposal contract**: when `controller`/`focusNode` is `null`, the widget creates and disposes its own instance; a caller-supplied instance is never disposed.
- **Accessibility**: field mode carries one `Semantics` node with the hint as its label. Icon mode's trigger button carries its own label, and the panel's field carries a distinct, localized label (`LayrzUiL10n.inputsSearchFieldLabel`) — the two are never announced as the same control.
