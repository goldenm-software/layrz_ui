---
name: layrz-ui-selection-toolbar
description: Use LayrzSelectionToolbar in a layrz_ui Flutter widget. Apply when rendering the Material-free selection context-menu toolbar directly — a dark surface row of LayrzSelectableAction buttons, auto-positioned above (or below, when clipped) the current selection. Normally rendered internally by LayrzTextSelectionControls, not constructed directly.
---

> **Dart syntax:** This library requires Dart ≥ 3.13. Use dot shorthand for all enum values — never the fully-qualified form.

> **Full constructor and property reference:** read `references/api.md` in this skill's directory.

---

## When to use

- You will almost never construct this directly — `LayrzTextSelectionControls.instance` renders it automatically via `EditableText.contextMenuBuilder` whenever a selection's context menu opens.
- Reach for this skill when building a custom overlay/popover that needs the same dark, tonal selection-toolbar chrome outside the normal `EditableText` context-menu flow.
- **Do not use** to render a generic dropdown/context menu — use `LayrzContextMenu` or `LayrzDropdownMenu` for anything that isn't specifically a text-selection action bar.
- **Do not use** with a Material-style light surface — this widget's dark-fill/light-text treatment is deliberate (matches `LayrzTooltip`'s overlay convention) and should not be "corrected" to a light fill.

---

## Minimal usage

```dart
// Normally rendered internally — shown here for the rare direct-integration case:
LayrzSelectionToolbar(
  actions: {LayrzSelectableAction.copy, LayrzSelectableAction.paste},
  anchorAbove: selectionTopLeft,
  anchorBelow: selectionBottomLeft,
  tokens: context.tokens,
  onActionPressed: (type) {
    if (type == 'copy') copySelection();
    if (type == 'paste') pasteAtCursor();
  },
)
```

---

## Key behaviors

- **Dark overlay surface, always** — background `tokens.colors.fg1`, content `tokens.colors.sf1`, matching `LayrzTooltip`'s own treatment. Page surfaces are light with dark text; overlay surfaces (this one included) are dark with light text — deliberate, not a bug to "fix".
- **Content-sized, not overlay-width.** The toolbar sizes to fit its action buttons; horizontal scrolling only kicks in when content exceeds available width (rare, with the typical 3–5 buttons).
- **Auto-positions above, flips below.** Via `CustomSingleChildLayout` with `TextSelectionToolbarLayoutDelegate` — positions above the selection by default and flips below when there isn't enough space above.
- **`actions` is sorted internally by `type`** for consistent, stable ordering regardless of the `Set`'s own iteration order.
- **`onActionPressed` receives the action's `type` string**, not the `LayrzSelectableAction` instance itself — branch on `'copy'`/`'cut'`/`'paste'`/`'selectAll'`, or a custom action's own `type` (always `'custom'`, so distinguish custom actions some other way if you have more than one).

---

## Common patterns

```dart
// Typical integration path (this is what LayrzTextSelectionControls does internally
// — shown for understanding, not for direct reuse):
EditableText(
  selectionControls: LayrzTextSelectionControls.instance,
  contextMenuBuilder: (context, editableTextState) {
    // LayrzTextSelectionControls builds a LayrzSelectionToolbar here,
    // anchored to the editable's own selection rects.
  },
)
```

---

## Usage conventions

- Prefer using `LayrzTextSelectionControls.instance` on any `EditableText`-based widget rather than manually building `LayrzSelectionToolbar` — the controls class already handles anchoring, action filtering, and context-menu wiring correctly.
- If you must build one directly (a custom overlay case), always pass `tokens` from `context.tokens` at build time — never hardcode colors, since the dark surface treatment is token-driven, not a fixed palette.
- Keep the action `Set` small (3–5 entries) — the toolbar is designed to size to content, and horizontal scroll is a fallback, not the intended default experience.
