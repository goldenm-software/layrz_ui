import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

/// Paints the static hue/saturation disc of the HSV color wheel — hue
/// swept around the ring (0° at the positive x-axis, increasing clockwise
/// in [Canvas]'s coordinate space), saturation mapped to radius (0 at the
/// center, 1 at the outer edge).
///
/// **Kept in its own file per rule #3** (one concern per file), and split
/// from the marker into its own [CustomPainter] class specifically for
/// performance — see this class's own perf note below and
/// [LayrzColorWheel]'s doc for how the split is wired into two stacked
/// `CustomPaint` layers.
///
/// **From scratch, Material-free.** No `ColorPicker`, no
/// `HueRingPicker` — only shader-based [Canvas] painting (a [SweepGradient]
/// for hue composited with a [RadialGradient] for saturation), per the
/// project's Material/Cupertino-free invariant.
///
/// **Performance (perf fix, user-testing finding "the wheel is laggy").**
/// The previous implementation painted the disc as 100 concentric rings ×
/// 360 one-degree [Canvas.drawArc] calls — 36,000 draw calls — on *every*
/// pointer move, because one [CustomPainter] painted both the disc and the
/// marker together and repainted on every hue/saturation change (i.e.
/// every drag frame). This class now:
/// - Paints the disc in three shader-based draw calls total (see
///   [_paintDisc]): a [SweepGradient] sweeps hue around the circumference
///   in one `drawCircle`, a [RadialGradient] composited with
///   [BlendMode.srcATop] fades saturation from the center outward in a
///   second `drawCircle`, and a solid black scrim composited with
///   [BlendMode.srcATop] applies `value` uniformly in a third.
/// - Depends only on [value] (via [shouldRepaint]) — hue and saturation no
///   longer trigger a disc repaint at all, because dragging the marker
///   changes hue/saturation but never the disc's own appearance. Only
///   changing the value/brightness slider (which *does* visibly dim/
///   brighten every pixel of the disc) causes this painter to repaint.
/// [LayrzColorWheel] additionally wraps this painter in its own
/// `RepaintBoundary`, isolating the (now rare) disc repaint from the
/// separate, cheap marker-only [LayrzColorWheelMarkerPainter] layer that
/// repaints on every drag frame instead.
class LayrzColorWheelDiscPainter extends CustomPainter {
  /// The current value/brightness, in `[0, 1]`, applied uniformly to every
  /// pixel of the disc so the wheel visually dims/brightens together with
  /// the separate value slider [LayrzColorWheel] renders alongside it.
  final double value;

  /// The number of discrete hue stops the [SweepGradient] is built from.
  /// Higher values render a smoother hue sweep at the cost of a (still
  /// tiny, one-shader-object) amount of extra gradient-stop bookkeeping.
  /// Defaults to `36` (one stop every 10°), which a gradient's own
  /// hardware-interpolated shading renders as visually continuous — unlike
  /// the old flat-wedge-per-arc approach, a [SweepGradient] interpolates
  /// smoothly *between* stops, so this needs nowhere near the previous
  /// per-degree resolution to look identical.
  final int ringResolution;

