/// [LayoEmotion.angry]-only glyphs: two angled brow shapes and a flat mouth
/// bar.
///
/// Every shape here is a verbatim port of the artist's own vector paths from
/// `emo-angry.svg` (same `396.15`-wide source space as the mascot's other
/// emotions), scaled uniformly by the same `k` factor `LayoPainter` derives
/// from the painted [Size]. The source artwork's own fill is overridden by
/// the caller's `accentColor` (this emotion's crimson accent), rather than
/// hardcoding the source fill.
library;

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// How far (in the source's `396.15`-wide units) each brow is translated
/// downward-inward at the peak of a "furrow" burst -- a few source units,
/// small enough to read as a lowering brow rather than the glyph relocating.
const double _kFurrowTranslateY = 4.5;

/// How far (in radians) each brow rotates toward the nose at the peak of a
/// furrow burst -- the left brow rotates clockwise, the right counter-
/// clockwise, so the pair reads as knitting together.
const double _kFurrowRotate = 0.12;

/// The peak horizontal amplitude (in source units) of the high-frequency
/// tremble shake applied to the whole glyph group during a furrow burst.
const double _kTrembleAmplitude = 1.6;

/// How many full shake cycles the tremble completes over one burst -- a
/// fast, high-frequency jitter rather than a slow sway.
const double _kTrembleCycles = 6.0;

/// Paints [LayoEmotion.angry]'s two brows and flat mouth bar, applying a
/// furrow (lower + rotate inward) and a high-frequency horizontal tremble to
/// the whole glyph group, both driven by [burstT].
///
/// [burstT] is `0` at rest (static, unfurrowed, no shake) and sweeps `0..1`
/// across a single burst's lifetime; both the furrow and the tremble ease in
/// and back out across that same sweep (peaking near the middle) so the
/// burst reads as a brief flare rather than a linear wipe. At `burstT == 0`
/// every shape renders at its exact original, unmodified geometry.
///
/// Left brow spans roughly `x 128.6-166.8, y 185.4-214.7`, right brow spans
/// `x 228.8-267.0, y 185.4-214.7`; the mouth bar spans `x 145-250, y
/// 231-253`. All three shapes are ported verbatim from `emo-angry.svg`.
///
/// [canvas] is the target being painted onto. [k] is the uniform scale
/// factor mapping the SVG source's `396.15`-wide coordinate space onto the
/// painted [Size]. [accentColor] fills every shape. [burstT] is the furrow +
/// tremble burst phase in `0..1`. [paintSmoothed] is `LayoPainter`'s shared
/// fill+stroke antialiasing helper, threaded through so this free function
/// does not need a `LayoPainter` instance of its own.
void paintAngryGlyphs(
  Canvas canvas,
  double k, {
  required Color accentColor,
  required double burstT,
  required void Function(Canvas canvas, Color color, double k, void Function(Paint paint) shapeOnto) paintSmoothed,
}) {
  final t = burstT.clamp(0.0, 1.0);
  // A single envelope (0 at both ends, 1 at the middle) drives both the
  // furrow and the tremble's amplitude, so they rise and fall together.
  final envelope = t <= 0.0 ? 0.0 : math.sin(t * math.pi);
  final shakeX = envelope > 0.0 ? _kTrembleAmplitude * math.sin(t * _kTrembleCycles * 2 * math.pi) * k : 0.0;

  canvas.save();
  canvas.translate(shakeX, 0);

  _paintFurrowedBrow(
    canvas,
    k,
    accentColor: accentColor,
    envelope: envelope,
    isLeft: true,
    paintSmoothed: paintSmoothed,
  );
  _paintFurrowedBrow(
    canvas,
    k,
    accentColor: accentColor,
    envelope: envelope,
    isLeft: false,
    paintSmoothed: paintSmoothed,
  );
  _paintMouth(canvas, k, accentColor: accentColor, paintSmoothed: paintSmoothed);

  canvas.restore();
}

