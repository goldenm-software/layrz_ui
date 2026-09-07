/// [LayoEmotion.sleep]-only glyphs: two closed-eye lines, a single mouth
/// line, and three ascending "zzz" parallelograms drifting off to the upper
/// right.
///
/// Every shape here is a verbatim port of the artist's own vector paths from
/// `sleep.svg` (same `396.15`-wide source space as the mascot's other
/// emotions), scaled uniformly by the same `k` factor `LayoPainter` derives
/// from the painted [Size]. All glyphs paint in grey (`0xFF848484`), unlike
/// [LayoEmotion.mrLayo]'s blue.
library;

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// The phase offset (as a fraction of a full `0..1` cycle) applied to each
/// "zzz" glyph's own opacity pulse relative to [zzzPhase], smallest glyph
/// first -- so the three fade in and out in a staggered sequence rather than
/// all three pulsing in unison. See [paintSleepZzz].
const List<double> _kZzzPhaseOffsets = [0.0, 0.18, 0.36];

/// The opacity floor each "zzz" glyph's fade settles to at its dimmest point
/// -- never fully invisible, so the glyph still reads as present between
/// pulses rather than blinking out completely.
const double _kZzzMinAlpha = 0.25;

/// Derives a single "zzz" glyph's opacity from [zzzPhase] and its own
/// [offset] within [_kZzzPhaseOffsets], as a gentle sine breath between
/// [_kZzzMinAlpha] and fully opaque.
double _zzzAlpha(double zzzPhase, double offset) {
  final phase = (zzzPhase.clamp(0.0, 1.0) + offset) % 1.0;
  final breath = (math.sin(phase * 2 * math.pi) + 1.0) / 2.0;
  return _kZzzMinAlpha + (1.0 - _kZzzMinAlpha) * breath;
}

/// Paints the two short, closed-eye lines standing in for [LayoEmotion.sleep]'s
/// eyes — rounded-cap horizontal bars rather than circles, since this
/// emotion never blinks (its eyes are already closed).
///
/// Left line spans `x 142-182`, right line spans `x 214-254`, both at
/// `y 198-203`. Ported verbatim from `sleep.svg`.
///
/// [canvas] is the target being painted onto. [k] is the uniform scale
/// factor mapping the SVG source's `396.15`-wide coordinate space onto the
/// painted [Size]. [glyphColor] fills both lines. [paintSmoothed] is
/// `LayoPainter`'s shared fill+stroke antialiasing helper, threaded through
/// so this free function does not need a `LayoPainter` instance of its own.
void paintSleepEyes(
  Canvas canvas,
  double k, {
  required Color glyphColor,
  required void Function(Canvas canvas, Color color, double k, void Function(Paint paint) shapeOnto) paintSmoothed,
}) {
  final left = Path()
    ..moveTo(144.429688 * k, 197.964844 * k)
    ..lineTo(179.355469 * k, 197.964844 * k)
    ..cubicTo(180.730469 * k, 197.964844 * k, 181.851562 * k, 199.078125 * k, 181.851562 * k, 200.457031 * k)
    ..cubicTo(181.851562 * k, 201.835938 * k, 180.730469 * k, 202.953125 * k, 179.355469 * k, 202.953125 * k)
    ..lineTo(144.429688 * k, 202.953125 * k)
    ..cubicTo(143.050781 * k, 202.953125 * k, 141.9375 * k, 201.835938 * k, 141.9375 * k, 200.457031 * k)
    ..cubicTo(141.9375 * k, 199.078125 * k, 143.050781 * k, 197.964844 * k, 144.429688 * k, 197.964844 * k)
    ..close();
  paintSmoothed(canvas, glyphColor, k, (paint) => canvas.drawPath(left, paint));

  final right = Path()
    ..moveTo(216.875 * k, 197.964844 * k)
    ..lineTo(251.800781 * k, 197.964844 * k)
    ..cubicTo(253.175781 * k, 197.964844 * k, 254.292969 * k, 199.078125 * k, 254.292969 * k, 200.457031 * k)
    ..cubicTo(254.292969 * k, 201.835938 * k, 253.175781 * k, 202.953125 * k, 251.800781 * k, 202.953125 * k)
    ..lineTo(216.875 * k, 202.953125 * k)
    ..cubicTo(215.496094 * k, 202.953125 * k, 214.378906 * k, 201.835938 * k, 214.378906 * k, 200.457031 * k)
    ..cubicTo(214.378906 * k, 199.078125 * k, 215.496094 * k, 197.964844 * k, 216.875 * k, 197.964844 * k)
    ..close();
  paintSmoothed(canvas, glyphColor, k, (paint) => canvas.drawPath(right, paint));
}

