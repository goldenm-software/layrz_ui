import 'package:flutter/widgets.dart';

/// Paints the track, active fill, and thumb glyph of a [LayrzSlider]-family control.
///
/// This painter is intentionally dumb: it receives fully-resolved geometry and
/// colours from the widget's `build` method and draws them. It holds no
/// interaction-state logic of its own — that lives in the widget's `State`,
/// which resolves the correct colours per the slider's interaction-state
/// precedence (disabled > error > pressed > hover/focused > default) before
/// constructing this painter. Keeping the painter free of state logic makes it
/// testable in isolation with a plain [Canvas], the same pattern used by
/// `LayrzSelectionHandlePainter`.
///
/// **Geometry note (D15 compliance)**: [thumbRadius] must be constant across
/// every call this painter receives for a given slider instance, regardless of
/// interaction state. Interaction feedback is expressed by [thumbColor] and
/// [thumbBorderColor] alone — this painter has no branch that would grow the
/// thumb, and passing a different radius per state is a caller error the
/// painter does not protect against by design (it simply paints what it is told).
class LayrzSliderPainter extends CustomPainter {
  /// The fraction of the track, from 0.0 to 1.0, that is "filled" (before the thumb).
  ///
  /// Computed by the widget from the current value against `min`/`max`, already
  /// quantised if `divisions` is set. 0.0 renders the thumb at the track's start
  /// (left in LTR), 1.0 at its end.
  final double fraction;

  /// The thickness, in logical pixels, of the painted track line.
  ///
  /// This value must stay constant across all interaction states per D15 —
  /// only [trackColor] and [activeTrackColor] may vary with state, never this
  /// thickness.
  final double trackThickness;

  /// The radius, in logical pixels, of the painted circular thumb.
  ///
  /// Must stay constant across all interaction states per D15 — see the class
  /// doc's geometry note.
  final double thumbRadius;

  /// The width, in logical pixels, of the thumb's painted border ring.
  ///
  /// Kept constant across states; only [thumbBorderColor] varies.
  final double thumbBorderWidth;

  /// The colour of the unfilled portion of the track (from the thumb to the end).
  final Color trackColor;

  /// The colour of the filled portion of the track (from the start to the thumb).
  final Color activeTrackColor;

  /// The fill colour of the thumb glyph.
  final Color thumbColor;

  /// The colour of the thumb's border ring.
  final Color thumbBorderColor;

  /// Creates a painter for a single-value slider track and thumb.
  const LayrzSliderPainter({
    required this.fraction,
    required this.trackThickness,
    required this.thumbRadius,
    required this.thumbBorderWidth,
    required this.trackColor,
    required this.activeTrackColor,
    required this.thumbColor,
    required this.thumbBorderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final trackY = size.height / 2;
    final usableWidth = size.width - thumbRadius * 2;
    final thumbX = thumbRadius + usableWidth * fraction;

    final trackPaint = Paint()
      ..color = trackColor
      ..strokeWidth = trackThickness
      ..strokeCap = StrokeCap.round;

    final activeTrackPaint = Paint()
      ..color = activeTrackColor
      ..strokeWidth = trackThickness
      ..strokeCap = StrokeCap.round;

    // Unfilled segment: from the thumb to the track's end.
    canvas.drawLine(
      Offset(thumbX, trackY),
      Offset(size.width - thumbRadius, trackY),
      trackPaint,
    );

    // Filled segment: from the track's start to the thumb.
    canvas.drawLine(
      Offset(thumbRadius, trackY),
      Offset(thumbX, trackY),
      activeTrackPaint,
    );

    final thumbCenter = Offset(thumbX, trackY);

    canvas.drawCircle(
      thumbCenter,
      thumbRadius,
      Paint()..color = thumbColor,
    );

    if (thumbBorderWidth > 0) {
      canvas.drawCircle(
        thumbCenter,
        thumbRadius - thumbBorderWidth / 2,
        Paint()
          ..color = thumbBorderColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = thumbBorderWidth,
      );
    }
  }

  @override
  bool shouldRepaint(covariant LayrzSliderPainter oldDelegate) {
    return fraction != oldDelegate.fraction ||
        trackThickness != oldDelegate.trackThickness ||
        thumbRadius != oldDelegate.thumbRadius ||
        thumbBorderWidth != oldDelegate.thumbBorderWidth ||
        trackColor != oldDelegate.trackColor ||
        activeTrackColor != oldDelegate.activeTrackColor ||
        thumbColor != oldDelegate.thumbColor ||
        thumbBorderColor != oldDelegate.thumbBorderColor;
  }
}
