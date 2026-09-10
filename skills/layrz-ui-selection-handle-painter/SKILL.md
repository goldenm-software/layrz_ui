---
name: layrz-ui-selection-handle-painter
description: Use LayrzSelectionHandlePainter in a layrz_ui Flutter widget. Apply when understanding or extending the teardrop-shaped selection-handle CustomPainter that LayrzTextSelectionControls draws internally — a single-color, unrotated NW-cornered teardrop rotated externally per handle type. Not normally constructed directly by application code.
---

> **Dart syntax:** This library requires Dart ≥ 3.13. Use dot shorthand for all enum values — never the fully-qualified form.

> **Full constructor and property reference:** read `references/api.md` in this skill's directory.

---

## When to use

- You will almost never construct this directly — `LayrzTextSelectionControls.buildHandle` creates one internally for each selection handle it renders.
- Reach for this skill when building a custom `EditableText`-based selection UI that needs the exact same teardrop glyph, or when debugging handle-rotation/positioning issues in `LayrzTextSelectionControls`.
- **Do not use** as a general-purpose marker/pin icon — this shape and its rotation contract are specifically calibrated for text-selection handle anchoring; reach for a plain `Icon`/`CustomPainter` for anything else.
- **Do not adjust the rotation angles** documented for handle types elsewhere (`LayrzTextSelectionControls.buildHandle`) without re-verifying against real selection endpoints — they were determined empirically, not derived from a formula.

---

## Minimal usage

```dart
// Normally created internally by LayrzTextSelectionControls.buildHandle —
// shown here for a custom selection UI that wants the same glyph:
CustomPaint(
  size: const Size(22.0, 22.0),
  painter: LayrzSelectionHandlePainter(
    color: context.tokens.colors.primary,
  ),
)
```

---

## Key behaviors

- **Single color, no border, no decoration.** The painter fills the teardrop shape with one `Paint()..color = color` — no stroke, no shadow.
- **Fixed 22×22 canvas.** The painter is always invoked with `size = Size(22, 22)`; it derives its own circle radius from `size.width / 2`.
- **Unrotated corner points NW.** The base shape (before any `Transform.rotate` applied by the caller) always has its square corner in the top-left quadrant — rotation to point at a specific handle direction happens *outside* this painter, in `LayrzTextSelectionControls.buildHandle`.
- **`shouldRepaint` only on color change.** Repaints are triggered solely by `color` differing between the old and new delegate — no other state exists to compare.
- **Composed via `Path` winding, not layered shapes.** `addOval` (the circular bulge) + `addRect` (the square corner) on one `Path`, filled together — this is what produces the teardrop silhouette from two primitive shapes.

---

## Common patterns

```dart
// Standard usage, exactly as LayrzTextSelectionControls.buildHandle does internally:
CustomPaint(
  size: const Size(22.0, 22.0),
  painter: LayrzSelectionHandlePainter(color: tokens.colors.primary),
)

// Rotated to point NE (the "left"/selection-start handle orientation)
Transform.rotate(
  angle: math.pi / 2.0,
  child: CustomPaint(
    size: const Size(22.0, 22.0),
    painter: LayrzSelectionHandlePainter(color: tokens.colors.primary),
  ),
)
```

---

## Usage conventions

- Always pair this painter with the exact rotation angles `LayrzTextSelectionControls.buildHandle` uses (`0`, `π/2`, `π/4` for right/left/collapsed) if reproducing selection-handle behavior elsewhere — the painter itself has no concept of "which handle type", only the caller's rotation does.
- Keep the `CustomPaint` size at `22.0 × 22.0` — the painter's own geometry (circle radius, square corner extent) is derived from the size it's given, so a different size changes proportions rather than simply scaling the same glyph.
- Prefer reusing `LayrzTextSelectionControls.instance` over hand-rolling this painter for anything that is actually a text field — this painter exists to be composed by that class, not as a general-purpose API surface.
