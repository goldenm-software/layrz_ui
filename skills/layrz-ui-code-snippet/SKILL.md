---
name: layrz-ui-code-snippet
description: Use LayrzCodeSnippet in a layrz_ui Flutter widget. Apply when displaying a read-only, syntax-highlighted block of source — Python/LCL/LML formula previews, API response bodies, documentation examples, or any static code that needs a copy-to-clipboard affordance but no editing.
---

> **Dart syntax:** This library requires Dart ≥ 3.13. Use dot shorthand for all enum values (e.g. `.python`, `.lcl`, `.lml`) — never the fully-qualified form (`LayrzCodeLanguage.python`).

> **Full constructor and property reference:** read `references/api.md` in this skill's directory.

---

## When to use

- Showing a computed-sensor formula (LCL) or template preview (LML) inline, read-only, in a config or detail screen.
- Embedding a short Python example in in-app documentation or a help panel.
- Rendering an API response body, webhook payload, or other static source-like text with monospace, highlighted presentation.
- **Do not use** for anything the user needs to edit — use `LayrzCodeEditor` instead (its `readOnly: true` branch renders pixel-identical to this widget, but reach for `LayrzCodeSnippet` directly when nothing is ever editable — it's lighter, with no controller/focus machinery).
- **Do not use** for fenced code blocks inside a larger Markdown document — `LayrzMarkdown` already renders those through this widget internally; render the whole document with `LayrzMarkdown` instead.

---

## Minimal usage

```dart
LayrzCodeSnippet(
  code: formula,
  language: .lcl,
)
```

---

## Key behaviors

- **Always dark.** Renders in `LayrzCodeThemeExtension.dark()` (or whatever `LayrzCodeThemeExtension` the active theme registers) — never the app's own light palette, matching every other code widget.
- **Read-only, no text selection.** This paints a plain `RichText`, not an `EditableText` — there is no `SelectableText`/`SelectionArea` (both Material-only) wired in. The copy button is the supported way to extract text, not drag-selection.
- `showCopyButton: true` (default) overlays a small affordance in the top-right corner that copies the entire `code` string.
- `showLineNumbers` defaults to **`false`** here (unlike `LayrzCodeEditor`, which defaults it to `true`) — pass `true` explicitly when a gutter is wanted.
- `maxHeight: null` (default) leaves height unconstrained, sizing to the code's natural height; set it to keep a long snippet within a visible area — it scrolls internally past that height rather than overflowing the layout.
- Long lines scroll horizontally rather than wrapping — code is never reflowed.

---

## Common patterns

```dart
// 1. With line numbers, for a longer example
LayrzCodeSnippet(
  code: pythonSnippet,
  language: .python,
  showLineNumbers: true,
)

// 2. LCL formula preview, no copy button
LayrzCodeSnippet(
  code: formula,
  language: .lcl,
  showCopyButton: false,
)

// 3. Constrained height for a long log/response body
LayrzCodeSnippet(
  code: longLogOutput,
  language: .python,
  maxHeight: 200,
)

// 4. Custom padding and font size
LayrzCodeSnippet(
  code: shortExpression,
  language: .lcl,
  fontSize: 12,
  padding: const EdgeInsets.all(8),
)
```

---

## `LayrzCodeLanguage` reference

| Value | Highlights |
|---|---|
| `.python` | Comments, single/triple-quoted strings, decorators, numbers (incl. hex), keywords, common builtins. |
| `.lcl` | Layrz Compute Language — built-in function names, strings, numbers, `True`/`False`/`None` (case-insensitive). |
| `.lml` | Same function-call surface as `.lcl`, plus `{{ mustache }}` variables, strings, numbers, constants. |
| `.plain` | No highlighting at all — every character emitted as plain text; used as the fallback for an unrecognized fence language inside `LayrzMarkdown`. |

---

## Usage conventions

- Prefer this over `LayrzCodeEditor(readOnly: true)` whenever nothing is ever editable — it avoids allocating a controller/focus node this widget has no use for.
- Set `maxHeight` on any snippet that could realistically exceed the visible viewport (a full API response, a long script) — without it the widget grows to fit content, which can push surrounding layout off-screen.
- Leave `showCopyButton` on by default for anything a user might reasonably want to extract; only disable it for decorative/preview-only code samples.
