import 'package:flutter/widgets.dart';

/// Paints the centered value label for [LayrzProgressBar]'s linear,
/// determinate mode, split across the filled/unfilled boundary so it stays
/// legible regardless of where that boundary falls.
///
/// A label centered inside a partially-filled bar almost always straddles
/// the seam between the indicator color and the track color — there is no
/// single text color that reads clearly against both halves at once. This
/// painter solves that the way native OS progress bars do: the same text is
/// painted twice, each copy clipped to one side of the fill boundary and
/// colored for contrast against *that* side only —
/// [indicatorContrastColor] within the filled region, [trackContrastColor]
/// within the unfilled region. The two clipped halves compose into one
/// visually continuous label with no unreadable segment.
///
/// This painter deliberately knows nothing about progress semantics
/// (determinate/indeterminate, format) — [LayrzProgressBar] only constructs
/// it for the linear, determinate case, and is responsible for withholding
/// it entirely for indeterminate mode, where a percentage would be
/// meaningless.
class LayrzProgressLabelPainter extends CustomPainter {
  /// The formatted label text to paint (e.g. `'42%'` or `'3.14%'`).
  final String text;

  /// The text style applied to both copies of the label; only [TextStyle.color]
  /// is overridden per copy, per side of the fill boundary.
  final TextStyle style;

  /// The determinate fill fraction, in `[0.0, 1.0]`, marking where the
  /// indicator fill ends and the track begins. The x-offset in logical
  /// pixels is derived from this fraction and the painter's actual resolved
  /// [Size] at paint time, rather than being precomputed by the caller —
  /// the enclosing bar's width is frequently unresolved
  /// (`double.infinity`, an unconstrained-width hint) until layout, so only
  /// the [paint] callback's `size` argument is ever a real, finite width.
  final double fillFraction;

  /// The text color used for the portion of the label that overlaps the
  /// filled (indicator) region.
  final Color indicatorContrastColor;

  /// The text color used for the portion of the label that overlaps the
  /// unfilled (track) region.
  final Color trackContrastColor;

  /// Creates a new [LayrzProgressLabelPainter].
  LayrzProgressLabelPainter({
    required this.text,
    required this.style,
    required this.fillBoundary,
    required this.indicatorContrastColor,
    required this.trackContrastColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final boundary = fillBoundary.clamp(0.0, size.width);

    _paintClipped(
      canvas: canvas,
      size: size,
      color: trackContrastColor,
      clip: Rect.fromLTWH(boundary, 0, size.width - boundary, size.height),
    );
    _paintClipped(
      canvas: canvas,
      size: size,
      color: indicatorContrastColor,
      clip: Rect.fromLTWH(0, 0, boundary, size.height),
    );
  }

  /// Paints [text] centered in [size], colored with [color], visible only
  /// within [clip].
  ///
  /// The full label is laid out and centered against the *entire* bar for
  /// both calls (not re-centered within [clip]), so the two clipped copies
  /// line up into a single glyph run with no seam or double-strike — only
  /// the fill color changes between them, never the glyph position.
  void _paintClipped({required Canvas canvas, required Size size, required Color color, required Rect clip}) {
    if (clip.width <= 0 || clip.height <= 0) return;

    final painter = TextPainter(
      text: TextSpan(text: text, style: style.copyWith(color: color)),
      textDirection: TextDirection.ltr,
    )..layout();

    final offset = Offset(
      (size.width - painter.width) / 2,
      (size.height - painter.height) / 2,
    );

    canvas.save();
    canvas.clipRect(clip);
    painter.paint(canvas, offset);
    canvas.restore();
  }

  @override
  bool shouldRepaint(LayrzProgressLabelPainter oldDelegate) {
    return text != oldDelegate.text ||
        style != oldDelegate.style ||
        fillBoundary != oldDelegate.fillBoundary ||
        indicatorContrastColor != oldDelegate.indicatorContrastColor ||
        trackContrastColor != oldDelegate.trackContrastColor;
  }
}
