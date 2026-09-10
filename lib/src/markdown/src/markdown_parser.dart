import 'package:markdown/markdown.dart' as md;

import 'markdown_block.dart';

/// The tags of `package:markdown` [md.Element]s this parser recognizes at
/// block level.
///
/// Every other tag — most notably a raw HTML block/inline node, which
/// `package:markdown` represents as an unwrapped [md.Text] rather than one
/// of these tags — is silently skipped. This is how "drop raw HTML" is
/// enforced: [parseMarkdownBlocks] never enables an HTML renderer in the
/// first place, and this walker's whitelist-by-tag approach means a node it
/// does not recognize simply produces no block, rather than being rendered
/// as markup.
const Set<String> _headingTags = {'h1', 'h2', 'h3', 'h4', 'h5', 'h6'};

/// A façade over `package:markdown` turning a Markdown source string into
/// [LayrzMarkdownBlock]s.
///
/// This is the only file in the `markdown` module that imports
/// `package:markdown` directly — every other file works with
/// [LayrzMarkdownBlock] and the `md.Node` inline-AST fragments it carries.
class LayrzMarkdownParser {
  const LayrzMarkdownParser._();

  /// Parses [source] into an ordered list of top-level [LayrzMarkdownBlock]s.
  ///
  /// Uses `package:markdown`'s [md.ExtensionSet.gitHubFlavored] extension set
  /// (fenced code, tables, strikethrough, autolinks) with HTML rendering
  /// left off entirely — `package:markdown` still *parses* raw HTML into the
  /// AST (it has no "reject HTML" mode), but it always surfaces as a bare
  /// [md.Text] node rather than one of the block tags this walker
  /// recognizes, so [_convertBlock] silently drops it. No block is ever
  /// interpreted as live HTML markup.
  ///
  /// [md.Document.encodeHtml] is explicitly set to `false`. That flag exists
  /// so an HTML *renderer* can safely re-embed source text into a `<code>`
  /// tag (escaping `<`, `&`, `"`); this widget renders straight to Flutter
  /// spans and never emits HTML, so leaving it at the package's `true`
  /// default would corrupt fenced/inline code content — e.g. a literal `"`
  /// in source turning into the four characters `&quot;` in the rendered
  /// text.
  static List<LayrzMarkdownBlock> parseBlocks(String source) {
    final document = md.Document(extensionSet: md.ExtensionSet.gitHubFlavored, encodeHtml: false);
    final nodes = document.parse(source);
    return _convertNodes(nodes);
  }

  /// Splits [source] into the blocks safe to render as final
  /// (`committedBlocks`) and, when [isStreaming] is `true`, the trailing
  /// block that may still grow (`pendingBlock`) — or `null` when every block
  /// is already committed.
  ///
  /// **The streaming rule.** `package:markdown` retains no source positions
  /// on its AST, so completeness cannot be read off a parsed node — it is
  /// decided from the raw text instead, before parsing:
  ///
  /// - [isStreaming] is `false`: every block is committed; `pendingBlock` is
  ///   always `null`. This is the common "already-finished message" path.
  /// - [isStreaming] is `true`: [source] is split into raw top-level
  ///   segments on blank lines, *except* inside a fenced code block (a blank
  ///   line inside a fence never splits it). The last segment is held back
  ///   as pending when either:
  ///   - it opens a fence (```` ``` ```` or `~~~`) that never closes within
  ///     [source] — the fence is still being typed; or
  ///   - [source] does not end with a newline — the last visible line may
  ///     still be mid-word, so its block (heading/paragraph/list item) is
  ///     not yet provably finished.
  ///
  ///   Every earlier segment is committed and parsed normally. The pending
  ///   segment is best-effort parsed on its own and wrapped in a
  ///   [LayrzMarkdownPendingBlock] so callers can distinguish it, though by
  ///   default [LayrzMarkdown] renders it exactly like any other block.
  static (List<LayrzMarkdownBlock> committedBlocks, LayrzMarkdownBlock? pendingBlock) splitForStreaming(
    String source, {
    required bool isStreaming,
  }) {
    if (!isStreaming || source.isEmpty) {
      return (parseBlocks(source), null);
    }

    final segments = _splitTopLevelSegments(source);
    if (segments.isEmpty) {
      return (const [], null);
    }

    final lastSegment = segments.last;
    final lastIsPending = _isUnterminatedFence(lastSegment) || !source.endsWith('\n');

    if (!lastIsPending) {
      return (parseBlocks(source), null);
    }

    final committedSource = segments.sublist(0, segments.length - 1).join('\n\n');
    final committedBlocks = committedSource.isEmpty ? <LayrzMarkdownBlock>[] : parseBlocks(committedSource);

    final pendingBlocks = parseBlocks(lastSegment);
    final pendingInner = pendingBlocks.isEmpty ? null : pendingBlocks.first;
    return (committedBlocks, LayrzMarkdownPendingBlock(inner: pendingInner));
  }

  /// Splits [source] into raw top-level segments on blank lines, treating a
  /// fenced code block (opened by a line starting with ` ``` ` or `~~~`) as
  /// atomic — a blank line inside an open fence never starts a new segment.
  static List<String> _splitTopLevelSegments(String source) {
    final lines = source.split('\n');
    final segments = <String>[];
    final current = <String>[];
    var inFence = false;
    String? fenceMarker;

    void flush() {
      if (current.isNotEmpty) {
        segments.add(current.join('\n'));
        current.clear();
      }
    }

    for (final line in lines) {
      final trimmed = line.trimLeft();
      final opensOrClosesFence = trimmed.startsWith('```') || trimmed.startsWith('~~~');

      if (opensOrClosesFence) {
        final marker = trimmed.startsWith('```') ? '```' : '~~~';
        if (!inFence) {
          inFence = true;
          fenceMarker = marker;
        } else if (marker == fenceMarker) {
          inFence = false;
          fenceMarker = null;
        }
        current.add(line);
        continue;
      }

      if (!inFence && trimmed.isEmpty) {
        flush();
        continue;
      }

      current.add(line);
    }
    flush();

    return segments;
  }

