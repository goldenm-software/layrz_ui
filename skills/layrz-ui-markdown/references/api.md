# LayrzMarkdown — API Reference

Source: `lib/src/markdown/src/markdown.dart`, `lib/src/markdown/src/markdown_block.dart`
- `LayrzMarkdown` class (`StatefulWidget`) — `markdown.dart`
- `LayrzMarkdownBlock` sealed class + subtypes — `markdown_block.dart`

---

## Examples

```dart
// Basic render
LayrzMarkdown(
  data: '# Hello\n\nThis is **bold** and `inline code`.',
)

// Streaming (LLM response arriving token by token)
LayrzMarkdown(
  data: partialResponse,
  isStreaming: true,
)

// Link handling
LayrzMarkdown(
  data: 'See [the docs](https://example.com) for details.',
  onTapLink: (href, title) => launchExternally(href),
)

// Overridden body style and block spacing
LayrzMarkdown(
  data: source,
  bodyStyleOverride: TextStyle(fontSize: 13, color: context.tokens.colors.fg2),
  blockSpacingOverride: 12,
)

// Center-aligned blocks
LayrzMarkdown(
  data: source,
  crossAxisAlignment: .center,
)
```

---

## Constructor

```dart
const LayrzMarkdown({
  super.key,
  required this.data,
  this.onTapLink,
  this.isStreaming = false,
  this.bodyStyleOverride,
  this.blockSpacingOverride,
  this.crossAxisAlignment = CrossAxisAlignment.start,
});
```

No asserts — `data` is the only required field.

---

## Properties

| Property | Type | Default | Notes |
|---|---|---|---|
| `data` | `String` | **required** | The Markdown source to render. Raw HTML inside it is parsed but never rendered as markup. |
| `onTapLink` | `void Function(String href, String? title)?` | `null` | Called on link tap with `href` and optional `title`. `null` renders links as plain, non-interactive styled text. This widget never launches URLs itself. |
| `isStreaming` | `bool` | `false` | When `true`, the trailing block that cannot yet be proven complete is held back rather than committed as final — see "Streaming" behavior notes. |
| `bodyStyleOverride` | `TextStyle?` | `null` | Overrides the resolved body style for paragraphs, list items, and any heading level without a dedicated style. `null` falls back to `context.tokens.typography.body`. |
| `blockSpacingOverride` | `double?` | `null` | Overrides the vertical spacing reserved around block-level elements. `null` falls back to `context.tokens.spacing.sp3`. |
| `crossAxisAlignment` | `CrossAxisAlignment` | `CrossAxisAlignment.start` | Horizontal alignment applied to the column of rendered blocks. |

---

## Supported Markdown

- Headings `h1`–`h6` (`h1` carries an underline rule; `h2` → title scale; `h3`–`h6` → body scale, descending weight).
- Emphasis — bold, italic, strikethrough, and combinations.
- Lists — ordered and unordered, including nested lists (indented by nesting level).
- Links — surfaced via `onTapLink`; empty link text falls back to displaying the href.
- Inline code — rendered as a small rounded monospace chip.
- Fenced code blocks — rendered through `LayrzCodeSnippet`. The fence's info string maps to `LayrzCodeLanguage` (`python`/`py`, `lcl`, `lml`); anything else (or none) falls back to `.plain`.

**Not supported** (skipped, not mis-rendered): tables, blockquotes, thematic breaks.

---

## `LayrzMarkdownBlock` sealed class

The AST-level block model `LayrzMarkdown` parses `data` into internally (`markdown_block.dart`). Not typically constructed by consumers — documented here because it is a public, exported sealed hierarchy.

| Subtype | Fields | Notes |
|---|---|---|
| `LayrzMarkdownHeadingBlock` | `level` (`int`, 1–6), `inlineNodes` (`List<md.Node>`) | A `#`–`######` heading. |
| `LayrzMarkdownParagraphBlock` | `inlineNodes` (`List<md.Node>`) | A run of inline content with no block structure of its own. |
| `LayrzMarkdownUnorderedListBlock` | `items` (`List<LayrzMarkdownListItem>`), `level` (`int`, default `0`) | A bulleted list; `level` drives indentation. |
| `LayrzMarkdownOrderedListBlock` | `items`, `level` (default `0`), `start` (`int`, default `1`) | A numbered list; `start` is the first item's declared number. |
| `LayrzMarkdownCodeFenceBlock` | `code` (`String`), `infoString` (`String?`) | A fenced code block; `infoString` is the fence's language tag, verbatim, not yet mapped to `LayrzCodeLanguage`. |
| `LayrzMarkdownPendingBlock` | `inner` (`LayrzMarkdownBlock?`) | The trailing, not-yet-complete block held back during streaming — only ever produced when `isStreaming: true`. `inner` is `null` when the trailing region produced no parseable block yet (e.g. a bare opening fence). |

`LayrzMarkdownListItem` (a plain `@immutable` class, not part of the sealed hierarchy) holds a list item's `nestedBlocks` (`List<LayrzMarkdownBlock>`) — almost always one `LayrzMarkdownParagraphBlock`, plus an optional nested list block for indented sub-lists.

Being `sealed`, a `switch` over `LayrzMarkdownBlock` is exhaustive — a future block kind cannot be silently unhandled by custom rendering code built against this hierarchy.

---

## Behavior notes

- **Why a `StatefulWidget`.** Every rendered link attaches a `TapGestureRecognizer`, which Flutter requires to be explicitly disposed. `LayrzMarkdown` disposes the previous batch immediately before every `build` (including the first) and disposes the final batch in `dispose()` — this is entirely internal; callers do nothing extra.
- **Streaming split.** `LayrzMarkdownParser.splitForStreaming` decides what counts as "not yet provably complete": an unclosed code fence, or a trailing line not yet terminated by a newline. That trailing region is wrapped as a `LayrzMarkdownPendingBlock` and still rendered (so partial output stays visible while streaming), just tagged distinctly so a future revision could dim it or append a typing cursor.
- **Material-free.** Every block is built on `package:flutter/widgets.dart` and `dart:ui` — no `flutter_markdown` (which descends from Material) or any Material/Cupertino import anywhere in this module.
- **Parsing engine.** `package:markdown` (pure Dart, zero Flutter coupling) produces the AST; `LayrzMarkdown` hand-rolls the AST-to-widget rendering on top of it.
