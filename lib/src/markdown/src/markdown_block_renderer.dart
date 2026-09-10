import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import 'package:layrz_ui/src/extensions/extensions.dart';

import 'markdown_block.dart';
import 'markdown_code_fence.dart';
import 'markdown_inline_renderer.dart';

/// Renders a single [LayrzMarkdownBlock] as a [Widget].
///
/// This is the block-level counterpart of `markdown_inline_renderer.dart` —
/// it decides layout (headings, paragraph spacing, list bullets/numbers and
/// their indentation, code fences) while delegating every run of inline
/// content to [LayrzMarkdownInlineRenderer].
class LayrzMarkdownBlockRenderer {
  const LayrzMarkdownBlockRenderer._();

  /// Renders [block] as a [Widget].
  ///
  /// [context] supplies theme tokens; [bodyStyle] is the resolved body text
  /// style (already applying `LayrzMarkdown.bodyStyleOverride` if any);
  /// [blockSpacing] is the vertical gap reserved around block-level elements
  /// that need it (currently only [LayrzMarkdownCodeFence]); [onTapLink] and
  /// [recognizerSink] are forwarded to [LayrzMarkdownInlineRenderer] for any
  /// inline content this block carries.
  static Widget renderBlock(
    LayrzMarkdownBlock block, {
    required BuildContext context,
    required TextStyle bodyStyle,
    required double blockSpacing,
    required void Function(String href, String? title)? onTapLink,
    required List<TapGestureRecognizer> recognizerSink,
  }) {
    switch (block) {
      case LayrzMarkdownHeadingBlock():
        return _renderHeading(
          block,
          context: context,
          onTapLink: onTapLink,
          recognizerSink: recognizerSink,
        );
      case LayrzMarkdownParagraphBlock():
        return _renderParagraph(
          block,
          context: context,
          bodyStyle: bodyStyle,
          onTapLink: onTapLink,
          recognizerSink: recognizerSink,
        );
      case LayrzMarkdownUnorderedListBlock():
        return _renderUnorderedList(
          block,
          context: context,
          bodyStyle: bodyStyle,
          blockSpacing: blockSpacing,
          onTapLink: onTapLink,
          recognizerSink: recognizerSink,
        );
      case LayrzMarkdownOrderedListBlock():
        return _renderOrderedList(
          block,
          context: context,
          bodyStyle: bodyStyle,
          blockSpacing: blockSpacing,
          onTapLink: onTapLink,
          recognizerSink: recognizerSink,
        );
      case LayrzMarkdownCodeFenceBlock():
        return LayrzMarkdownCodeFence(block: block, blockSpacing: blockSpacing);
      case LayrzMarkdownPendingBlock():
        final inner = block.inner;
        if (inner == null) {
          return const SizedBox.shrink();
        }
        return renderBlock(
          inner,
          context: context,
          bodyStyle: bodyStyle,
          blockSpacing: blockSpacing,
          onTapLink: onTapLink,
          recognizerSink: recognizerSink,
        );
    }
  }

