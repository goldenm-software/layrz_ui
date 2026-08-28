import 'package:flutter/widgets.dart';

/// Paints the rounded-capsule track and indicator for [LayrzProgressBar].
///
/// Supports two modes, distinguished by [determinateValue]:
/// - **Determinate** (non-null): paints a filled bar growing from the leading
///   edge, where `1.0` is a full bar. This is intentionally the inverse of
///   `LayrzButtonIndicator`'s internal `_IndicatorPainter`, whose determinate
///   mode depletes from full to empty — correct for a countdown, wrong for a
///   general-purpose progress bar (see the DESIGN-88 plan's R-3).
/// - **Indeterminate** (null): paints a capsule sweeping back and forth across
///   the track, driven by [sweepPosition] in `[0.0, 1.0]`.
class LayrzProgressPainter extends CustomPainter {
  /// The determinate fill fraction in `[0.0, 1.0]`, where `1.0` fills the
  /// entire track. Null selects indeterminate painting instead, in which case
  /// [sweepPosition] is used.
  final double? determinateValue;

  /// The current position of the indeterminate sweep in `[0.0, 1.0]`.
  ///
  /// Ignored when [determinateValue] is non-null. Interpreted as an
  /// oscillation: `0.0` and `1.0` both correspond to the sweep's start edge,
  /// with `0.5` at its furthest travel, so a repeating linear animation
  /// produces a back-and-forth sweep without a visible jump cut.
  final double sweepPosition;

  /// The fraction of the track width covered by the indeterminate sweep.
  final double sweepWidthFraction;

  /// The color painted for the track (the unfilled background of the bar).
  final Color trackColor;

  /// The color painted for the indicator (the determinate fill or the
  /// indeterminate sweep).
  final Color indicatorColor;

  /// The border radius applied to both the track and the indicator, in
  /// logical pixels.
  final double borderRadius;

  /// Creates a new [LayrzProgressPainter].
  const LayrzProgressPainter({
    required this.determinateValue,
    required this.sweepPosition,
    required this.sweepWidthFraction,
    required this.trackColor,
    required this.indicatorColor,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
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

  @override
  bool shouldRepaint(LayrzProgressPainter oldDelegate) {
    return determinateValue != oldDelegate.determinateValue ||
        sweepPosition != oldDelegate.sweepPosition ||
        sweepWidthFraction != oldDelegate.sweepWidthFraction ||
        trackColor != oldDelegate.trackColor ||
        indicatorColor != oldDelegate.indicatorColor ||
        borderRadius != oldDelegate.borderRadius;
  }
}
