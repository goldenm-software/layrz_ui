import 'package:flutter/widgets.dart';

/// Indeterminate progress indicator for [LayrzButton].
///
/// This widget is internal to the buttons package and not exported publicly.
///
/// Renders as a horizontal rounded capsule that sweeps across the button's width
/// repeatedly. Used for both loading and cooldown states, differing only in color.
/// No countdown text or duration display.
class LayrzButtonIndicator extends StatefulWidget {
  /// The color of the track (background of the progress bar).
  final Color trackColor;

  /// The color of the animated indicator sweep.
  final Color indicatorColor;

  /// The border radius for rounded corners of the capsule.
  final double borderRadius;

  /// The height of the indicator bar in logical pixels.
  final double height;

  /// Creates a new [LayrzButtonIndicator].
  const LayrzButtonIndicator({
    super.key,
    required this.trackColor,
    required this.indicatorColor,
    required this.borderRadius,
    required this.height,
  });

  @override
  State<LayrzButtonIndicator> createState() => LayrzButtonIndicatorState();
}

/// State for [LayrzButtonIndicator].
///
/// Manages the animation controller that drives the indeterminate sweep animation.
class LayrzButtonIndicatorState extends State<LayrzButtonIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _IndicatorPainter(
            progress: _controller.value,
            trackColor: widget.trackColor,
            indicatorColor: widget.indicatorColor,
            borderRadius: widget.borderRadius,
          ),
          size: Size(double.infinity, widget.height),
        );
      },
    );
  }
}

/// Paints the indeterminate progress indicator sweep across the button width.
class _IndicatorPainter extends CustomPainter {
  /// The current animation progress (0.0–1.0).
  final double progress;

  /// The color of the track background.
  final Color trackColor;

  /// The color of the animated sweep.
  final Color indicatorColor;

  /// The border radius of the capsule.
  final double borderRadius;

  const _IndicatorPainter({
    required this.progress,
    required this.trackColor,
    required this.indicatorColor,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw track background.
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

    // Compute sweep bounds.
    // Sweep width is ~30% of the available width.
    const sweepWidthFraction = 0.3;
    final sweepWidth = size.width * sweepWidthFraction;

    // Start position oscillates from 0 to (width - sweepWidth).
    final maxTravel = size.width - sweepWidth;
    final startX = progress < 0.5
        ? maxTravel *
              (progress * 2) // 0.0 to maxTravel (first half)
        : maxTravel * ((1 - progress) * 2); // maxTravel to 0.0 (second half)

    // Draw indicator sweep.
    final indicatorPaint = Paint()
      ..color = indicatorColor
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(startX, 0, sweepWidth, size.height),
        Radius.circular(borderRadius),
      ),
      indicatorPaint,
    );
  }

  @override
  bool shouldRepaint(_IndicatorPainter oldDelegate) {
    return progress != oldDelegate.progress ||
        trackColor != oldDelegate.trackColor ||
        indicatorColor != oldDelegate.indicatorColor ||
        borderRadius != oldDelegate.borderRadius;
  }
}
