import 'package:flutter/widgets.dart';

import 'package:layrz_ui/src/code/src/code_copy_button.dart';
import 'package:layrz_ui/src/code/src/code_surface.dart';
import 'package:layrz_ui/src/constants/constants.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/highlight/highlight.dart';

/// A read-only, syntax-highlighted code snippet with an optional copy button.
///
/// This is the "just show me the code" widget — a static block of source,
/// always rendered in the code module's dark theme (code widgets never
/// follow the app's light theme), with a small affordance in the top-right
/// corner to copy [code] to the clipboard.
///
/// All highlighting, gutter, and scrolling behavior is delegated to
/// [LayrzCodeSurface] — this widget only adds the copy button on top of it.
/// For an editable surface, see the (forthcoming) code editor widget instead.
class LayrzCodeSnippet extends StatelessWidget {
  /// The source code to display.
  final String code;

  /// The language used to syntax-highlight [code].
  final LayrzCodeLanguage language;

  /// Whether to draw a line-number gutter to the left of the code.
  ///
  /// Defaults to `false`.
  final bool showLineNumbers;

  /// The maximum height of the code area.
  ///
  /// When the rendered code exceeds this height, [LayrzCodeSurface] scrolls
  /// internally rather than growing past it. `null` (the default) leaves the
  /// height unconstrained, sizing to the code's natural height.
  final double? maxHeight;

  /// Whether to show the [LayrzCodeCopyButton] overlaid in the top-right
  /// corner of the snippet.
  ///
  /// Defaults to `true`.
  final bool showCopyButton;

  /// The font size, in logical pixels, used to render [code].
  ///
  /// Defaults to `14`.
  final double fontSize;

  /// The padding applied around [code] inside the surface.
  ///
  /// `null` defers to [LayrzCodeSurface]'s own default padding.
  final EdgeInsets? padding;

  /// Creates a new [LayrzCodeSnippet].
  ///
  /// [code] and [language] are required; every other parameter has a default
  /// suited to a plain, read-only snippet display.
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

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        LayrzCodeSurface(
          code: code,
          language: language,
          showLineNumbers: showLineNumbers,
          maxHeight: maxHeight,
          fontSize: fontSize,
          padding: padding,
          reservedTrailingSpace: showCopyButton ? kLayrzButtonCompactHeight + context.tokens.spacing.sp1 : 0,
        ),
        if (showCopyButton)
          Positioned(
            top: 0,
            right: 0,
            child: LayrzCodeCopyButton(text: code),
          ),
      ],
    );
  }
}