  /// Renders an `h1`–`h6` heading.
  ///
  /// - `h1` uses `typography.headline` and gets a 2px full-width divider
  ///   painted below it, in `border.dividerColor`.
  /// - `h2` uses `typography.title`.
  /// - `h3`–`h6` use `typography.body`, with descending weight expressed via
  ///   `fontVariations` (the body font is a variable font, so `fontWeight`
  ///   would silently no-op) — `h3` at `600`, stepping down by `100` per
  ///   level to `h6` at `300`.
  static Widget _renderHeading(
    LayrzMarkdownHeadingBlock block, {
    required BuildContext context,
    required void Function(String href, String? title)? onTapLink,
    required List<TapGestureRecognizer> recognizerSink,
  }) {
    final tokens = context.tokens;
    final TextStyle style;
    switch (block.level) {
      case 1:
        style = tokens.typography.headline;
      case 2:
        style = tokens.typography.title;
      default:
        // h3 (level 3) starts at weight 600 and steps down by 100 per
        // additional level, bottoming out at 300 for h6 (level 6).
        final weight = (600 - (block.level - 3) * 100).clamp(300, 600).toDouble();
        style = tokens.typography.body.merge(TextStyle(fontVariations: [FontVariation('wght', weight)]));
    }

    final span = LayrzMarkdownInlineRenderer.renderInlineNodes(
      nodes: block.inlineNodes,
      baseStyle: style,
      context: context,
      onTapLink: onTapLink,
      recognizerSink: recognizerSink,
    );

    final text = Text.rich(span);

    if (block.level != 1) {
      return text;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        text,
        SizedBox(height: tokens.spacing.sp1),
        DecoratedBox(
          decoration: BoxDecoration(color: tokens.border.dividerColor),
          child: const SizedBox(height: 2, width: double.infinity),
        ),
      ],
    );
  }

  /// Renders a paragraph as its inline content under [bodyStyle].
  static Widget _renderParagraph(
    LayrzMarkdownParagraphBlock block, {
    required BuildContext context,
    required TextStyle bodyStyle,
    required void Function(String href, String? title)? onTapLink,
    required List<TapGestureRecognizer> recognizerSink,
  }) {
    final span = LayrzMarkdownInlineRenderer.renderInlineNodes(
      nodes: block.inlineNodes,
      baseStyle: bodyStyle,
      context: context,
      onTapLink: onTapLink,
      recognizerSink: recognizerSink,
    );
    return Text.rich(span);
  }

  /// Renders an unordered list as a [Column] of bullet rows.
  ///
  /// Each row is `[bullet, spacing, Expanded(content)]`, with the bullet a
  /// small circular [DecoratedBox] sized `0.4 * fontSize` in `colors.fg1`,
  /// `10px` of leading padding and `8px` of trailing spacing below it before
  /// the next item — matching this brief's spec. Indentation for a nested
  /// list is `block.level * spacing.sp3`, driven purely by [block]'s nesting
  /// level rather than any leading-whitespace count in the source Markdown.
  static Widget _renderUnorderedList(
    LayrzMarkdownUnorderedListBlock block, {
    required BuildContext context,
    required TextStyle bodyStyle,
    required double blockSpacing,
    required void Function(String href, String? title)? onTapLink,
    required List<TapGestureRecognizer> recognizerSink,
  }) {
    final tokens = context.tokens;
    final bulletSize = (bodyStyle.fontSize ?? 14) * 0.4;
    final indent = block.level * tokens.spacing.sp3;

    final rows = <Widget>[];
    for (var i = 0; i < block.items.length; i++) {
      final item = block.items[i];
      final isLast = i == block.items.length - 1;
      rows.add(
        Padding(
          padding: EdgeInsets.only(left: indent, top: tokens.spacing.sp2, bottom: isLast ? 0 : tokens.spacing.sp1),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(top: (bodyStyle.fontSize ?? 14) * 0.5),
                child: DecoratedBox(
                  decoration: BoxDecoration(color: tokens.colors.fg1, shape: BoxShape.circle),
                  child: SizedBox(width: bulletSize, height: bulletSize),
                ),
              ),
              SizedBox(width: tokens.spacing.sp2),
              Expanded(
                child: _renderItemBlocks(
                  item.nestedBlocks,
                  context: context,
                  bodyStyle: bodyStyle,
                  blockSpacing: blockSpacing,
                  onTapLink: onTapLink,
                  recognizerSink: recognizerSink,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: rows);
  }

  /// Renders an ordered list as a [Column] of numbered rows.
  ///
  /// Each row is `["N.", spacing, Expanded(content)]`, with the number
  /// marker rendered at weight `100` via `fontVariations` and baseline
  /// aligned with the content, `10px` of leading padding and `6px` of
  /// trailing spacing below it before the next item. Numbering starts at
  /// `block.start` (the source's declared start, e.g. `3.` starts at `3`).
  /// Indentation for a nested list is `block.level * spacing.sp3`, driven
  /// purely by [block]'s nesting level.
  static Widget _renderOrderedList(
    LayrzMarkdownOrderedListBlock block, {
    required BuildContext context,
    required TextStyle bodyStyle,
    required double blockSpacing,
    required void Function(String href, String? title)? onTapLink,
    required List<TapGestureRecognizer> recognizerSink,
  }) {
    final tokens = context.tokens;
    final indent = block.level * tokens.spacing.sp3;
    final markerStyle = bodyStyle.merge(const TextStyle(fontVariations: [FontVariation('wght', 100)]));

    final rows = <Widget>[];
    for (var i = 0; i < block.items.length; i++) {
      final item = block.items[i];
      final isLast = i == block.items.length - 1;
      final number = block.start + i;
      rows.add(
        Padding(
          padding: EdgeInsets.only(left: indent, top: tokens.spacing.sp2, bottom: isLast ? 0 : tokens.spacing.sp1),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('$number.', style: markerStyle),
              SizedBox(width: tokens.spacing.sp2),
              Expanded(
                child: _renderItemBlocks(
                  item.nestedBlocks,
                  context: context,
                  bodyStyle: bodyStyle,
                  blockSpacing: blockSpacing,
                  onTapLink: onTapLink,
                  recognizerSink: recognizerSink,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: rows);
  }

  /// Renders a list item's nested blocks (usually one paragraph, optionally
  /// followed by a nested list) as a single [Column].
  static Widget _renderItemBlocks(
    List<LayrzMarkdownBlock> blocks, {
    required BuildContext context,
    required TextStyle bodyStyle,
    required double blockSpacing,
    required void Function(String href, String? title)? onTapLink,
    required List<TapGestureRecognizer> recognizerSink,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: blocks
          .map(
            (nested) => renderBlock(
              nested,
              context: context,
              bodyStyle: bodyStyle,
              blockSpacing: blockSpacing,
              onTapLink: onTapLink,
              recognizerSink: recognizerSink,
            ),
          )
          .toList(),
    );
  }
}
