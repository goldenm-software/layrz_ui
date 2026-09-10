import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:markdown/markdown.dart' as md;

import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/fonts/fonts.dart';

/// Builds an [InlineSpan] tree from a run of `package:markdown` inline AST
/// [md.Node]s.
///
/// This is the counterpart of `markdown_block_renderer.dart` for inline
/// content — bold, italic, strikethrough, inline code, links, and plain
/// text. It follows the same recursive style-merge pattern as
/// `LayrzTooltip`'s `_mergeTextStyleWithSpan` (see
/// `lib/src/tooltips/src/tooltip.dart`): every recursive call receives the
/// [TextStyle] its parent has already accumulated and layers its own tag's
/// contribution on top via [TextStyle.merge], so nested formatting (e.g.
/// bold *inside* italic) composes correctly no matter how deep.
///
/// Every [TapGestureRecognizer] created for a link is appended to
/// [recognizerSink] rather than owned locally, so `LayrzMarkdown`'s
/// [State] can dispose them all on rebuild/dispose — recognizers are the one
/// piece of this renderer that is not stateless, since Flutter requires a
/// gesture recognizer to be explicitly disposed.
///
/// [renderInlineNodes] is the sole entry point; every other member here is
/// an internal helper.
class LayrzMarkdownInlineRenderer {
  const LayrzMarkdownInlineRenderer._();

  /// Renders [nodes] as a single [TextSpan] tree.
  ///
  /// [baseStyle] is the starting style (typically the resolved body style
  /// for the enclosing block); [context] supplies theme tokens for link
  /// color and the inline-code chip; [onTapLink] is forwarded from
  /// `LayrzMarkdown.onTapLink`; [recognizerSink] collects every
  /// [TapGestureRecognizer] created while rendering a link, for the caller
  /// to dispose later.
  static TextSpan renderInlineNodes({
    required List<md.Node> nodes,
    required TextStyle baseStyle,
    required BuildContext context,
    required void Function(String href, String? title)? onTapLink,
    required List<TapGestureRecognizer> recognizerSink,
  }) {
    return TextSpan(
      style: baseStyle,
      children: nodes
          .map(
            (node) => _renderNode(
              node,
              style: baseStyle,
              context: context,
              onTapLink: onTapLink,
              recognizerSink: recognizerSink,
            ),
          )
          .toList(),
    );
  }

  /// Renders a single inline AST [node] as an [InlineSpan], recursing into
  /// its children (if any) with [style] merged with this node's own
  /// contribution.
  static InlineSpan _renderNode(
    md.Node node, {
    required TextStyle style,
    required BuildContext context,
    required void Function(String href, String? title)? onTapLink,
    required List<TapGestureRecognizer> recognizerSink,
  }) {
    if (node is md.Text) {
      return TextSpan(text: node.text, style: style);
    }

    if (node is! md.Element) {
      return TextSpan(text: node.textContent, style: style);
    }

    switch (node.tag) {
      case 'strong':
        return _renderChildren(
          node,
          style: style.merge(const TextStyle(fontVariations: [FontVariation('wght', 700)])),
          context: context,
          onTapLink: onTapLink,
          recognizerSink: recognizerSink,
        );
      case 'em':
        return _renderChildren(
          node,
          style: style.merge(const TextStyle(fontStyle: FontStyle.italic)),
          context: context,
          onTapLink: onTapLink,
          recognizerSink: recognizerSink,
        );
      case 'del':
        return _renderChildren(
          node,
          style: style.merge(const TextStyle(decoration: TextDecoration.lineThrough)),
          context: context,
          onTapLink: onTapLink,
          recognizerSink: recognizerSink,
        );
      case 'code':
        return _renderInlineCode(node, context: context, baseStyle: style);
      case 'a':
        return _renderLink(
          node,
          style: style,
          context: context,
          onTapLink: onTapLink,
          recognizerSink: recognizerSink,
        );
      default:
        return _renderChildren(
          node,
          style: style,
          context: context,
          onTapLink: onTapLink,
          recognizerSink: recognizerSink,
        );
    }
  }

  /// Renders [node]'s children as a [TextSpan], each merging [style] with
  /// its own contribution.
  static TextSpan _renderChildren(
    md.Element node, {
    required TextStyle style,
    required BuildContext context,
    required void Function(String href, String? title)? onTapLink,
    required List<TapGestureRecognizer> recognizerSink,
  }) {
    return TextSpan(
      style: style,
      children: (node.children ?? const <md.Node>[])
          .map(
            (child) => _renderNode(
              child,
              style: style,
              context: context,
              onTapLink: onTapLink,
              recognizerSink: recognizerSink,
            ),
          )
          .toList(),
    );
  }

  /// Renders an inline `code` element as a small rounded chip — a
  /// [WidgetSpan] wrapping a [DecoratedBox] with JetBrains Mono text —
  /// rather than a plain colored [TextSpan], so inline code reads visually
  /// distinct from surrounding prose the same way it does on GitHub/most
  /// Markdown renderers.
  static WidgetSpan _renderInlineCode(md.Element node, {required BuildContext context, required TextStyle baseStyle}) {
    final tokens = context.tokens;
    const font = LayrzJetBrainsMonoFont();
    final codeStyle = font.body.copyWith(
      fontSize: (baseStyle.fontSize ?? 14) * 0.9,
      color: tokens.colors.fg1,
    );

    return WidgetSpan(
      alignment: PlaceholderAlignment.baseline,
      baseline: TextBaseline.alphabetic,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tokens.colors.sf3,
          borderRadius: tokens.radius.br1,
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: tokens.spacing.sp1, vertical: 1),
          child: Text(node.textContent, style: codeStyle),
        ),
      ),
    );
  }

  /// Renders an `a` element as its child spans, underlined and colored with
  /// the theme's primary color, with a [TapGestureRecognizer] wired to
  /// invoke [onTapLink] with the element's `href`/`title` attributes.
  ///
  /// If the link has no visible text (an empty `[]( url )`), the href itself
  /// is displayed instead of rendering nothing or the literal string
  /// `"null"`.
  static InlineSpan _renderLink(
    md.Element node, {
    required TextStyle style,
    required BuildContext context,
    required void Function(String href, String? title)? onTapLink,
    required List<TapGestureRecognizer> recognizerSink,
  }) {
    final href = node.attributes['href'] ?? '';
    final title = node.attributes['title'];
    final linkStyle = style.merge(
      TextStyle(color: context.tokens.colors.primary, decoration: TextDecoration.underline),
    );

    final recognizer = TapGestureRecognizer()..onTap = () => onTapLink?.call(href, title);
    recognizerSink.add(recognizer);

    final hasVisibleText = (node.textContent).trim().isNotEmpty;
    if (!hasVisibleText) {
      return TextSpan(text: href, style: linkStyle, recognizer: recognizer);
    }

    return TextSpan(
      style: linkStyle,
      recognizer: recognizer,
      children: (node.children ?? const <md.Node>[])
          .map(
            (child) => _renderNode(
              child,
              style: linkStyle,
              context: context,
              onTapLink: onTapLink,
              recognizerSink: recognizerSink,
            ),
          )
          .toList(),
    );
  }
}
