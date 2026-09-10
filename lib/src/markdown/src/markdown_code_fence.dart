import 'package:flutter/widgets.dart';

import 'package:layrz_ui/src/code/code.dart';

import 'markdown_block.dart';
import 'markdown_language_mapper.dart';

/// Renders a [LayrzMarkdownCodeFenceBlock] as a [LayrzCodeSnippet], with the
/// fence's info string mapped to a [LayrzCodeLanguage] via
/// [mapMarkdownLanguage].
///
/// Wrapped in vertical margin (a spacing token, [blockSpacing]) so a fenced
/// block sits with the same rhythm as any other block in the surrounding
/// [LayrzMarkdown] output, matching `markdown_block_renderer.dart`'s
/// block-to-block spacing.
class LayrzMarkdownCodeFence extends StatelessWidget {
  /// The parsed code-fence block to render.
  final LayrzMarkdownCodeFenceBlock block;

  /// The vertical margin applied above and below the rendered snippet.
  final double blockSpacing;

  /// Creates a new [LayrzMarkdownCodeFence].
  ///
  /// [block] and [blockSpacing] are both required.
  const LayrzMarkdownCodeFence({
    super.key,
    required this.block,
    required this.blockSpacing,
  });

  @override
  Widget build(BuildContext context) {
    final language = mapMarkdownLanguage(block.infoString);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: blockSpacing / 2),
      child: LayrzCodeSnippet(
        code: block.code,
        language: language,
      ),
    );
  }
}
