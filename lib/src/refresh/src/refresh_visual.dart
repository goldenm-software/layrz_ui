import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';

import 'refresh_state.dart';

/// The visual loading affordance painted by [LayrzRefreshIndicator].
///
/// Built independently of `LayrzProgressBar` (DESIGN-88): the two components
/// ship different shapes on purpose (a ring here, a bar there), so
/// [LayrzRefreshVisual] owns its own [CustomPainter] rather than importing
/// one. A [state] of [LayrzRefreshState.idle] or [LayrzRefreshState.armed]
/// paints a ring that fills in proportion to [dragProgress]; [refreshing]
/// paints a continuously rotating indeterminate arc; [settling] paints the
/// same rotating arc while the surrounding [LayrzRefreshIndicator] animates
/// the whole visual back to its retracted position.
class LayrzRefreshVisual extends StatefulWidget {
  /// Creates a [LayrzRefreshVisual].
  const LayrzRefreshVisual({
    required this.state,
    required this.dragProgress,
    this.size = 32.0,
    super.key,
  });

  /// The current refresh lifecycle state, driving which painting mode is
  /// used: a progress ring pre-trigger, or a spinning arc once refreshing.
  final LayrzRefreshState state;

  /// How far an in-progress drag has advanced toward the trigger threshold,
  /// in `[0.0, 1.0]`. Only used to size the ring while [state] is
  /// [LayrzRefreshState.idle] or [LayrzRefreshState.armed]; ignored once a
  /// refresh has committed.
  final double dragProgress;

  /// The diameter of the visual, in logical pixels.
  final double size;

  @override
  State<LayrzRefreshVisual> createState() => _LayrzRefreshVisualState();
}

class _LayrzRefreshVisualState extends State<LayrzRefreshVisual> with SingleTickerProviderStateMixin {
  /// How long one full sweep of the indeterminate arc takes.
  ///
  /// Kept local to this widget rather than promoted to a shared constant:
  /// no other component in this batch spins an arc, so there is nothing yet
  /// to share it with.
  static const Duration _sweepDuration = Duration(milliseconds: 1000);

  late final AnimationController _spinController;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(duration: _sweepDuration, vsync: this);
    // Reduce-motion is read from MediaQuery, which is not available yet in
    // initState (dependOnInheritedWidgetOfExactType requires a build context
    // already in the tree). build() calls _syncSpinning() unconditionally on
    // every build, including the first, so nothing is missed by deferring it.
  }

  /// Starts or stops [_spinController]'s repeating ticker to match [widget.state]
  /// and the current reduce-motion setting.
  ///
  /// Called from [build] on every build (rather than from [initState] or
  /// [didUpdateWidget]) because it reads [MediaQuery] via
  /// [BuildContext.dependOnInheritedWidgetOfExactType], which is only valid
  /// once this element is already in the tree — [initState] runs too early
  /// for that. Calling it unconditionally from [build] means it always runs
  /// at least once per frame this widget rebuilds, so no transition is missed.
  void _syncSpinning() {
    final shouldSpin = widget.state == LayrzRefreshState.refreshing || widget.state == LayrzRefreshState.settling;
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    if (shouldSpin && !reduceMotion) {
      if (!_spinController.isAnimating) _spinController.repeat();
    } else {
      _spinController.stop();
    }
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final trackColor = tokens.colors.sf3;
    final indicatorColor = tokens.colors.primary.shade500;
    final isSpinning = widget.state == LayrzRefreshState.refreshing || widget.state == LayrzRefreshState.settling;

    // Re-evaluate reduce-motion on every build: MediaQuery may change without
    // widget.state changing (e.g. the OS setting flips mid-refresh).
    _syncSpinning();

    return Semantics(
      // `container: true` gives this widget its own semantics boundary node
      // regardless of what else shares the page. [LayrzRefreshIndicator] can
      // float a second [LayrzRefreshVisual] for its fallback button
      // alongside this one (see refresh_indicator.dart); without a boundary
      // here, both would merge their `liveRegion`/`label` into whatever
      // ancestor node happens to be nearest, and the combined result is not
      // guaranteed to preserve either one's label or live-region flag.
      container: true,
      liveRegion: isSpinning,
      label: isSpinning ? 'Refreshing' : null,
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: isSpinning
            ? AnimatedBuilder(
                animation: _spinController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _RefreshRingPainter(
                      trackColor: trackColor,
                      indicatorColor: indicatorColor,
                      sweepFraction: 0.75,
                      rotation: _spinController.value * 2 * math.pi,
                    ),
                  );
                },
              )
            : CustomPaint(
                painter: _RefreshRingPainter(
                  trackColor: trackColor,
                  indicatorColor: indicatorColor,
                  sweepFraction: widget.dragProgress.clamp(0.0, 1.0),
                  rotation: -math.pi / 2,
                ),
              ),
      ),
    );
  }
}

/// Paints [LayrzRefreshVisual]'s ring: a track circle plus an arc sweeping
/// [sweepFraction] of the full circle, starting at [rotation] radians.
class _RefreshRingPainter extends CustomPainter {
  /// Creates a [_RefreshRingPainter].
  const _RefreshRingPainter({
    required this.trackColor,
    required this.indicatorColor,
    required this.sweepFraction,
    required this.rotation,
  });

  /// The color of the full background ring.
  final Color trackColor;

  /// The color of the progress/spinner arc.
  final Color indicatorColor;

  /// The fraction (0.0–1.0) of the circle the arc sweeps.
  final double sweepFraction;

  /// The starting angle of the arc, in radians.
  final double rotation;

  static const double _strokeWidth = 3.0;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (math.min(size.width, size.height) - _strokeWidth) / 2;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth;
    canvas.drawCircle(center, radius, trackPaint);

    if (sweepFraction <= 0.0) return;

    final arcPaint = Paint()
      ..color = indicatorColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      rotation,
      sweepFraction * 2 * math.pi,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RefreshRingPainter oldDelegate) =>
      trackColor != oldDelegate.trackColor ||
      indicatorColor != oldDelegate.indicatorColor ||
      sweepFraction != oldDelegate.sweepFraction ||
      rotation != oldDelegate.rotation;
}
