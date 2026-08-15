import 'package:flutter/widgets.dart';

/// Progress indicator for [LayrzButton] with determinate and indeterminate modes.
///
/// This widget is internal to the buttons package and not exported publicly.
///
/// **Indeterminate mode** (progress: null):
/// Renders as a horizontal rounded capsule that sweeps across the button's width
/// repeatedly. Used for loading and post-countdown states.
///
/// **Determinate mode** (progress: 0.0–1.0):
/// Renders a filled bar that depletes from full to empty over the duration,
/// with remaining whole seconds displayed as text overlay.
class LayrzButtonIndicator extends StatefulWidget {
  /// The color of the track (background of the progress bar).
  final Color trackColor;

  /// The color of the animated indicator sweep or determinate fill.
  final Color indicatorColor;

  /// The border radius for rounded corners of the capsule.
  final double borderRadius;

  /// The height of the indicator bar in logical pixels.
  final double height;

  /// The progress value (0.0–1.0) for determinate mode.
  ///
  /// When null, renders indeterminate sweep animation.
  /// When a value between 0.0 and 1.0, renders a depleting bar with remaining seconds text.
  final double? progress;

  /// The remaining seconds to display during determinate mode.
  ///
  /// Ignored when [progress] is null (indeterminate mode).
  /// Displayed as centered text overlay on the progress bar.
  final int? remainingSeconds;

  /// Creates a new [LayrzButtonIndicator].
  const LayrzButtonIndicator({
    super.key,
    required this.trackColor,
    required this.indicatorColor,
    required this.borderRadius,
    required this.height,
    this.progress,
    this.remainingSeconds,
  });

  @override
  State<LayrzButtonIndicator> createState() => LayrzButtonIndicatorState();
}

/// State for [LayrzButtonIndicator].
///
/// Manages the animation controller that drives the indeterminate sweep animation.
/// For determinate mode, the progress value is passed directly via the widget.
class LayrzButtonIndicatorState extends State<LayrzButtonIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _indeterminateController;

  @override
  void initState() {
    super.initState();
    _indeterminateController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _indeterminateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final determinateProgress = widget.progress;

    // Determinate mode: show progress bar with remaining seconds.
    if (determinateProgress != null) {
      return Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            painter: _IndicatorPainter(
              progress: determinateProgress,
              trackColor: widget.trackColor,
              indicatorColor: widget.indicatorColor,
              borderRadius: widget.borderRadius,
              isDeterminate: true,
            ),
            size: Size(double.infinity, widget.height),
          ),
          // Remaining seconds text overlay.
          if (widget.remainingSeconds != null)
            Text(
              '${widget.remainingSeconds}',
              style: TextStyle(
                color: widget.indicatorColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      );
    }

    // Indeterminate mode: animate sweep across full width.
    return AnimatedBuilder(
      animation: _indeterminateController,
      builder: (context, child) {
        return CustomPaint(
          painter: _IndicatorPainter(
            progress: _indeterminateController.value,
            trackColor: widget.trackColor,
            indicatorColor: widget.indicatorColor,
            borderRadius: widget.borderRadius,
            isDeterminate: false,
          ),
          size: Size(double.infinity, widget.height),
        );
      },
    );
  }
}

/// Paints progress indicators for [LayrzButtonIndicator].
///
/// Supports two modes:
/// - **Determinate**: filled bar depleting from full to empty with remaining seconds text
/// - **Indeterminate**: animated sweep oscillating across the button width
class _IndicatorPainter extends CustomPainter {
  /// The current animation progress (0.0–1.0).
  final double progress;

  /// The color of the track background.
  final Color trackColor;

  /// The color of the animated sweep or determinate fill.
  final Color indicatorColor;

  /// The border radius of the capsule.
  final double borderRadius;

  /// True for determinate mode (progress bar + remaining seconds).
  /// False for indeterminate mode (animated sweep).
  final bool isDeterminate;

  const _IndicatorPainter({
    required this.progress,
    required this.trackColor,
    required this.indicatorColor,
    required this.borderRadius,
    required this.isDeterminate,
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

    final indicatorPaint = Paint()
      ..color = indicatorColor
      ..style = PaintingStyle.fill;

    if (isDeterminate) {
      // Determinate mode: filled bar from left, depleting as progress increases.
      // progress: 0.0 = full bar, progress: 1.0 = empty bar
      final filledWidth = size.width * (1.0 - progress);

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, filledWidth, size.height),
          Radius.circular(borderRadius),
        ),
        indicatorPaint,
      );
    } else {
      // Indeterminate mode: sweep oscillates across width.
      const sweepWidthFraction = 0.3;
      final sweepWidth = size.width * sweepWidthFraction;

      // Start position oscillates from 0 to (width - sweepWidth).
      final maxTravel = size.width - sweepWidth;
      final startX = progress < 0.5
          ? maxTravel *
                (progress * 2) // 0.0 to maxTravel (first half)
          : maxTravel * ((1 - progress) * 2); // maxTravel to 0.0 (second half)

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
  bool shouldRepaint(_IndicatorPainter oldDelegate) {
    return progress != oldDelegate.progress ||
        trackColor != oldDelegate.trackColor ||
        indicatorColor != oldDelegate.indicatorColor ||
        borderRadius != oldDelegate.borderRadius ||
        isDeterminate != oldDelegate.isDeterminate;
  }
}
