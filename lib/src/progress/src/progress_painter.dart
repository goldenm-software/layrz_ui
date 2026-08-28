import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'progress_format.dart';

/// Paints the track and indicator for [LayrzProgressBar], in either its
/// [LayrzProgressFormat.linear] (rounded-capsule) or [LayrzProgressFormat.circular]
/// (ring) shape.
///
/// Supports two behaviours in both shapes, distinguished by [determinateValue]:
/// - **Determinate** (non-null): in [LayrzProgressFormat.linear], paints a
///   filled bar growing from the leading edge, where `1.0` is a full bar; in
///   [LayrzProgressFormat.circular], paints an arc sweeping clockwise from 12
///   o'clock, where `1.0` is a complete ring. Both are intentionally the
///   inverse of `LayrzButtonIndicator`'s internal `_IndicatorPainter`, whose
///   determinate mode depletes from full to empty — correct for a countdown,
///   wrong for a general-purpose progress indicator (see the DESIGN-88 plan's
///   R-3).
/// - **Indeterminate** (null): in [LayrzProgressFormat.linear], paints a
///   capsule sweeping back and forth across the track, driven by
///   [sweepPosition] in `[0.0, 1.0]`; in [LayrzProgressFormat.circular], paints
///   a rotating arc, also driven by [sweepPosition], advancing monotonically
///   rather than oscillating (a ring has no "edge" to bounce off of).
class LayrzProgressPainter extends CustomPainter {
  /// The shape to paint: a horizontal bar or a ring.
  final LayrzProgressFormat shape;

  /// The determinate fill fraction in `[0.0, 1.0]`, where `1.0` fills the
  /// entire track (linear) or completes the ring (circular). Null selects
  /// indeterminate painting instead, in which case [sweepPosition] is used.
  final double? determinateValue;

  /// The current position of the indeterminate sweep in `[0.0, 1.0]`.
  ///
  /// Ignored when [determinateValue] is non-null. In [LayrzProgressFormat.linear],
  /// interpreted as an oscillation: `0.0` and `1.0` both correspond to the
  /// sweep's start edge, with `0.5` at its furthest travel, so a repeating
  /// linear animation produces a back-and-forth sweep without a visible jump
  /// cut. In [LayrzProgressFormat.circular], interpreted as a monotonic
  /// rotation fraction of a full turn.
  final double sweepPosition;

  /// The fraction of the track width (linear) or of a full turn (circular)
  /// covered by the indeterminate sweep arc.
  final double sweepWidthFraction;

  /// The color painted for the track (the unfilled background of the
  /// indicator).
  final Color trackColor;

  /// The color painted for the indicator (the determinate fill or the
  /// indeterminate sweep).
  final Color indicatorColor;

  /// The border radius applied to both the track and the indicator, in
  /// logical pixels. Only meaningful in [LayrzProgressFormat.linear] mode.
  final double borderRadius;

  /// The stroke thickness of the ring, in logical pixels. Only meaningful in
  /// [LayrzProgressFormat.circular] mode.
  final double strokeWidth;

  /// Creates a new [LayrzProgressPainter].
  const LayrzProgressPainter({
    this.shape = LayrzProgressFormat.linear,
    required this.determinateValue,
    required this.sweepPosition,
    required this.sweepWidthFraction,
    required this.trackColor,
    required this.indicatorColor,
    required this.borderRadius,
    this.strokeWidth = 4.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (shape == LayrzProgressFormat.circular) {
      _paintCircular(canvas, size);
    } else {
      _paintLinear(canvas, size);
    }
  }

  /// Paints the rounded-capsule linear track and indicator.
  void _paintLinear(Canvas canvas, Size size) {
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(borderRadius),
      ),
      trackPaint,
    );

    final indicatorPaint = Paint()
      ..color = indicatorColor
      ..style = PaintingStyle.fill;

