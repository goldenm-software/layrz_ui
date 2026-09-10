import 'package:flutter/widgets.dart';
import 'package:markdown/markdown.dart' as md;

/// A single block-level unit of parsed Markdown content.
///
/// [LayrzMarkdown] parses its `data` string into a flat, ordered list of
/// [LayrzMarkdownBlock]s via `parseMarkdownBlocks` (see
/// `markdown_parser.dart`), then renders each one via
/// `renderMarkdownBlock` (see `markdown_block_renderer.dart`). This is a
/// sealed class so the renderer's `switch` is exhaustive and a future block
/// kind cannot be silently unhandled.
///
/// Every variant carries only the data needed to render it — inline
/// formatting (bold/italic/links/inline code) is preserved as a [md.Node]
/// tree (the `package:markdown` AST) rather than flattened early, so the
/// inline renderer can build the exact [InlineSpan] tree including tap
/// recognizers for links.
@immutable
sealed class LayrzMarkdownBlock {
  /// Creates a new [LayrzMarkdownBlock].
  const LayrzMarkdownBlock();
}

/// A Markdown heading (`#` through `######`).
final class LayrzMarkdownHeadingBlock extends LayrzMarkdownBlock {
  /// The heading level, from `1` (`#`) to `6` (`######`).
  final int level;

  /// The heading's inline content, as parsed inline AST nodes (may contain
  /// bold, italic, links, and inline code, like any other inline content).
  final List<md.Node> inlineNodes;

  /// Creates a new [LayrzMarkdownHeadingBlock].
  ///
  /// [level] and [inlineNodes] are both required.
  const LayrzMarkdownHeadingBlock({
    required this.level,
    required this.inlineNodes,
  });
}

/// A Markdown paragraph — a run of inline content with no block structure of
/// its own.
final class LayrzMarkdownParagraphBlock extends LayrzMarkdownBlock {
  /// The paragraph's inline content, as parsed inline AST nodes.
  final List<md.Node> inlineNodes;

  /// Creates a new [LayrzMarkdownParagraphBlock].
  ///
  /// [inlineNodes] is required.
  const LayrzMarkdownParagraphBlock({required this.inlineNodes});
}

/// A single item of a [LayrzMarkdownUnorderedListBlock] or
/// [LayrzMarkdownOrderedListBlock].
///
/// An item's own content is itself a list of blocks — almost always a single
/// [LayrzMarkdownParagraphBlock], but [nestedBlocks] may additionally include
/// a further [LayrzMarkdownUnorderedListBlock] or
/// [LayrzMarkdownOrderedListBlock] for a nested list under this item.
@immutable
class LayrzMarkdownListItem {
  /// The blocks that make up this list item's content, in order.
  ///
  /// A nested list (if the source Markdown indents one under this item)
  /// appears here as its own [LayrzMarkdownUnorderedListBlock] or
  /// [LayrzMarkdownOrderedListBlock] entry, carrying its own incremented
  /// [LayrzMarkdownUnorderedListBlock.level] / [LayrzMarkdownOrderedListBlock.level].
  final List<LayrzMarkdownBlock> nestedBlocks;

  /// Creates a new [LayrzMarkdownListItem].
  ///
  /// [nestedBlocks] is required.
  const LayrzMarkdownListItem({required this.nestedBlocks});
}

/// An unordered (bulleted) Markdown list.
final class LayrzMarkdownUnorderedListBlock extends LayrzMarkdownBlock {
  /// The items of this list, in order.
  final List<LayrzMarkdownListItem> items;

  /// The nesting depth of this list, starting at `0` for a top-level list.
  ///
  /// Used by the renderer to compute indentation (`level * <spacing token>`)
  /// — nesting depth drives indent, never the number of leading spaces in
  /// the source Markdown.
  final int level;

  /// Creates a new [LayrzMarkdownUnorderedListBlock].
  ///
  /// [items] is required; [level] defaults to `0`.
  const LayrzMarkdownUnorderedListBlock({required this.items, this.level = 0});
}

/// An ordered (numbered) Markdown list.
final class LayrzMarkdownOrderedListBlock extends LayrzMarkdownBlock {
  /// The items of this list, in order.
  final List<LayrzMarkdownListItem> items;

  /// The nesting depth of this list, starting at `0` for a top-level list.
  ///
  /// Used by the renderer to compute indentation (`level * <spacing token>`)
  /// — nesting depth drives indent, never the number of leading spaces in
  /// the source Markdown.
  final int level;

  /// The 1-based number of the first item, as declared by the source
  /// Markdown (e.g. `3.` starts a list at `3`).
  final int start;

  /// Creates a new [LayrzMarkdownOrderedListBlock].
  ///
  /// [items] is required; [level] and [start] default to `0` and `1`
  /// respectively.
  const LayrzMarkdownOrderedListBlock({
    required this.items,
    this.level = 0,
    this.start = 1,
  });
}

/// A fenced Markdown code block (triple-backtick or triple-tilde).
final class LayrzMarkdownCodeFenceBlock extends LayrzMarkdownBlock {
  /// The fence's info string (the text right after the opening fence, e.g.
  /// `python` in ` ```python `), verbatim as written — not yet mapped to a
  /// [LayrzCodeLanguage]. `null` when the fence carries no info string.
  final String? infoString;

  /// The literal source code inside the fence, with the trailing newline
  /// `package:markdown` appends removed.
  final String code;

  /// Creates a new [LayrzMarkdownCodeFenceBlock].
  ///
  /// [code] is required; [infoString] defaults to `null`.
  const LayrzMarkdownCodeFenceBlock({required this.code, this.infoString});
}

/// The trailing, not-yet-complete block held back during streaming.
///
/// Only ever produced when `LayrzMarkdown.isStreaming` is `true` and the
/// source text's final block cannot yet be proven complete (see
/// `markdown_parser.dart`'s streaming split for the exact rule). Wraps the
/// best-effort parse of that trailing region as [inner] so it can still be
/// rendered — typically identically to its final form — while remaining
/// distinguishable so a caller-side renderer could choose to (for instance)
/// dim it or append a typing cursor.
final class LayrzMarkdownPendingBlock extends LayrzMarkdownBlock {
  /// The best-effort parse of the trailing, incomplete source region.
  ///
  /// `null` when the trailing region produced no parseable block yet (for
  /// example, a bare opening code fence with no content after it).
  final LayrzMarkdownBlock? inner;

  /// Creates a new [LayrzMarkdownPendingBlock].
  ///
  /// [inner] defaults to `null`.
  const LayrzMarkdownPendingBlock({this.inner});
}