/// Paints the single grey mouth line for [LayoEmotion.sleep], spanning
/// `x 142-254` at `y 239-244`. Ported verbatim from `sleep.svg`.
///
/// [canvas] is the target being painted onto. [k] is the uniform scale
/// factor. [glyphColor] fills the line. [paintSmoothed] is `LayoPainter`'s
/// shared fill+stroke antialiasing helper.
void paintSleepMouth(
  Canvas canvas,
  double k, {
  required Color glyphColor,
  required void Function(Canvas canvas, Color color, double k, void Function(Paint paint) shapeOnto) paintSmoothed,
}) {
  final path = Path()
    ..moveTo(144.429688 * k, 238.644531 * k)
    ..lineTo(251.800781 * k, 238.644531 * k)
    ..cubicTo(253.175781 * k, 238.644531 * k, 254.292969 * k, 239.761719 * k, 254.292969 * k, 241.140625 * k)
    ..cubicTo(254.292969 * k, 242.519531 * k, 253.175781 * k, 243.636719 * k, 251.800781 * k, 243.636719 * k)
    ..lineTo(144.429688 * k, 243.636719 * k)
    ..cubicTo(143.050781 * k, 243.636719 * k, 141.9375 * k, 242.519531 * k, 141.9375 * k, 241.140625 * k)
    ..cubicTo(141.9375 * k, 239.761719 * k, 143.050781 * k, 238.644531 * k, 144.429688 * k, 238.644531 * k)
    ..close();
  paintSmoothed(canvas, glyphColor, k, (paint) => canvas.drawPath(path, paint));
}

/// Paints the three "zzz" parallelograms ascending to the upper right,
/// spanning roughly `x 242-293, y 151-194`. Each is a lightning-bolt-shaped
/// closed path (two parallel diagonal strokes joined by short horizontal
/// caps) ported verbatim from `sleep.svg`, smallest and lowest first.
///
/// Each glyph's opacity is derived independently from [zzzPhase] via
/// [_zzzAlpha], offset by its own entry in [_kZzzPhaseOffsets] (smallest
/// first) so the three fade in and out in a staggered sequence rather than
/// all pulsing in unison -- a simple opacity effect only, with no motion or
/// scale change, per the maintainer's request to keep this glyph's animation
/// simple. At `zzzPhase == 0` every glyph renders at a non-trivial starting
/// alpha (see [_zzzAlpha]'s sine breath), and the very first frame does not
/// need to be fully opaque for this painter to look correct -- there is no
/// "at rest" pose for a looping fade the way [LayoPainter.pulseT] has one.
///
/// [canvas] is the target being painted onto. [k] is the uniform scale
/// factor. [glyphColor] fills all three shapes, modulated by each glyph's own
/// alpha. [zzzPhase] is the idle fade phase in `0..1`, looping.
/// [paintSmoothed] is `LayoPainter`'s shared fill+stroke antialiasing helper.
void paintSleepZzz(
  Canvas canvas,
  double k, {
  required Color glyphColor,
  required double zzzPhase,
  required void Function(Canvas canvas, Color color, double k, void Function(Paint paint) shapeOnto) paintSmoothed,
}) {
  final small = Path()
    ..moveTo(241.960938 * k, 193.582031 * k)
    ..lineTo(252.835938 * k, 177.207031 * k)
    ..lineTo(253.238281 * k, 178.824219 * k)
    ..lineTo(242.527344 * k, 178.824219 * k)
    ..lineTo(242.527344 * k, 175.980469 * k)
    ..lineTo(257.1875 * k, 175.980469 * k)
    ..lineTo(246.300781 * k, 192.363281 * k)
    ..lineTo(245.914062 * k, 190.75 * k)
    ..lineTo(257.007812 * k, 190.75 * k)
    ..lineTo(257.007812 * k, 193.582031 * k)
    ..close();
  paintSmoothed(
    canvas,
    glyphColor.withValues(alpha: _zzzAlpha(zzzPhase, _kZzzPhaseOffsets[0])),
    k,
    (paint) => canvas.drawPath(small, paint),
  );

  final medium = Path()
    ..moveTo(254.125 * k, 186.027344 * k)
    ..lineTo(267.914062 * k, 165.285156 * k)
    ..lineTo(268.414062 * k, 167.277344 * k)
    ..lineTo(254.851562 * k, 167.277344 * k)
    ..lineTo(254.851562 * k, 163.6875 * k)
    ..lineTo(273.414062 * k, 163.6875 * k)
    ..lineTo(259.632812 * k, 184.433594 * k)
    ..lineTo(259.136719 * k, 182.4375 * k)
    ..lineTo(273.183594 * k, 182.4375 * k)
    ..lineTo(273.183594 * k, 186.027344 * k)
    ..close();
  paintSmoothed(
    canvas,
    glyphColor.withValues(alpha: _zzzAlpha(zzzPhase, _kZzzPhaseOffsets[1])),
    k,
    (paint) => canvas.drawPath(medium, paint),
  );

  final large = Path()
    ..moveTo(268.664062 * k, 179.054688 * k)
    ..lineTo(285.796875 * k, 153.257812 * k)
    ..lineTo(286.425781 * k, 155.804688 * k)
    ..lineTo(269.5625 * k, 155.804688 * k)
    ..lineTo(269.5625 * k, 151.332031 * k)
    ..lineTo(292.640625 * k, 151.332031 * k)
    ..lineTo(275.507812 * k, 177.128906 * k)
    ..lineTo(274.878906 * k, 174.582031 * k)
    ..lineTo(292.371094 * k, 174.582031 * k)
    ..lineTo(292.371094 * k, 179.054688 * k)
    ..close();
  paintSmoothed(
    canvas,
    glyphColor.withValues(alpha: _zzzAlpha(zzzPhase, _kZzzPhaseOffsets[2])),
    k,
    (paint) => canvas.drawPath(large, paint),
  );
}
