import 'package:flutter/widgets.dart';

import 'package:layrz_ui/src/code/src/code_theme_extension.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/highlight/highlight.dart';

/// The shared, read-only syntax-highlighted code renderer.
///
/// [LayrzCodeSurface] is the rendering core reused by `LayrzCodeSnippet` and by
/// `LayrzCodeEditor`'s read-only/disabled branch — anywhere source code needs
/// to be displayed with highlighting but not edited. It tokenizes [code] with
/// [LayrzSyntaxHighlighter.tokenize] and paints the result as a single
/// [RichText], optionally with a line-number gutter.
///
/// **Always dark.** Every color painted here comes from a
/// [LayrzCodeThemeExtension] (falling back to [LayrzCodeThemeExtension.dark]
/// when the active theme has not registered one) — this widget never reads
/// light-mode tokens, matching the code surfaces' fixed dark presentation.
///
/// **Read-only, v1 has no text selection.** This widget renders a plain
/// [RichText] with no [EditableText] and no controller. Flutter's built-in
/// selectable-text widgets (`SelectableText`, `SelectionArea`) live in the
/// Material library, which this package cannot import, and the library's
/// Material-free selection controls
/// (`lib/src/selection/src/selection_controls.dart`) are not wired into a
/// bare [RichText] here. Selection is therefore explicitly out of scope for
/// this surface's first version; callers that need copyable code should pair
/// this widget with `LayrzCodeCopyButton` instead.
class LayrzCodeSurface extends StatelessWidget {
  /// The source code to render.
  final String code;

  /// The language used to tokenize [code] for syntax highlighting.
  final LayrzCodeLanguage language;

  /// Whether to render a line-number gutter to the left of the code.
  ///
  /// Defaults to `false`.
  final bool showLineNumbers;

  /// The maximum height of the scrollable code area.
  ///
  /// When set, the surface is constrained to this height and scrolls
  /// vertically past it. When `null`, the surface sizes itself to the full
  /// height of [code].
  final double? maxHeight;

  /// The font size used for both the code and the line-number gutter.
  ///
  /// Defaults to `14`.
  final double fontSize;

  /// The padding around the code area.
  ///
  /// When `null`, falls back to `context.tokens.spacing.pd3` (16px all
  /// around).
  final EdgeInsets? padding;

  /// Creates a read-only, syntax-highlighted [LayrzCodeSurface].
  const LayrzCodeSurface({
    super.key,
    required this.code,
    required this.language,
    this.showLineNumbers = false,
    this.maxHeight,
    this.fontSize = 14,
    this.padding,
  });

  /// Resolves the active [LayrzCodeThemeExtension], falling back to the
  /// always-available dark default when the current theme has not
  /// registered one.
  LayrzCodeThemeExtension _resolveCodeTheme(BuildContext context) {
    return context.maybeThemeExtension<LayrzCodeThemeExtension>() ?? const LayrzCodeThemeExtension.dark();
  }

  /// Builds the highlighted [TextSpan] tree for [code] under [codeTheme].
  ///
  /// The engine guarantees the returned tokens are non-overlapping and cover
  /// every character of [code], but this loop still defends against a gap by
  /// falling back to the plain [LayrzHighlightScope.text] style for any span
  /// it did not expect, so a future engine change can never leave a hole in
  /// the rendered text.
  TextSpan _buildHighlightedSpan(LayrzCodeThemeExtension codeTheme) {
    final tokens = LayrzSyntaxHighlighter.tokenize(code, language);
    final styles = codeTheme.resolveStyles(fontSize: fontSize);
    final defaultStyle =
        styles[LayrzHighlightScope.text] ?? codeTheme.styleForScope(LayrzHighlightScope.text, fontSize: fontSize);

    final spans = <TextSpan>[];
    var covered = 0;
    for (final token in tokens) {
      if (token.start > covered) {
        spans.add(TextSpan(text: code.substring(covered, token.start), style: defaultStyle));
      }
      spans.add(
        TextSpan(
          text: code.substring(token.start, token.end),
          style: styles[token.scope] ?? defaultStyle,
        ),
      );
      covered = token.end;
    }
    if (covered < code.length) {
      spans.add(TextSpan(text: code.substring(covered), style: defaultStyle));
    }

    return TextSpan(style: defaultStyle, children: spans);
  }

  /// Builds the right-aligned line-number gutter for [lineCount] lines.
  ///
  /// Uses the same [strutStyle] as the code [RichText] so both columns share
  /// an identical line height and stay vertically aligned row for row.
  Widget _buildGutter({
    required int lineCount,
    required LayrzCodeThemeExtension codeTheme,
    required StrutStyle strutStyle,
    required TextStyle gutterStyle,
  }) {
    final buffer = StringBuffer();
    for (var i = 1; i <= lineCount; i++) {
      buffer.writeln(i);
    }
    // Drop the trailing newline `writeln` added after the last number so the
    // gutter's line count matches the code's exactly.
    final text = buffer.toString().trimRight();

    return DecoratedBox(
      decoration: BoxDecoration(color: codeTheme.gutterBackground),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: RichText(
          strutStyle: strutStyle,
          textAlign: TextAlign.right,
          text: TextSpan(text: text, style: gutterStyle),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final codeTheme = _resolveCodeTheme(context);
    final tokens = context.tokens;
    final resolvedPadding = padding ?? tokens.spacing.pd3;
    final gutterStyle = codeTheme
        .styleForScope(LayrzHighlightScope.text, fontSize: fontSize)
        .copyWith(
          color: codeTheme.gutterForeground,
        );
    final strutStyle = StrutStyle(fontSize: fontSize, height: gutterStyle.height ?? 1.4, forceStrutHeight: true);

    final lineCount = code.isEmpty ? 1 : code.split('\n').length;

    Widget codeContent = RichText(
      strutStyle: strutStyle,
      text: _buildHighlightedSpan(codeTheme),
    );

    // Horizontal scroll keeps long lines from wrapping or overflowing.
    codeContent = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(padding: resolvedPadding, child: codeContent),
    );

    Widget body = codeContent;
    if (showLineNumbers) {
      body = IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(top: resolvedPadding.top, bottom: resolvedPadding.bottom),
              child: _buildGutter(
                lineCount: lineCount,
                codeTheme: codeTheme,
                strutStyle: strutStyle,
                gutterStyle: gutterStyle,
              ),
            ),
            Expanded(child: body),
          ],
        ),
      );
    }

    // Vertical scroll only kicks in meaningfully once maxHeight constrains
    // the surface; without it the surface simply sizes to content.
    body = SingleChildScrollView(child: body);
    if (maxHeight != null) {
      body = ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight!),
        child: body,
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: codeTheme.background,
        borderRadius: tokens.radius.br2,
      ),
      child: ClipRRect(
        borderRadius: tokens.radius.br2,
        child: body,
      ),
    );
  }
}
