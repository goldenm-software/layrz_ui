---
name: layrz-ui-code-editor
description: Use LayrzCodeEditor in a layrz_ui Flutter widget. Apply when adding an editable, syntax-highlighted code surface — Python/LCL/LML source editing with live highlighting, Tab/Shift+Tab indent, a line-number gutter, `LayrzCodeError` diagnostics, autocomplete suggestions, or a read-only/disabled surface that must render pixel-identical to `LayrzCodeSnippet`.
---

> **Dart syntax:** This library requires Dart ≥ 3.13. Use dot shorthand for all enum values (e.g. `.python`, `.lcl`, `.lml`) — never the fully-qualified form (`LayrzCodeLanguage.python`).

> **Full constructor and property reference:** read `references/api.md` in this skill's directory.

---

## When to use

- Editing a computed-sensor formula (LCL), an LML report/case template, or a Python scripting field — anywhere source needs live syntax highlighting while the user types.
- Surfacing backend/compiler diagnostics per line/column via `errors` (a `List<LayrzCodeError>`), shown as gutter markers and an underlying tonal-red row.
- Offering caller-supplied autocomplete via `suggestions` (e.g. LML `{{variable}}` names the editor has no built-in list for) merged with the language's own built-in symbols.
- **Do not use** for a static, read-only block of code with no editing affordance — use `LayrzCodeSnippet` instead; it is lighter and has no controller/focus machinery. (`LayrzCodeEditor` with `readOnly: true` renders pixel-identical to it, but `LayrzCodeSnippet` is the intentional choice when nothing is ever editable.)
- **Do not use** for free-text prose entry — use `LayrzTextInput`/`LayrzTextAreaInput`; this widget is monospace, syntax-aware, and Tab-repurposing, all wrong defaults for prose.

---

## Minimal usage

```dart
LayrzCodeEditor(
  labelText: 'Computed sensor formula',
  language: .lcl,
  value: formula,
  onChanged: (value) => setState(() => formula = value),
)
```

---

## Key behaviors

- **Always dark.** Like every code widget in this module, the editor always renders in `LayrzCodeThemeExtension.dark()` (or whatever `LayrzCodeThemeExtension` the active theme registers) — never the app's light palette.
- **Not built on `LayrzInputChrome`.** It composes `labelText`/`hintText`/`helperText` itself around a raw `EditableText`, using the Material-free `LayrzTextSelectionControls` — code editing needs a gutter/scroll model the shared chrome doesn't offer.
- **`readOnly`/`disabled` degrade to the same surface as `LayrzCodeSnippet`** — no `EditableText` is built at all in that branch. `disabled` additionally dims the surface to 50% opacity.
- **Controller/focus ownership**: `null` (the default) means the widget creates and disposes its own `LayrzHighlightingController`/`FocusNode`; a caller-supplied `controller` is used as-is — if it isn't already a `LayrzHighlightingController`, live highlighting simply doesn't happen, and this widget never wraps or replaces what it's given.
- **Tab is never swallowed.** Tab/Shift+Tab indent/outdent the current selection (`tabSpaces` literal spaces, or a single `\t` when `useSpaces: false`) instead of moving focus, intercepted by an ancestor `Focus.onKeyEvent`.
- **Ctrl/Cmd+Space** force-opens the autocomplete popup at the caret; arrow keys/Enter/Escape navigate it while open, without ever blocking Tab's own indent behavior.
- **`height` is fixed, not a max.** The editor is always exactly `height` (default `220`) tall and never grows with line count — short content leaves empty space below; long content scrolls inside.
- `onRun`/`onLint`, when non-null, add a run/lint icon button to the top-right action row alongside the copy button — wiring what they do is entirely the caller's responsibility.

---

## Common patterns

```dart
// 1. Diagnostics from a backend validator
LayrzCodeEditor(
  labelText: 'Formula',
  language: .lcl,
  value: formula,
  errors: [
    LayrzCodeError(line: 3, column: 5, message: 'Unknown function GET_PARAMX'),
  ],
  onChanged: (value) => setState(() => formula = value),
)

// 2. Read-only, degrades to the same rendering as LayrzCodeSnippet
LayrzCodeEditor(
  labelText: 'Saved formula',
  language: .lcl,
  value: savedFormula,
  readOnly: true,
)

// 3. LML template with caller-supplied variable suggestions
LayrzCodeEditor(
  labelText: 'Report template',
  language: .lml,
  value: template,
  suggestions: const ['assetName', 'executedAt', 'primaryDeviceId'],
  onChanged: (value) => setState(() => template = value),
)

// 4. Run + lint actions in the top-right row
LayrzCodeEditor(
  labelText: 'Script',
  language: .python,
  value: script,
  onChanged: (value) => script = value,
  onRun: () => runScript(script),
  onLint: () => lintScript(script),
)
```

---

## `LayrzCodeLanguage` reference

| Value | Highlights |
|---|---|
| `.python` | Comments, single/triple-quoted strings, decorators, numbers (incl. hex), keywords, common builtins. |
| `.lcl` | Layrz Compute Language — built-in function names (`GET_SENSOR`, `IF`, ...), strings, numbers, `True`/`False`/`None` (case-insensitive). |
| `.lml` | Layrz Markup Language — same function-call surface as `.lcl`, plus `{{ mustache }}` variables, strings, numbers, constants. |
| `.plain` | No highlighting — every character emitted as plain text. Used as the fallback when a `LayrzMarkdown` fenced block's language is unrecognized. |

---

## Usage conventions

- Guard `onChanged` the way any other input is guarded in a form: assign to local state, then trigger revalidation — this widget does not validate on its own.
- Pass `errors` straight from backend/linter diagnostics; `line`/`column` are 1-based, matching compiler convention — do not subtract 1.
- Reach for `suggestions` only for completions the editor's built-in symbol table cannot know (document-specific variable names); language keywords and builtins are already offered automatically.
- Set `showLineNumbers: false` for short, single-expression fields (e.g. a one-line LCL condition) where a gutter is visual noise.
