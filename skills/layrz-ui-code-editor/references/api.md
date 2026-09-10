# LayrzCodeEditor — API Reference

Source: `lib/src/code/src/code_editor.dart`, `lib/src/code/src/code_error.dart`
- `LayrzCodeEditor` class (`StatefulWidget`) — `code_editor.dart`
- `LayrzCodeError` class — `code_error.dart`
- `LayrzCodeLanguage` enum — `lib/src/highlight/src/language.dart` (shared with `LayrzCodeSnippet`)

---

## Examples

```dart
// Basic editable Python editor
LayrzCodeEditor(
  labelText: 'Editable Python',
  helperText: 'Tab/Shift+Tab indent — not swallowed by focus.',
  language: .python,
  value: source,
  onChanged: (value) => setState(() => source = value),
  height: 260,
)

// With LayrzCodeError gutter markers
LayrzCodeEditor(
  labelText: 'Python with diagnostics',
  language: .python,
  value: source,
  errors: [
    LayrzCodeError(line: 1, column: 1, message: "Unused import 'statistics'"),
    LayrzCodeError(line: 6, column: 21, message: 'Possible division by zero'),
  ],
)

// Read-only — degrades to the same rendering as LayrzCodeSnippet
const LayrzCodeEditor(
  labelText: 'Read-only Python',
  language: .python,
  value: readOnlySample,
  readOnly: true,
)

// LCL formula editor, no gutter
LayrzCodeEditor(
  labelText: 'Computed sensor formula',
  language: .lcl,
  value: formula,
  onChanged: (value) => formula = value,
  showLineNumbers: false,
)

// LML template editor
LayrzCodeEditor(
  labelText: 'Report template',
  language: .lml,
  value: template,
  onChanged: (value) => template = value,
)

// Disabled
const LayrzCodeEditor(
  labelText: 'Formula (locked)',
  language: .lcl,
  value: 'CONSTANT(1)',
  disabled: true,
)

// With run + lint actions and caller suggestions
LayrzCodeEditor(
  labelText: 'Script',
  language: .python,
  value: script,
  onChanged: (value) => script = value,
  onRun: runScript,
  onLint: lintScript,
  suggestions: const ['device_id', 'threshold'],
)
```

---

## Constructor

```dart
const LayrzCodeEditor({
  super.key,
  this.value,
  this.onChanged,
  required this.language,
  this.errors = const [],
  this.showLineNumbers = true,
  this.tabSpaces = 4,
  this.useSpaces = true,
  this.readOnly = false,
  this.disabled = false,
  this.autofocus = false,
  this.controller,
  this.focusNode,
  this.labelText,
  this.hintText,
  this.helperText,
  this.showCopyButton = true,
  this.height = 220,
  this.fontSize = 14,
  this.dense = false,
  this.onTap,
  this.onFocusChanged,
  this.onRun,
  this.onLint,
  this.suggestions = const [],
});
```

No asserts — every combination of parameters is valid.

---

## Properties

| Property | Type | Default | Notes |
|---|---|---|---|
| `value` | `String?` | `null` | Seeds `controller` when supplied; when `controller` is `null` this is the source of truth for ongoing edits is the controller created from it. `null` starts empty. |
| `onChanged` | `ValueChanged<String>?` | `null` | Fires on every edit, including Tab/Shift+Tab indentation and autocomplete acceptance. |
| `language` | `LayrzCodeLanguage` | **required** | Language used to syntax-highlight the edited text. |
| `errors` | `List<LayrzCodeError>` | `[]` | Diagnostics marked in the gutter and, per-line, underlined in the code. |
| `showLineNumbers` | `bool` | `true` | Whether to draw the line-number gutter. |
| `tabSpaces` | `int` | `4` | Spaces a Tab keystroke inserts when `useSpaces` is `true`; also the max leading spaces a Shift+Tab removes per selected line (falls back to removing one leading tab character). |
| `useSpaces` | `bool` | `true` | `true` inserts `tabSpaces` literal spaces on Tab; `false` inserts a single `\t`. |
| `readOnly` | `bool` | `false` | Renders via the same internal surface `LayrzCodeSnippet` uses instead of building an `EditableText`. |
| `disabled` | `bool` | `false` | Like `readOnly`, plus dims the surface to 50% opacity. |
| `autofocus` | `bool` | `false` | Whether the editor requests focus as soon as it is built. |
| `controller` | `TextEditingController?` | `null` | `null` → internally-created, owned `LayrzHighlightingController` (live highlighting works out of the box). Supplied → used as-is; only keeps highlighting if it is itself a `LayrzHighlightingController`. |
| `focusNode` | `FocusNode?` | `null` | `null` → created and disposed internally, mirroring `controller`'s ownership rule. |
| `labelText` | `String?` | `null` | Label rendered above the editor. |
| `hintText` | `String?` | `null` | Placeholder shown when the editor is empty. |
| `helperText` | `String?` | `null` | Helper text rendered below the editor. |
| `showCopyButton` | `bool` | `true` | Overlays a copy button in the top-right corner, in both the editable and read-only branches. |
| `height` | `double` | `220` | Fixed height of the code area — never grows/shrinks with line count; content scrolls internally past this. |
| `fontSize` | `double` | `14` | Font size, in logical pixels, used to render the code. |
| `dense` | `bool` | `false` | Uses the dense density variant, reducing outer padding by one spacing level. |
| `onTap` | `VoidCallback?` | `null` | Fired when the editor is tapped. |
| `onFocusChanged` | `ValueChanged<bool>?` | `null` | Fired when the editor gains or loses focus. |
| `onRun` | `VoidCallback?` | `null` | When non-null, shows a run (play) button in the top-right action row. Wiring what "run" does is the caller's job. |
| `onLint` | `VoidCallback?` | `null` | When non-null, shows a lint button in the top-right action row. |
| `suggestions` | `List<String>` | `[]` | Extra autocomplete entries merged with `language`'s built-in symbols, filtered by prefix as the user types. Each accepted entry is inserted verbatim. |

