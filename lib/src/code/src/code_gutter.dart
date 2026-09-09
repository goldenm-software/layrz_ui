import 'package:flutter/widgets.dart';

import 'package:layrz_ui/src/code/src/code_error.dart';
import 'package:layrz_ui/src/code/src/code_theme_extension.dart';
import 'package:layrz_ui/src/fonts/fonts.dart';
import 'package:layrz_ui/src/tooltips/tooltips.dart';

/// The line-number gutter drawn to the left of [LayrzCodeEditor]'s editable
/// text.
///
/// Renders one row per line of the edited document, right-aligned, colored
/// with [LayrzCodeThemeExtension.gutterForeground] on
/// [LayrzCodeThemeExtension.gutterBackground]. The row for [currentLine] (when
/// non-null) is painted with [LayrzCodeThemeExtension.currentLineBackground]
/// to mirror the current-line highlight drawn behind the code itself. Any
/// line reported in [errors] is painted with
/// [LayrzCodeThemeExtension.errorColor] and wrapped in a [LayrzTooltip]
/// carrying that error's message.
///
/// **Scroll-sync contract**: this widget renders its rows in a plain
/// [Column] with **no scrolling of its own** — [LayrzCodeEditor] places it
/// and the editable text side by side inside one shared
/// [SingleChildScrollView], so both columns move together under a single
/// [ScrollController] and line `N` always lines up between the two. Giving
/// the gutter its own scrollable would desynchronize it from the text the
/// moment the two views scroll by different amounts (e.g. differing
/// scrollbar insets), so this widget must never be wrapped in a second
/// scroll view by its caller.
///
/// Each row's height matches [lineHeight] exactly, which the caller computes
/// from the same [TextStyle] used to render the code, so row `N` in this
/// gutter sits flush against line `N` of the code above it.
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
  /// gutter, or line numbers will drift out of alignment as the document
  /// grows.
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
    final numberStyle = font.body.copyWith(fontSize: fontSize, color: codeTheme.gutterForeground);
    final errorNumberStyle = numberStyle.copyWith(color: codeTheme.errorColor);

    return ColoredBox(
      color: codeTheme.gutterBackground,
      // `IntrinsicWidth` pins this column to its content's natural width
      // (the widest line number) rather than stretching to fill whatever
      // width its parent `Row` slot offers — which can be unbounded when
      // this gutter sits beside an `Expanded` sibling under a
      // `SingleChildScrollView` that itself received unbounded width from
      // an ancestor (e.g. a bare `Center` in a test harness).
      child: IntrinsicWidth(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var line = 1; line <= lineCount; line++)
              _buildRow(
                line: line,
                isCurrent: line == currentLine,
                error: errorByLine[line],
                numberStyle: numberStyle,
                errorNumberStyle: errorNumberStyle,
              ),
          ],
        ),
      ),
    );
  }

  /// Builds a single gutter row for [line].
  Widget _buildRow({
    required int line,
    required bool isCurrent,
    required LayrzCodeError? error,
    required TextStyle numberStyle,
    required TextStyle errorNumberStyle,
  }) {
    final row = Container(
      height: lineHeight,
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      color: isCurrent ? codeTheme.currentLineBackground : null,
      child: Text(
        '$line',
        style: error != null ? errorNumberStyle : numberStyle,
      ),
    );

    if (error == null) {
      return row;
    }

    return LayrzTooltip(
      contentText: 'Line $line, column ${error.column}: ${error.message}',
      child: row,
    );
  }
}
