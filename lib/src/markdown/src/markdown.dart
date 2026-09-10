import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import 'package:layrz_ui/src/extensions/extensions.dart';

import 'markdown_block.dart';
import 'markdown_block_renderer.dart';
import 'markdown_parser.dart';

/// Renders a Markdown source string as a column of rich, themed block
/// widgets — headings, paragraphs, bold/italic/strikethrough text, inline
/// code, links, and fenced code blocks (syntax-highlighted via
/// `LayrzCodeSnippet`, one per fence's language).
///
/// **Transport format.** [data] is plain Markdown text — the same format an
/// LLM or a Layrz backend would emit. Raw HTML embedded in [data] is parsed
/// but never rendered as markup (see `markdown_parser.dart`'s doc comment);
/// it is silently dropped rather than interpreted.
///
/// **Streaming.** When [isStreaming] is `true`, the trailing block of [data]
/// that cannot yet be proven complete (an unclosed code fence, or a line not
/// yet terminated by a newline) is held back as a
/// [LayrzMarkdownPendingBlock] rather than committed — see
/// `LayrzMarkdownParser.splitForStreaming` for the exact rule. This widget
/// still renders that pending block (so partial output is visible as it
/// streams in), just distinguished internally so a future revision could
/// treat it differently (a dimmed style, a typing cursor). When
/// [isStreaming] is `false` (the default), every block is treated as final.
///
/// **Links are never launched.** [onTapLink] is called with the link's
/// `href` and optional `title` on tap; this widget never calls `launchUrl`
/// or any platform API itself — the decision of what a link tap does
/// belongs entirely to the caller.
///
/// **Why a [StatefulWidget].** Every rendered link attaches a
/// [TapGestureRecognizer], and Flutter requires each one to be explicitly
/// disposed — a plain [StatelessWidget] has nowhere to do that. This widget
/// keeps the current batch of recognizers in [State], disposing the
/// previous batch immediately before building a new one (on every `build`,
/// including the first) and disposing the final batch in [State.dispose].
class LayrzMarkdown extends StatefulWidget {
  /// The Markdown source to render.
  ///
  /// Plain text in the Markdown transport format — the same string an LLM
  /// or backend would emit. Raw HTML inside it is parsed but never rendered
  /// as markup; see the class-level doc comment.
  final String data;

  /// Called when the reader taps a link, with its `href` and optional
  /// `title` attribute.
  ///
  /// This widget never launches URLs itself — `null` (the default) renders
  /// links as plain styled, non-interactive text.
  final void Function(String href, String? title)? onTapLink;

  /// Whether [data] is still being appended to (e.g. an LLM response
  /// streaming in token by token).
  ///
  /// When `true`, the trailing block that cannot yet be proven complete is
  /// held back as a [LayrzMarkdownPendingBlock] rather than committed as
  /// final — see the class-level doc comment. Defaults to `false`.
  final bool isStreaming;

  /// Overrides the resolved body text style used for paragraphs, list items,
  /// and any heading level that does not have its own dedicated style.
  ///
  /// `null` (the default) falls back to `context.tokens.typography.body`.
  final TextStyle? bodyStyleOverride;

  /// Overrides the vertical spacing reserved around block-level elements
  /// that need it (currently fenced code blocks).
  ///
  /// `null` (the default) falls back to `context.tokens.spacing.sp3`.
  final double? blockSpacingOverride;

  /// The horizontal alignment applied to the column of rendered blocks.
  ///
  /// Defaults to [CrossAxisAlignment.start].
  final CrossAxisAlignment crossAxisAlignment;

  /// Creates a new [LayrzMarkdown].
  ///
  /// [data] is required. Every other parameter is optional, defaulting to
  /// non-streaming, theme-derived styling with left-aligned blocks.
  const LayrzMarkdown({
    super.key,
    required this.data,
    this.onTapLink,
    this.isStreaming = false,
    this.bodyStyleOverride,
    this.blockSpacingOverride,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  @override
  State<LayrzMarkdown> createState() => _LayrzMarkdownState();
}

class _LayrzMarkdownState extends State<LayrzMarkdown> {
  /// The [TapGestureRecognizer]s created for the links in the most recently
  /// built output.
  ///
  /// Rebuilt (and the previous batch disposed) on every [build], and fully
  /// disposed in [dispose].
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void didUpdateWidget(covariant LayrzMarkdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Nothing to do here explicitly: `build` always re-renders from
    // `widget.data`/`widget.onTapLink`/`widget.isStreaming` and disposes the
    // previous recognizer batch itself, so a changed value is picked up
    // automatically on the next build Flutter schedules for this update.
  }

  /// Disposes every recognizer collected during the previous build and
  /// clears the batch, so a fresh build can start collecting a new one.
  void _disposeRecognizers() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _disposeRecognizers();

    final tokens = context.tokens;
    final bodyStyle = widget.bodyStyleOverride ?? tokens.typography.body;
    final blockSpacing = widget.blockSpacingOverride ?? tokens.spacing.sp3;

    final (committedBlocks, pendingBlock) = LayrzMarkdownParser.splitForStreaming(
      widget.data,
      isStreaming: widget.isStreaming,
    );

    final blocks = <LayrzMarkdownBlock>[...committedBlocks, ?pendingBlock];

    final children = <Widget>[];
    for (var i = 0; i < blocks.length; i++) {
      if (i > 0) {
        children.add(SizedBox(height: blockSpacing));
      }
      children.add(
        LayrzMarkdownBlockRenderer.renderBlock(
          blocks[i],
          context: context,
          bodyStyle: bodyStyle,
          blockSpacing: blockSpacing,
          onTapLink: widget.onTapLink,
          recognizerSink: _recognizers,
        ),
      );
    }

    return Column(
      crossAxisAlignment: widget.crossAxisAlignment,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }
}