    final value = determinateValue;
    if (value != null) {
      // Determinate mode: filled bar grows from the leading edge as the
      // value increases — value: 1.0 is a full bar.
      final filledWidth = size.width * value.clamp(0.0, 1.0);
      if (filledWidth <= 0) return;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, filledWidth, size.height),
          Radius.circular(borderRadius),
        ),
        indicatorPaint,
      );
    } else {
      // Indeterminate mode: sweep oscillates back and forth across the track.
      final sweepWidth = size.width * sweepWidthFraction;
      final maxTravel = size.width - sweepWidth;
      final oscillation = sweepPosition < 0.5 ? sweepPosition * 2 : (1 - sweepPosition) * 2;
      final startX = maxTravel * oscillation;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(startX, 0, sweepWidth, size.height),
          Radius.circular(borderRadius),
        ),
        indicatorPaint,
      );
    }
  }

  /// Paints the ring track and indicator arc.
  ///
  /// The ring is inscribed in [size], deflated by half the [strokeWidth] so
  /// the stroke never clips against the canvas bounds. The track is a closed
  /// circle drawn with [Canvas.drawCircle] rather than a 360-degree
  /// [Canvas.drawArc] — an arc retains distinct start/end points even at a
  /// full turn, and a round stroke cap at each produces an overlapping
  /// lump where the ring "closes". A circle has no endpoints, so it always
  /// closes cleanly regardless of cap style. Determinate progress sweeps
  /// clockwise starting at 12 o'clock (`-pi/2` in canvas radians, where `0` is
  /// 3 o'clock); indeterminate progress rotates a fixed-length arc
  /// monotonically around the ring, also starting from 12 o'clock.
  ///
  /// Both the track and indicator paints set `isAntiAlias` explicitly (it
  /// already defaults to `true`, but a stroked arc's edge quality is directly
  /// what this painter exists to get right, so leaving it implicit was worth
  /// removing as a variable). The indeterminate case is additionally isolated
  /// in its own compositor layer by the caller (`progress_bar.dart`'s
  /// `_wrapCircular`), since a continuously-repainting arc that shares a
  /// layer with surrounding content forces more to be re-rasterized each
  /// frame than the ring itself.
  void _paintCircular(Canvas canvas, Size size) {
    final diameter = math.min(size.width, size.height);
    final radius = (diameter - strokeWidth) / 2;
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: center, radius: radius);

    const startAngle = -math.pi / 2; // 12 o'clock.
    const fullTurn = 2 * math.pi;

    // The track is a fully closed ring, so it is painted with drawCircle
    // rather than a 360-degree drawArc. An arc has a start point and an end
    // point even when its sweep is a full turn, and StrokeCap.round draws a
    // hemispherical cap at each — with both points landing on the same spot,
    // the two caps overlap into a visible lump/seam artifact. A circle has no
    // endpoints, so cap style is irrelevant and the ring closes cleanly.
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..isAntiAlias = true;

    canvas.drawCircle(center, radius, trackPaint);

    final indicatorPaint = Paint()
      ..color = indicatorColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    final value = determinateValue;
    if (value != null) {
      // Determinate mode: arc sweeps clockwise from 12 o'clock as the value
      // increases — value: 1.0 is a complete ring.
      final sweepAngle = fullTurn * value.clamp(0.0, 1.0);
      if (sweepAngle <= 0) return;

      canvas.drawArc(rect, startAngle, sweepAngle, false, indicatorPaint);
    } else {
      // Indeterminate mode: a fixed-length arc rotates monotonically around
      // the ring as sweepPosition advances from 0.0 to 1.0 (then repeats).
      final sweepAngle = fullTurn * sweepWidthFraction;
      final rotation = fullTurn * sweepPosition;

      canvas.drawArc(rect, startAngle + rotation, sweepAngle, false, indicatorPaint);
    }
  }

  @override
  bool shouldRepaint(LayrzProgressPainter oldDelegate) {
    return shape != oldDelegate.shape ||
        determinateValue != oldDelegate.determinateValue ||
        sweepPosition != oldDelegate.sweepPosition ||
        sweepWidthFraction != oldDelegate.sweepWidthFraction ||
        trackColor != oldDelegate.trackColor ||
        indicatorColor != oldDelegate.indicatorColor ||
        borderRadius != oldDelegate.borderRadius ||
        strokeWidth != oldDelegate.strokeWidth;
  }
}
