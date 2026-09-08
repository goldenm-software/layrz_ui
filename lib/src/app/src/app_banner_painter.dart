import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Paints [labelText] repeated in a diagonal tiled pattern across the whole
/// canvas at low opacity, forming a debug-only watermark for [LayrzApp].
///
/// The text is rotated by [rotationRadians] (roughly -45°/-π/4 by default)
/// and tiled across rows and columns with fixed spacing, so the mark repeats
/// densely enough to survive an arbitrary crop of the screen while staying
/// faint enough ([alpha]) to never obscure the content painted underneath
/// it. This painter is purely decorative: it never receives input, and
/// callers are expected to wrap it in an `IgnorePointer` (see
/// `LayrzApp._wrapWithTheme`).
///
/// Self-contained and Material-free — glyphs are drawn with a plain
/// [TextPainter] rather than any Material text widget.
@immutable
class LayrzAppBannerPainter extends CustomPainter {
  /// The text repeated across the tiled watermark, e.g. `'STAGING'`.
  final String labelText;

  /// The base color the watermark text is painted in, before [alpha] is
  /// applied. Resolved by the caller — typically from design tokens, with a
  /// caller-supplied override taking precedence — never hardcoded by this
  /// painter.
  final Color color;

  /// The font size, in logical pixels, each repeated [labelText] glyph run is
  /// painted at.
  final double fontSize;

  /// The opacity applied to [color] when painting the watermark text.
  ///
  /// Kept low (the default sits in the ~0.08–0.12 range recommended for a
  /// watermark) so the mark never competes with, or obscures, the actual app
  /// content it is painted over.
  final double alpha;

  /// The clockwise rotation, in radians, applied to each repeated text run.
  ///
  /// Defaults to `-π/4` (-45°), the conventional diagonal watermark angle.
  final double rotationRadians;

  /// The horizontal distance, in logical pixels, between the start of one
  /// tiled text run and the next, along the same row.
  final double horizontalSpacing;

  /// The vertical distance, in logical pixels, between one tiled row of text
  /// and the next.
  final double verticalSpacing;

  /// Creates a [LayrzAppBannerPainter] that tiles [labelText] diagonally
  /// across the canvas in [color] at [alpha] opacity.
  const LayrzAppBannerPainter({
    required this.labelText,
    required this.color,
    this.fontSize = 20.0,
    this.alpha = 0.1,
    this.rotationRadians = -math.pi / 4,
    this.horizontalSpacing = 220.0,
    this.verticalSpacing = 140.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (labelText.isEmpty) return;

    final textPainter = TextPainter(
      text: TextSpan(
        text: labelText,
        style: TextStyle(
          color: color.withValues(alpha: alpha),
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          letterSpacing: 2.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    // Over-cover the canvas so rotated tiles still fill every corner after
    // clipping back down to `size` — a diagonal tiling needs a larger source
    // area than the canvas itself or its corners would show gaps.
    final diagonal = size.longestSide * 1.5;

    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(rotationRadians);
    canvas.translate(-diagonal / 2, -diagonal / 2);

    for (double y = -verticalSpacing; y < diagonal + verticalSpacing; y += verticalSpacing) {
      for (double x = -horizontalSpacing; x < diagonal + horizontalSpacing; x += horizontalSpacing) {
        textPainter.paint(canvas, Offset(x, y));
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant LayrzAppBannerPainter oldDelegate) {
    return labelText != oldDelegate.labelText ||
        color != oldDelegate.color ||
        fontSize != oldDelegate.fontSize ||
        alpha != oldDelegate.alpha ||
        rotationRadians != oldDelegate.rotationRadians ||
        horizontalSpacing != oldDelegate.horizontalSpacing ||
        verticalSpacing != oldDelegate.verticalSpacing;
  }
}