  /// Creates a new [LayrzColorWheelDiscPainter].
  LayrzColorWheelDiscPainter({
    required this.value,
    this.ringResolution = 36,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    if (radius <= 0) return;

    _paintDisc(canvas, center, radius);
  }

  /// Paints the full hue/saturation disc in three shader-based draw calls,
  /// replacing the previous per-degree/per-ring `drawArc` loop (see this
  /// class's own doc for the before/after call count).
  ///
  /// 1. A [SweepGradient] built from [ringResolution] fully-saturated,
  ///    full-value hue stops is drawn as one filled circle — this alone
  ///    reproduces the disc's angular hue variation.
  /// 2. A white-to-transparent [RadialGradient] (opaque white at the
  ///    center, fully transparent at the rim) is composited on top with
  ///    [BlendMode.srcATop], which blends *toward white* by exactly the
  ///    overlay's alpha at each pixel — i.e. fully white at the center
  ///    (saturation 0) fading to the pure hue color at the rim (saturation
  ///    1), the same desaturate-toward-center relationship the old
  ///    per-ring `HSVColor(.., ringSaturation, ..)` loop produced.
  /// 3. A solid black scrim at `alpha = 1 - value` is composited with
  ///    [BlendMode.srcATop] the same way, blending every pixel toward
  ///    black by `(1 - value)` — equivalent to HSV's uniform value scaling
  ///    of the previous loop's `HSVColor.fromAHSV(1.0, degree, sat,
  ///    value)`.
  ///
  /// All three draws happen inside one [Canvas.saveLayer]/`restore` pair so
  /// the `srcATop` composites apply only within the disc's own circular
  /// bounds, not the full painter [Size].
  void _paintDisc(Canvas canvas, Offset center, double radius) {
    final rect = Rect.fromCircle(center: center, radius: radius);

    canvas.saveLayer(rect, Paint());

    final hueStops = List<double>.generate(ringResolution + 1, (i) => i / ringResolution);
    final hueColors = hueStops
        .map((stop) => HSVColor.fromAHSV(1.0, stop * 360.0, 1.0, 1.0).toColor())
        .toList(growable: false);

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = ui.Gradient.sweep(
          center,
          hueColors,
          hueStops,
          TileMode.clamp,
          0.0,
          2 * math.pi,
        ),
    );

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..blendMode = BlendMode.srcATop
        ..shader = ui.Gradient.radial(
          center,
          radius,
          const [Color(0xFFFFFFFF), Color(0x00FFFFFF)],
          const [0.0, 1.0],
        ),
    );

    if (value < 1.0) {
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..blendMode = BlendMode.srcATop
          ..color = Color.fromRGBO(0, 0, 0, (1.0 - value).clamp(0.0, 1.0)),
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant LayrzColorWheelDiscPainter oldDelegate) {
    return oldDelegate.value != value || oldDelegate.ringResolution != ringResolution;
  }
}

/// Paints only the small selection marker at the hue/saturation coordinate
/// currently selected — split out from [LayrzColorWheelDiscPainter]
/// specifically so dragging the marker repaints a single small circle
/// instead of the entire disc. See [LayrzColorWheelDiscPainter]'s doc for
/// the full before/after performance rationale, and [LayrzColorWheel] for
/// how the two painters are stacked.
class LayrzColorWheelMarkerPainter extends CustomPainter {
  /// The currently-selected hue, in degrees `[0, 360)`. Drives the
  /// marker's angular position.
  final double hue;

  /// The currently-selected saturation, in `[0, 1]`. Drives the marker's
  /// radial position (0 = center, 1 = outer edge).
  final double saturation;

  /// The color painted at the marker's exact center, and the color used to
  /// decide the marker ring's own contrasting outline — always the fully
  /// resolved HSV color (hue, saturation, value) currently selected.
  final Color markerColor;

  /// Creates a new [LayrzColorWheelMarkerPainter].
  LayrzColorWheelMarkerPainter({
    required this.hue,
    required this.saturation,
    required this.markerColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    if (radius <= 0) return;

    final angle = hue * math.pi / 180;
    final markerRadius = saturation.clamp(0.0, 1.0) * radius;
    final markerCenter = center + Offset(math.cos(angle), math.sin(angle)) * markerRadius;

    const markerSize = 10.0;

    canvas.drawCircle(markerCenter, markerSize / 2, Paint()..color = markerColor);
    canvas.drawCircle(
      markerCenter,
      markerSize / 2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..color = markerColor.computeLuminance() > 0.5 ? const Color(0xFF000000) : const Color(0xFFFFFFFF),
    );
  }

  @override
  bool shouldRepaint(covariant LayrzColorWheelMarkerPainter oldDelegate) {
    return oldDelegate.hue != hue || oldDelegate.saturation != saturation || oldDelegate.markerColor != markerColor;
  }
}