---

## `LayrzCodeError`

```dart
@immutable
class LayrzCodeError {
  const LayrzCodeError({
    required this.line,
    required this.column,
    required this.message,
  });

  final int line;
  final int column;
  final String message;

  LayrzCodeError copyWith({int? line, int? column, String? message});
}
```

| Property | Type | Notes |
|---|---|---|
| `line` | `int` | 1-based line the error is reported against — matches compiler/linter convention. |
| `column` | `int` | 1-based column the error is reported against. |
| `message` | `String` | Human-readable diagnostic text. |

Value-equality via `==`/`hashCode` on all three fields.

---

## `LayrzCodeLanguage` enum

Shared with `LayrzCodeSnippet` and the highlighting engine (`lib/src/highlight/src/language.dart`).

| Value | Highlights |
|---|---|
| `.python` | Comments, single/triple-quoted strings, decorators, numbers (incl. hex), keywords, common builtins. |
| `.lcl` | Layrz Compute Language function names, strings, numbers, case-insensitive `True`/`False`/`None`. |
| `.lml` | Same function-call surface as `.lcl`, plus `{{ mustache }}` variables, strings, numbers, constants. |
| `.plain` | No highlighting — every character emitted as plain text. |

---

## Companion widgets / shared engine

- **`LayrzCodeSnippet`** — the read-only counterpart this widget's `readOnly`/`disabled` branch renders through.
- **`LayrzHighlightingController`** — a `TextEditingController` subclass that tokenizes its own text on every `buildTextSpan` call; created internally when `controller` is `null`.
- **`LayrzSyntaxHighlighter`** — the stateless tokenizer both code widgets call.
- **`LayrzCodeThemeExtension`** — the palette (`background`, `foreground`, `gutterBackground`, `gutterForeground`, `currentLineBackground`, `errorColor`, plus one color per syntax scope). Register a custom instance via `LayrzThemeData(extensions: [...])` to recolor every code widget at once. `LayrzHighlightScope.function` always renders bold regardless of palette.

---

## Behavior notes

- **Gutter/scroll sync**: the gutter and code share one vertical `SingleChildScrollView`, side by side in a `Row`, so line `N` in the gutter always aligns with line `N` of the code — the gutter never scrolls independently.
- **Tab handling**: intercepted by an ancestor `Focus.onKeyEvent` (the same pattern `LayrzNumberInput` uses for arrow-key stepping), not by the `EditableText` itself — the text transformation itself is the pure, independently-testable `applyTabIndent` function (also exposed as the static `LayrzCodeEditor.applyTabIndent`).
- **Autocomplete popup**: rendered in the root `Overlay` (not clipped by the editor's rounded chrome or `maxHeight`), anchored to the caret via a `CompositedTransformFollower`. Ctrl/Cmd+Space force-opens it; Tab is never consumed by the popup, so indentation keeps working mid-completion.
- **Action row reserve**: when `onRun`/`onLint`/`showCopyButton` are active, the code content's right padding grows to keep long lines from running under the overlaid buttons — this is automatic, not caller-configurable.
- **Language change while owning the controller**: if `controller` is `null` (internally owned) and `language` changes, the controller is recreated so the highlighter re-tokenizes under the new grammar, preserving the current text.