/// Paints one brow, furrowed by [envelope] (`0` at rest, `1` at a burst's
/// peak): translated down-and-in and rotated toward the nose. [isLeft]
/// selects which of the two source paths to draw and which rotation
/// direction reads as "toward the nose".
void _paintFurrowedBrow(
  Canvas canvas,
  double k, {
  required Color accentColor,
  required double envelope,
  required bool isLeft,
  required void Function(Canvas canvas, Color color, double k, void Function(Paint paint) shapeOnto) paintSmoothed,
}) {
  final pivot = isLeft ? const Offset(147.7, 200) : const Offset(247.9, 200);
  final path = isLeft ? _leftBrowPath(k) : _rightBrowPath(k);

  if (envelope <= 0.0) {
    paintSmoothed(canvas, accentColor, k, (paint) => canvas.drawPath(path, paint));
    return;
  }

  final pivotScaled = Offset(pivot.dx * k, pivot.dy * k);
  final rotation = (isLeft ? 1 : -1) * _kFurrowRotate * envelope;

  canvas.save();
  canvas.translate(pivotScaled.dx, pivotScaled.dy);
  canvas.rotate(rotation);
  canvas.translate(-pivotScaled.dx, -pivotScaled.dy + _kFurrowTranslateY * envelope * k);
  paintSmoothed(canvas, accentColor, k, (paint) => canvas.drawPath(path, paint));
  canvas.restore();
}

/// The left brow shape: a short, angled wedge ported verbatim from
/// `emo-angry.svg` (bbox roughly `128.6,185.4` to `166.8,214.7`).
Path _leftBrowPath(double k) {
  return Path()
    ..moveTo(159.710938 * k, 194.011719 * k)
    ..cubicTo(166.808594 * k, 196.007812 * k, 152.675781 * k, 214.699219 * k, 144.144531 * k, 209.578125 * k)
    ..cubicTo(135.613281 * k, 204.460938 * k, 128.578125 * k, 202.593750 * k, 128.578125 * k, 194.011719 * k)
    ..cubicTo(128.578125 * k, 185.429688 * k, 152.726562 * k, 191.269531 * k, 159.710938 * k, 194.011719 * k)
    ..close();
}

/// The right brow shape (mirroring the left): a short, angled wedge ported
/// verbatim from `emo-angry.svg` (bbox roughly `228.8,185.4` to
/// `267.0,214.7`).
Path _rightBrowPath(double k) {
  return Path()
    ..moveTo(235.859375 * k, 194.011719 * k)
    ..cubicTo(228.773438 * k, 196.007812 * k, 242.894531 * k, 214.699219 * k, 251.425781 * k, 209.578125 * k)
    ..cubicTo(259.957031 * k, 204.460938 * k, 266.992188 * k, 202.593750 * k, 266.992188 * k, 194.011719 * k)
    ..cubicTo(266.992188 * k, 185.429688 * k, 242.863281 * k, 191.269531 * k, 235.859375 * k, 194.011719 * k)
    ..close();
}

/// Paints the flat mouth bar, spanning `x 145-250, y 231-253`. Ported
/// verbatim from `emo-angry.svg`.
void _paintMouth(
  Canvas canvas,
  double k, {
  required Color accentColor,
  required void Function(Canvas canvas, Color color, double k, void Function(Paint paint) shapeOnto) paintSmoothed,
}) {
  final path = Path()
    ..moveTo(152.019531 * k, 231.222656 * k)
    ..lineTo(243.582031 * k, 231.222656 * k)
    ..cubicTo(247.378906 * k, 231.222656 * k, 250.457031 * k, 234.300781 * k, 250.457031 * k, 238.097656 * k)
    ..lineTo(250.457031 * k, 246.238281 * k)
    ..cubicTo(250.457031 * k, 250.035156 * k, 247.378906 * k, 253.113281 * k, 243.582031 * k, 253.113281 * k)
    ..lineTo(152.019531 * k, 253.113281 * k)
    ..cubicTo(148.222656 * k, 253.113281 * k, 145.144531 * k, 250.035156 * k, 145.144531 * k, 246.238281 * k)
    ..lineTo(145.144531 * k, 238.097656 * k)
    ..cubicTo(145.144531 * k, 234.300781 * k, 148.222656 * k, 231.222656 * k, 152.019531 * k, 231.222656 * k)
    ..close();
  paintSmoothed(canvas, accentColor, k, (paint) => canvas.drawPath(path, paint));
}
