import 'package:flutter/widgets.dart';

import 'package:layrz_ui/src/code/src/code_error.dart';
import 'package:layrz_ui/src/code/src/code_theme_extension.dart';
import 'package:layrz_ui/src/constants/constants.dart';
import 'package:layrz_ui/src/fonts/fonts.dart';
import 'package:layrz_ui/src/tooltips/tooltips.dart';

/// The line-number gutter drawn to the left of [LayrzCodeEditor]'s editable
/// text.
///
/// The line numbers are rendered as a **single** [RichText] sharing the exact
/// same [StrutStyle] as the code text (the same approach `LayrzCodeSurface`
/// uses for its read-only gutter). This is what keeps row `N` of the gutter
/// flush against line `N` of the code: because both columns are laid out by
/// the identical strut, their line boxes have the same height and the same
/// baseline distribution, so the numbers never drift as the document grows.
/// A per-row `Column` of individually-centered `Text` boxes — the earlier
/// approach — does *not* share the code's strut and drifts cumulatively.
///
/// Per-line backgrounds (the [currentLine] highlight and the tonal-red error
/// band) are painted as [Positioned] layers **behind** the numbers, each at
/// `(line - 1) * lineHeight`, so they line up with the code-area bands that
/// [LayrzCodeEditor] positions on the same math.
///
/// **Precedence**: an error-marked line always wins its background over the
/// current-line highlight, even when the caret sits on that very line —
/// [errorsByLine] is consulted before [currentLine]. This gutter paints only
/// its half (left) of the full-width error band; [LayrzCodeEditor]'s editable
/// branch paints the matching background behind the code area on the right so
/// the two halves read as one continuous row.
///
/// **Scroll-sync contract**: this widget renders with **no scrolling of its
/// own** — [LayrzCodeEditor] places it and the editable text side by side
/// inside one shared [SingleChildScrollView], so both columns move together
/// under a single [ScrollController] and line `N` always lines up between the
/// two. It must never be wrapped in a second scroll view by its caller.
class LayrzCodeGutter extends StatelessWidget {
  /// The total number of lines to render one gutter row for.
  ///
  /// Typically `code.split('\n').length` of the document currently being
  /// edited.
  final int lineCount;

  /// The 1-based line number the caret currently sits on, or `null` when no
  /// line should be highlighted (e.g. the field has never been focused).
  final int? currentLine;

  /// The height, in logical pixels, of a single gutter row.
  ///
  /// Must equal the line height of the code text rendered alongside this
  /// gutter (`kCodeLineHeightFactor * fontSize`), or line numbers will drift
  /// out of alignment as the document grows.
  final double lineHeight;

  /// The font size, in logical pixels, used to render line numbers.
  final double fontSize;

  /// The errors to mark in the gutter, keyed by their 1-based
  /// [LayrzCodeError.line].
  final List<LayrzCodeError> errors;

  /// The resolved code theme supplying every color this gutter paints with.
  final LayrzCodeThemeExtension codeTheme;

  /// Creates a new [LayrzCodeGutter].
  const LayrzCodeGutter({
    super.key,
    required this.lineCount,
    required this.currentLine,
    required this.lineHeight,
    required this.fontSize,
    required this.errors,
    required this.codeTheme,
  });

  /// Builds a lookup from 1-based line number to the first [LayrzCodeError]
  /// reported against it.
  ///
  /// Extracted as a pure, stateless computation so it can be unit-tested
  /// directly without mounting the widget. When more than one error targets
  /// the same line, the first one encountered in [errors] wins.
  static Map<int, LayrzCodeError> errorsByLine(List<LayrzCodeError> errors) {
    final map = <int, LayrzCodeError>{};
    for (final error in errors) {
      map.putIfAbsent(error.line, () => error);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final errorByLine = errorsByLine(errors);
    const font = LayrzJetBrainsMonoFont();
    final numberStyle = font.body.copyWith(
      fontSize: fontSize,
      height: kCodeLineHeightFactor,
      color: codeTheme.gutterForeground,
    );
    final errorColor = codeTheme.errorColor;

    // The number column: one RichText per line, right-aligned, each carrying
    // the code's strut so its line box matches the code line box exactly.
    // Line numbers for error lines render in the opaque error color.
    final numberSpans = <TextSpan>[];
    for (var line = 1; line <= lineCount; line++) {
      final isError = errorByLine.containsKey(line);
      numberSpans.add(
        TextSpan(
          text: line == lineCount ? '$line' : '$line\n',
          style: isError ? numberStyle.copyWith(color: errorColor) : numberStyle,
        ),
      );
    }

    final strutStyle = StrutStyle(
      fontFamily: numberStyle.fontFamily,
      fontSize: fontSize,
      height: kCodeLineHeightFactor,
      forceStrutHeight: true,
    );

    final numbers = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: RichText(
        strutStyle: strutStyle,
        textAlign: TextAlign.right,
        text: TextSpan(children: numberSpans),
      ),
    );

    return ColoredBox(
      color: codeTheme.gutterBackground,
      // `IntrinsicWidth` pins this column to its content's natural width (the
      // widest line number) rather than stretching to fill an unbounded slot
      // (which can happen when the gutter sits beside an `Expanded` sibling
      // under a `SingleChildScrollView` given unbounded width by an ancestor).
      child: IntrinsicWidth(
        child: Stack(
          children: [
            // Background bands, one per highlighted line, behind the numbers.
            // Error bands win over the current-line band on the same line.
            for (var line = 1; line <= lineCount; line++)
              if (errorByLine.containsKey(line))
                Positioned(
                  top: (line - 1) * lineHeight,
                  left: 0,
                  right: 0,
                  height: lineHeight,
                  child: ColoredBox(color: errorColor.withValues(alpha: 0.12)),
                )
              else if (line == currentLine)
                Positioned(
                  top: (line - 1) * lineHeight,
                  left: 0,
                  right: 0,
                  height: lineHeight,
                  child: ColoredBox(color: codeTheme.currentLineBackground),
                ),
            numbers,
            // Transparent per-line tooltip regions over error lines, so
            // hovering the error's row surfaces its message.
            for (final entry in errorByLine.entries)
              Positioned(
                top: (entry.key - 1) * lineHeight,
                left: 0,
                right: 0,
                height: lineHeight,
                child: LayrzTooltip(
                  contentText: 'Line ${entry.key}, column ${entry.value.column}: ${entry.value.message}',
                  child: const SizedBox.expand(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
