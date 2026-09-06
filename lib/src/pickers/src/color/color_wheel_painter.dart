import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Paints a classic HSV color wheel disc — hue swept around the ring
/// (0° at the positive x-axis, increasing counter-clockwise to match
/// [Canvas.drawArc]'s own angle convention), saturation mapped to radius
/// (0 at the center, 1 at the outer edge) — plus a small selection marker
/// at the currently-picked hue/saturation coordinate.
///
/// **Kept in its own file per rule #3** (one concern per file): this class
/// owns only the paint routine; [LayrzColorWheel] (`color_wheel.dart`) owns
/// gesture hit-testing, the value/brightness control, and the public widget
/// contract. Splitting them means a change to the paint routine alone never
/// touches gesture math and vice versa.
///
/// **From scratch, Material-free.** No `ColorPicker`, no
/// `HueRingPicker` — only [Canvas.drawArc]-based polar-coordinate painting
/// with a manually composited [Gradient] per ring segment, per the project's
/// Material/Cupertino-free invariant.
///
/// **Brightness (the HSV "V" component) is deliberately NOT represented on
/// this disc.** Per Decision D-wheel (implementation plan), the wheel
/// disc renders hue × saturation only; [LayrzColorWheel] composes a
/// separate value/brightness slider alongside it — mirroring how every
/// reference HSV-wheel implementation (and the classic macOS/Windows
/// system pickers) splits the two concerns rather than painting a 3D
/// property onto a 2D disc.
class LayrzColorWheelPainter extends CustomPainter {
  /// The currently-selected hue, in degrees `[0, 360)`. Drives the marker's
  /// angular position.
  final double hue;

  /// The currently-selected saturation, in `[0, 1]`. Drives the marker's
  /// radial position (0 = center, 1 = outer edge).
  final double saturation;

  /// The current value/brightness, in `[0, 1]`, applied uniformly to every
  /// pixel of the disc so the wheel visually dims/brightens together with
  /// the separate value slider [LayrzColorWheel] renders alongside it.
  final double value;

  /// The color painted at the marker's exact center, and the color used to
  /// decide the marker ring's own contrasting outline — always the fully
  /// resolved HSV color (hue, saturation, value) currently selected.
  final Color markerColor;

  /// The number of concentric rings the disc is painted with. Higher values
  /// render a smoother saturation gradient at the cost of more draw calls.
  /// Defaults to `100`, a value tuned to look continuous at typical wheel
  /// sizes (200–320 logical pixels) without noticeably taxing paint time.
  final int ringResolution;

  /// Creates a new [LayrzColorWheelPainter].
  LayrzColorWheelPainter({
    required this.hue,
    required this.saturation,
    required this.value,
    required this.markerColor,
    this.ringResolution = 100,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    if (radius <= 0) return;

    _paintDisc(canvas, center, radius);
    _paintMarker(canvas, center, radius);
  }

  /// Paints the hue/saturation disc as [ringResolution] concentric rings,
  /// each ring itself swept as 360 one-degree arcs so hue varies smoothly
  /// around the circumference. Every ring's saturation is held constant
  /// across its own sweep and increases outward from `0` (center, fully
  /// desaturated — i.e. `value`-only white/grey) to `1` (outer edge, fully
  /// saturated).
  void _paintDisc(Canvas canvas, Offset center, double radius) {
    final ringWidth = radius / ringResolution;

    for (var ring = 0; ring < ringResolution; ring++) {
      final innerRadius = ring * ringWidth;
      final outerRadius = innerRadius + ringWidth + 0.5; // +0.5 avoids anti-aliasing seams between rings.
      final ringSaturation = ring / (ringResolution - 1);

      final rect = Rect.fromCircle(center: center, radius: outerRadius);

      // One arc per degree so the hue sweep reads as a continuous gradient
      // rather than a small number of flat-colored wedges.
      for (var degree = 0; degree < 360; degree++) {
        final paint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = outerRadius - innerRadius
          ..color = HSVColor.fromAHSV(1.0, degree.toDouble(), ringSaturation, value).toColor();

        // Canvas angles increase clockwise from the positive x-axis in
        // Flutter's coordinate space; degrees here are used directly as hue
        // degrees, so hue 0 (red) starts at the positive x-axis and sweeps
        // clockwise — the same convention `_angleToHue`/`_hueToAngle` in
        // `color_wheel.dart` use, so painted hue and hit-tested hue always
        // agree.
        canvas.drawArc(
          rect,
          degree * math.pi / 180,
          math.pi / 180 + 0.02, // Slight overlap between adjacent arcs closes anti-aliasing gaps.
          false,
          paint,
        );
      }
    }
  }

  /// Paints a small ring-shaped marker at the hue/saturation coordinate
  /// currently selected, using [markerColor] as its fill so the marker
  /// itself previews the exact color that coordinate resolves to.
  void _paintMarker(Canvas canvas, Offset center, double radius) {
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
  bool shouldRepaint(covariant LayrzColorWheelPainter oldDelegate) {
    return oldDelegate.hue != hue ||
        oldDelegate.saturation != saturation ||
        oldDelegate.value != value ||
        oldDelegate.markerColor != markerColor ||
        oldDelegate.ringResolution != ringResolution;
  }
}
