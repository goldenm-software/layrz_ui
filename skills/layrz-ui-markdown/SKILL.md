---
name: layrz-ui-markdown
description: Use LayrzMarkdown in a layrz_ui Flutter widget. Apply when rendering Markdown text as themed rich content — assistant/LLM responses, backend-emitted Markdown, streaming output with `isStreaming`, or any body text that carries headings, emphasis, lists, links, inline code, or fenced code blocks.
---

> **Dart syntax:** This library requires Dart ≥ 3.13. Use dot shorthand for all enum values (e.g. `.start`) — never the fully-qualified form (`CrossAxisAlignment.start`).

> **Full constructor and property reference:** read `references/api.md` in this skill's directory.

---

## When to use

- Rendering a Markdown string from an LLM/assistant or a Layrz backend as rich, themed content — headings, bold/italic/strikethrough, lists, links, inline code, and fenced code blocks.
- Streaming assistant output: pass `isStreaming: true` while text is still arriving so the trailing incomplete block (an unclosed fence, an unterminated line) is held back rather than flashing half-formed syntax.
- **Do not use** for plain, non-Markdown body text — use a themed `Text` widget instead; parsing overhead buys nothing.
- **Do not use** as an editable Markdown source field — this is render-only, with no source view or edit affordance. There is no editable counterpart in this module.
- **Do not use** for a standalone block of code with no surrounding prose — use `LayrzCodeSnippet` directly; `LayrzMarkdown` only reaches for it internally for fenced code *inside* a document.

---

## Minimal usage

```dart
LayrzMarkdown(
  data: '# Hello\n\nThis is **bold** and `inline code`.\n\n- a list item\n- another',
)
```

---

## Key behaviors

- `data` is the only required parameter — plain Markdown transport text, the same format an LLM or backend emits.
- **Raw HTML is dropped, never rendered.** Any HTML embedded in `data` (`<b>hi</b>`, `<img onerror=...>`) is parsed but silently discarded rather than interpreted — this widget is not an injection surface.
- **Links never launch.** Tapping a link calls `onTapLink(href, title)` and nothing else; `LayrzMarkdown` never calls `launchUrl` or any platform API. `onTapLink: null` (the default) renders links as plain, non-interactive styled text.
- **Streaming-aware.** `isStreaming: true` holds back the trailing block that cannot yet be proven complete. Keep passing `true` while output is arriving, then rebuild with `false` once it is final.
- Fenced code blocks render through `LayrzCodeSnippet`. The fence's info string maps to a `LayrzCodeLanguage` (`python`/`py`, `lcl`, `lml`); anything else (or no info string) falls back to `.plain` — unhighlighted monospace, never an error.
- **Out of scope, skipped rather than mis-rendered:** tables, blockquotes, and thematic breaks (`---`). Do not rely on them appearing.
- This is a `StatefulWidget` internally (it owns `TapGestureRecognizer`s for links, disposed and rebuilt every `build`) — treat it like any other widget; no special lifecycle handling is required from the caller.

---

## Common patterns

```dart
// 1. Streaming assistant response
LayrzMarkdown(
  data: accumulatedText,
  isStreaming: !responseComplete,
  onTapLink: (href, title) => openExternalLink(href),
)

// 2. Static backend-rendered Markdown, default styling
LayrzMarkdown(data: caseNote.body)

// 3. Overriding body style and block spacing
LayrzMarkdown(
  data: reportSummary,
  bodyStyleOverride: context.tokens.typography.body.copyWith(fontSize: 13),
  blockSpacingOverride: context.tokens.spacing.sp2,
)

// 4. Center-aligned blocks (e.g. inside a narrow card)
LayrzMarkdown(
  data: tip,
  crossAxisAlignment: .center,
)
```

---

## Usage conventions

- Pass `isStreaming` reactively (tied to the source's own "still generating" flag) — do not leave it `true` after the stream settles, or the final block stays needlessly held back.
- Always supply `onTapLink` when `data` may contain links the user should be able to follow; leaving it `null` silently strips link interactivity.
- Pair with `LayrzAiMarker` when the content is specifically assistant/AI-generated output, to visually flag its provenance.
- Never hand this widget pre-sanitized HTML expecting it to render as markup — it only ever parses Markdown syntax, and any HTML present is dropped, not sanitized-then-shown.
