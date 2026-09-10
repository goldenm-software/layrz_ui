# LayrzCodeSnippet — API Reference

Source: `lib/src/code/src/code_snippet.dart`
- `LayrzCodeSnippet` class (`StatelessWidget`)
- `LayrzCodeLanguage` enum — `lib/src/highlight/src/language.dart` (shared with `LayrzCodeEditor`)

---

## Examples

```dart
// Python, with line numbers
const pythonSnippet = '''
def average_speed(distances, durations):
    total_distance = sum(distances)
    total_duration = sum(durations)
    if total_duration == 0:
        return 0.0
    return round(total_distance / total_duration, 2)
''';

LayrzCodeSnippet(
  code: pythonSnippet,
  language: .python,
  showLineNumbers: true,
)

// LCL — nested function calls
const lclSnippet = '''
COMPARE(
  GET_PARAM(
    CONCAT(PRIMARY_DEVICE(), ".alarm.event"),
  ),
  CONSTANT(1)
)
''';

LayrzCodeSnippet(code: lclSnippet, language: .lcl)

// LML — prose with {{ mustache }} interpolation
LayrzCodeSnippet(
  code: "Asset name is {{assetName}}, sent at {{executedAt}}.",
  language: .lml,
)

// Without the copy button, constrained height
LayrzCodeSnippet(
  code: longLogOutput,
  language: .python,
  showCopyButton: false,
  maxHeight: 200,
)

// Custom padding and font size
LayrzCodeSnippet(
  code: shortExpression,
  language: .lcl,
  fontSize: 12,
  padding: const EdgeInsets.all(8),
)
```

---

## Constructor

```dart
const LayrzCodeSnippet({
  super.key,
  required this.code,
  required this.language,
  this.showLineNumbers = false,
  this.maxHeight,
  this.showCopyButton = true,
  this.fontSize = 14,
  this.padding,
});
```

No asserts — `code` and `language` are the only required fields.

---

## Properties

| Property | Type | Default | Notes |
|---|---|---|---|
| `code` | `String` | **required** | The source code to display. |
| `language` | `LayrzCodeLanguage` | **required** | Syntax-highlighting language. |
| `showLineNumbers` | `bool` | `false` | Whether to draw a line-number gutter. Defaults `false` here, unlike `LayrzCodeEditor` (defaults `true`). |
| `maxHeight` | `double?` | `null` | When set, the surface scrolls internally rather than growing past it. `null` leaves height unconstrained. |
| `showCopyButton` | `bool` | `true` | Whether to overlay a copy-to-clipboard button in the top-right corner. |
| `fontSize` | `double` | `14` | Font size, in logical pixels, used to render `code`. |
| `padding` | `EdgeInsets?` | `null` | Padding around `code` inside the surface. `null` defers to the internal renderer's own default (`tokens.spacing.pd3`, 16px on every side). |

---

## `LayrzCodeLanguage` enum

Shared with `LayrzCodeEditor` and the highlighting engine.

| Value | Highlights |
|---|---|
| `.python` | Comments, single/triple-quoted strings, decorators, numbers (incl. hex literals), keywords, common builtins. |
| `.lcl` | Layrz Compute Language — built-in function names (`GET_SENSOR(...)`, `IF(...)`), strings, numbers, case-insensitive `True`/`False`/`None`. |
| `.lml` | Same function-call surface as `.lcl`, plus `{{ mustache }}` variables, strings, numbers, constants. |
| `.plain` | Every character emitted as plain text — no highlighting. Used as the fallback when a fenced block's info string doesn't map to a known language. |

---

## Behavior notes

- **Internally a thin wrapper.** All tokenizing, gutter rendering, and scrolling delegate to the shared internal renderer (`LayrzCodeSurface`); `LayrzCodeSnippet` only adds the optional copy button on top. `LayrzCodeEditor`'s own `readOnly`/`disabled` branch renders through that same surface — a read-only `LayrzCodeEditor` and a `LayrzCodeSnippet` showing identical source are pixel-identical.
- **No text selection.** Renders a plain `RichText`, not `EditableText` — Flutter's `SelectableText`/`SelectionArea` are Material-only and cannot be used here. The copy button is the intended extraction path.
- **Fixed monospace font.** Code always renders in JetBrains Mono, regardless of the app's own typography.
- **No responsive layout of its own.** Does not read `context.isCompact`/`context.breakpoint`. Sizes to content horizontally (long lines scroll rather than wrap) and, absent `maxHeight`, to the code's full natural height vertically — wrap in a `SizedBox`/`ConstrainedBox` or set `maxHeight` on narrow viewports.
- **Accessibility.** The code body has no interactive semantics (static text, fully readable by a screen reader via the `RichText` content, but not selectable to an arbitrary sub-range). The copy button is a real interactive control with independent semantics.
