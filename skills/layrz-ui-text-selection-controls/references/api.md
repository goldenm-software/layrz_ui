# LayrzTextSelectionControls — API Reference

Source: `lib/src/selection/src/selection_controls.dart`
- `LayrzTextSelectionControls` class (`extends TextSelectionControls with TextSelectionHandleControls`)

---

## Examples

```dart
// Wiring a custom EditableText to Material-free selection
EditableText(
  controller: controller,
  focusNode: focusNode,
  style: style,
  cursorColor: context.tokens.colors.primary,
  backgroundCursorColor: context.tokens.colors.fg3,
  selectionControls: LayrzTextSelectionControls.instance,
)
```

For `LayrzTextInput`, this is already integrated — no additional configuration is needed.

---

## API surface

```dart
class LayrzTextSelectionControls extends TextSelectionControls
    with TextSelectionHandleControls {
  /// Returns the singleton instance.
  static LayrzTextSelectionControls get instance;

  // No public constructor — LayrzTextSelectionControls._internal() is private.
}
```

| Member | Signature | Notes |
|---|---|---|
| `instance` | `static LayrzTextSelectionControls get` | The only way to obtain an instance. Always returns the same object. |
| `buildHandle` | `Widget buildHandle(BuildContext, TextSelectionHandleType, double, [VoidCallback?])` | Override — renders the teardrop handle, rotated per `type`. |
| `getHandleAnchor` | `Offset getHandleAnchor(TextSelectionHandleType, double)` | Override — anchor point within the 22×22 handle box, per `type`. |
| `getHandleSize` | `Size getHandleSize(double)` | Override — always returns `Size(22.0, 22.0)`, independent of `textLineHeight`. |
| `operator==` | `bool operator==(Object other)` | Identity-based: `true` for any two `LayrzTextSelectionControls`, since only one ever exists. |
| `hashCode` | `int get hashCode` | Constant `0`. |

---

## Handle geometry

| Handle type | Rotation | Corner points | Role |
|---|---|---|---|
| `TextSelectionHandleType.left` | 90° clockwise (`π/2`) | NE (up-right) | Selection start |
| `TextSelectionHandleType.right` | 0° (none) | NW (up-left) | Selection end |
| `TextSelectionHandleType.collapsed` | 45° clockwise (`π/4`) | N (up) | Caret position |

The unrotated teardrop's square corner sits at NW; `Transform.rotate` uses clockwise rotation for positive angles in Flutter. These angles are exact and empirically determined — changing them misaligns handles with the actual selection endpoints.

- **Fill color**: `tokens.colors.primary`.
- **Size**: fixed 22×22 logical pixels, regardless of `textLineHeight`.
- **Hit region**: matches the visual size, via `GestureDetector(behavior: HitTestBehavior.translucent)`.

---

## Context menu / toolbar

Because this class mixes in `TextSelectionHandleControls`, the toolbar is surfaced through `EditableText.contextMenuBuilder`, not the deprecated `buildToolbar` method. The toolbar itself is rendered by `LayrzSelectionToolbar`, showing actions from `LayrzSelectableAction` (built-ins: copy/cut/paste/select-all, filtered by field state; custom actions supported).

---

## Behavior notes

- **Why a singleton.** `EditableText.didUpdateWidget` disposes and recreates the selection overlay whenever `selectionControls` differs between builds. A fresh instance on every rebuild would flicker the overlay and lose selection state; the singleton means every `EditableText` in the app shares one instance and the overlay survives rebuilds.
- **Theme changes need no instance recreation.** `context.tokens` is read inside `buildHandle` at render time, not cached at construction — a theme swap is reflected on the next paint.
- **Touch magnification.** Pairs naturally with `LayrzSelectionMagnifier.magnifierConfigurationFor(...)` on the same `EditableText`'s `magnifierConfiguration` parameter — the two are wired independently but typically used together for touch-platform drag-to-select.