  /// Whether [segment] opens a fenced code block that never closes within
  /// it — an odd number of fence-marker lines of the same kind.
  static bool _isUnterminatedFence(String segment) {
    var backtickFences = 0;
    var tildeFences = 0;
    for (final line in segment.split('\n')) {
      final trimmed = line.trimLeft();
      if (trimmed.startsWith('```')) backtickFences++;
      if (trimmed.startsWith('~~~')) tildeFences++;
    }
    return backtickFences.isOdd || tildeFences.isOdd;
  }

  /// Converts a list of top-level `package:markdown` AST [md.Node]s into
  /// [LayrzMarkdownBlock]s, dropping any node this walker does not
  /// recognize (see [_headingTags] and [_convertBlock]).
  static List<LayrzMarkdownBlock> _convertNodes(List<md.Node> nodes) {
    final blocks = <LayrzMarkdownBlock>[];
    for (final node in nodes) {
      final block = _convertBlock(node, level: 0);
      if (block != null) {
        blocks.add(block);
      }
    }
    return blocks;
  }

  /// Converts a single top-level AST [node] into a [LayrzMarkdownBlock], or
  /// `null` when [node] is not a recognized block-level tag (this is where
  /// a raw HTML [md.Text] node, or any other unhandled tag, is dropped).
  static LayrzMarkdownBlock? _convertBlock(md.Node node, {required int level}) {
    if (node is! md.Element) {
      // A bare Text node at block level is raw HTML content (see the
      // class-level doc comment) or stray whitespace — never a renderable
      // block on its own.
      return null;
    }

    if (_headingTags.contains(node.tag)) {
      final headingLevel = int.parse(node.tag.substring(1));
      return LayrzMarkdownHeadingBlock(level: headingLevel, inlineNodes: node.children ?? const []);
    }

    switch (node.tag) {
      case 'p':
        return LayrzMarkdownParagraphBlock(inlineNodes: node.children ?? const []);
      case 'ul':
        return LayrzMarkdownUnorderedListBlock(
          items: _convertListItems(node.children ?? const [], level: level),
          level: level,
        );
      case 'ol':
        final start = int.tryParse(node.attributes['start'] ?? '1') ?? 1;
        return LayrzMarkdownOrderedListBlock(
          items: _convertListItems(node.children ?? const [], level: level),
          level: level,
          start: start,
        );
      case 'pre':
        return _convertCodeFence(node);
      default:
        // Blockquotes, tables, thematic breaks, and any other block tag are
        // out of scope for this first version — silently skipped rather than
        // rendered incorrectly.
        return null;
    }
  }

  /// Converts a `pre` element's single `code` child into a
  /// [LayrzMarkdownCodeFenceBlock].
  static LayrzMarkdownCodeFenceBlock? _convertCodeFence(md.Element pre) {
    final children = pre.children;
    if (children == null || children.isEmpty || children.first is! md.Element) {
      return null;
    }
    final codeElement = children.first as md.Element;
    if (codeElement.tag != 'code') {
      return null;
    }

    final rawClass = codeElement.attributes['class'];
    final infoString = rawClass != null && rawClass.startsWith('language-')
        ? rawClass.substring('language-'.length)
        : null;

    var code = codeElement.textContent;
    if (code.endsWith('\n')) {
      code = code.substring(0, code.length - 1);
    }

    return LayrzMarkdownCodeFenceBlock(code: code, infoString: infoString);
  }

  /// Converts a `ul`/`ol` element's `li` children into
  /// [LayrzMarkdownListItem]s, recursing into any nested `ul`/`ol` found
  /// among an item's children at [level] + 1.
  ///
  /// A "tight" list (see `package:markdown`'s own doc comment on this
  /// behavior) flattens each item's inline content directly into the `li`
  /// rather than wrapping it in a `p` — this method re-wraps that flattened
  /// run into an implicit [LayrzMarkdownParagraphBlock] so every item
  /// consistently exposes a list of blocks, regardless of whether the source
  /// list was tight or loose.
  static List<LayrzMarkdownListItem> _convertListItems(List<md.Node> liNodes, {required int level}) {
    final items = <LayrzMarkdownListItem>[];
    for (final liNode in liNodes) {
      if (liNode is! md.Element || liNode.tag != 'li') continue;

      final nestedBlocks = <LayrzMarkdownBlock>[];
      final looseInline = <md.Node>[];

      void flushLooseInline() {
        if (looseInline.isNotEmpty) {
          nestedBlocks.add(LayrzMarkdownParagraphBlock(inlineNodes: List.of(looseInline)));
          looseInline.clear();
        }
      }

      for (final child in liNode.children ?? const <md.Node>[]) {
        if (child is md.Element && (child.tag == 'ul' || child.tag == 'ol')) {
          flushLooseInline();
          final nestedBlock = _convertBlock(child, level: level + 1);
          if (nestedBlock != null) {
            nestedBlocks.add(nestedBlock);
          }
          continue;
        }
        if (child is md.Element && child.tag == 'p') {
          flushLooseInline();
          nestedBlocks.add(LayrzMarkdownParagraphBlock(inlineNodes: child.children ?? const []));
          continue;
        }
        looseInline.add(child);
      }
      flushLooseInline();

      items.add(LayrzMarkdownListItem(nestedBlocks: nestedBlocks));
    }
    return items;
  }
}
