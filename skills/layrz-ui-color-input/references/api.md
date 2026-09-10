# LayrzColorInput — API Reference

Source: `lib/src/pickers/src/color/color_input.dart`
- `LayrzColorInput` class

Companion source (surface, not directly constructed by callers): `lib/src/pickers/src/color/color_surface.dart` (`LayrzColorSurface`), `color_wheel.dart` (`LayrzColorWheel`).

---

## Examples

```dart
// Minimal — wheel only (no palette)
LayrzColorInput(
  labelText: 'Accent color',
  value: accentColor,
  onChanged: (value) => setState(() => accentColor = value),
)

// With a brand palette (Palette tab shown first)
LayrzColorInput(
  labelText: 'Tag color',
  value: tagColor,
  palette: const {
    Color(0xFFEF5350),
    Color(0xFF66BB6A),
    Color(0xFF2196F3),
  },
  onChanged: (value) => setState(() => tagColor = value),
)

// With errors and help affordance
LayrzColorInput(
  labelText: 'Status color',
  value: statusColor,
  errors: statusColorErrors,
  helpTitleText: 'Status color',
  helpContentText: 'This color is shown on the dashboard badge.',
  onChanged: (value) => setState(() => statusColor = value),
)

// Disabled
LayrzColorInput(
  labelText: 'System color',
  value: systemColor,
  disabled: true,
)
```

---

## Constructor

```dart
const LayrzColorInput({
  super.key,
  required this.value,
  this.onChanged,
  this.palette = const {},
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
       labelText != null || hintText != null,
       'At least one of labelText or hintText must be non-null.',
     );
```

---

## Properties

| Property | Type | Default | Notes |
|---|---|---|---|
| `value` | `Color` | required | The currently-selected color. Always the committed value, never a mid-draft color. |
| `onChanged` | `ValueChanged<Color>?` | `null` | Called with the drafted color once the user presses Save. Never called on mount or merely by opening the surface. |
| `palette` | `Set<Color>` | `{}` | Caller-supplied swatches for the Palette tab. Empty (default) hides the Palette tab entirely; the surface opens on Wheel. |
| `labelText` | `String?` | `null` | Label displayed above the field. |
| `hintText` | `String?` | `null` | Placeholder shown when no `labelText` describes the field. |
| `isRequired` | `bool` | `false` | Whether the field is marked as required. |
| `errors` | `List<String>` | `[]` | Error messages displayed below the field. |
| `hideDetails` | `bool` | `false` | Whether to hide the error/help detail block. |
| `disabled` | `bool` | `false` | Whether the field is non-interactive. |
| `controller` | `TextEditingController?` | `null` | Anchor field's text controller. Created and disposed internally if omitted. |
| `focusNode` | `FocusNode?` | `null` | Anchor field's focus node. Created and disposed internally if omitted. |
| `dense` | `bool` | `false` | Whether the field uses the dense density variant. |
| `helpTitleText` | `String?` | `null` | Title text for the help affordance tooltip. |
| `helpContentText` | `String?` | `null` | Content text for the help affordance tooltip. |

At least one of `labelText`/`hintText` must be non-null (debug assertion).

---

## Behavior notes

- **Composition**: composes `LayrzInputChrome` directly (D63) — never wraps or extends `LayrzTextInput`. The closed field shows a circular swatch of `value` plus its hex code (`Color.toHex()`), truncated with an ellipsis on overflow.
- **Container**: the surface (`LayrzColorSurface`) opens via `LayrzResponsiveModal.show` — a centered `LayrzDialog` at `>= 960px`, a `LayrzBottomSheet` below `context.isCompact`. Both branches show a `LayrzPickerDialogHeader` (label as title, plus a close "X") above the tabs.
- **Two fixed tabs, no `enabledTypes` parameter.** Unlike layrz_theme's `ThemedColorPicker.enabledTypes`, the surface always exposes exactly Palette + Wheel — there is no way to force wheel-only or palette-only when a palette is supplied. Palette auto-hides only when `palette` is empty.
- **Wheel tab**: a from-scratch HSV color wheel disc (`LayrzColorWheel`) plus a value/brightness slider — hand-rolled because `flex_color_picker` (layrz_theme's dependency) is Material-coupled and cannot be used in this library.
- **Paste**: always a visible labeled button, never an ambient clipboard read (not on open, tab switch, or timer). Parses `#RRGGBB`/`RRGGBB`; a failed parse is a silent no-op leaving the draft untouched.
- **Commit model — staged-with-Save**: swatch tap / wheel drag / successful paste update only the draft. `onChanged` fires exactly once, on Save, with the drafted color. Cancel discards the draft entirely. Escape and barrier tap both act as Cancel.
- **No Clear action** — a color field's only content is the one currently-selected color; there is no "nothing selected" state, unlike a date field. The actions row is Cancel/Save only.
- **Migration from `ThemedColorPicker`**: `*Picker` suffix retired → `LayrzColorInput`. `enabledTypes` removed. Commit model changed from a Material dialog Save/OK to this family's staged-with-Save pattern inside `LayrzDialog`/`LayrzBottomSheet` (never a Material dialog). Palette source changed from theme-provided defaults to a caller-supplied `Set<Color>` — there is no built-in default palette.
