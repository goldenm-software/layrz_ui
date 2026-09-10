---
name: layrz-ui-text-selection-controls
description: Use LayrzTextSelectionControls in a layrz_ui Flutter widget. Apply when wiring a raw EditableText (a custom text-editing widget not already using LayrzTextInput) to Material-free selection handles and a Material-free context menu toolbar — pass the singleton instance via `selectionControls`.
---

> **Dart syntax:** This library requires Dart ≥ 3.13. Use dot shorthand for all enum values — never the fully-qualified form.

> **Full constructor and property reference:** read `references/api.md` in this skill's directory.

---

## When to use

- Building a custom `EditableText`-based widget (like `LayrzCodeEditor` does) that needs Material-free selection handles and a Material-free copy/cut/paste/select-all toolbar.
- **Do not use** with `LayrzTextInput` or anything built on it — that integration is already wired in; you never pass `selectionControls` yourself for those widgets.
- **Do not construct** with `LayrzTextSelectionControls()` — there is no public constructor. Always use the `LayrzTextSelectionControls.instance` singleton.
- **Do not use** for a read-only display with no editing/selection — use `LayrzCodeSnippet` or a plain `RichText` instead; there is no selection mechanism to wire up.

---

## Minimal usage

```dart
EditableText(
  controller: myController,
  focusNode: myFocusNode,
  style: myTextStyle,
  cursorColor: context.tokens.colors.primary,
  backgroundCursorColor: context.tokens.colors.fg3,
  selectionControls: LayrzTextSelectionControls.instance, // singleton — never construct
  // ... other required EditableText parameters
)
```

---

## Key behaviors

- **Singleton, always.** `LayrzTextSelectionControls.instance` is the only way to obtain one — `EditableText.didUpdateWidget` disposes and recreates the selection overlay whenever `selectionControls` differs between builds, so passing a fresh instance every rebuild would flicker the overlay and lose the selection.
- **Identity equality.** `operator==` returns `true` for any two `LayrzTextSelectionControls` instances (there's only ever one); `hashCode` is a constant `0`.
- **Tokens resolved at render time, not construction time.** Colors/sizes come from `context.tokens` inside `buildHandle`, so a theme change is reflected automatically without recreating this instance.
- **Handles are teardrop-shaped, 22×22 logical pixels**, colored `tokens.colors.primary`, rotated per handle type (`left`/`right`/`collapsed`) to point toward the selected text — the rotation angles are exact and were determined empirically; do not adjust them if extending this class.
- **Toolbar via `contextMenuBuilder`, not `buildToolbar`.** Mixes in `TextSelectionHandleControls`, so `EditableText.contextMenuBuilder` is what actually renders the context menu — the deprecated `buildToolbar` path is not used.
- Built-in toolbar actions (copy/cut/paste/select all) come from `LayrzSelectableAction`; the toolbar itself renders via `LayrzSelectionToolbar`.

---

## Common patterns

```dart
// 1. A custom EditableText-based widget (mirrors LayrzCodeEditor's own wiring)
EditableText(
  key: editableTextKey,
  controller: controller,
  focusNode: focusNode,
  style: baseStyle,
  cursorColor: codeTheme.foreground,
  backgroundCursorColor: codeTheme.gutterForeground,
  selectionColor: codeTheme.foreground.withValues(alpha: 0.24),
  selectionControls: LayrzTextSelectionControls.instance,
  contextMenuBuilder: myContextMenuBuilder,
)
```

---

## Usage conventions

- Never pass a `LayrzTextSelectionControls` instance you constructed yourself — there is no public constructor, and the singleton is a hard requirement for overlay stability.
- Pair with `LayrzSelectionMagnifier.magnifierConfigurationFor(...)` on the same `EditableText` for touch-platform magnification (see the `layrz-ui-selection-magnifier` skill) — the two are independent parameters but typically wired together.
- If you need custom toolbar actions on your custom `EditableText`, that's configured through whatever widget builds your `contextMenuBuilder` (mirroring `LayrzTextInput`'s own `actions` parameter pattern) — not through this class, which has no action-list parameter of its own.
