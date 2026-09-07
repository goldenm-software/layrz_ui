/// [LayoEmotion.money]-only glyphs: two green `$` sign eyes, plus this
/// emotion's own **background layer** — a looping rain of falling banknotes
/// behind the whole mascot figure.
///
/// Unlike every other emotion (whose glyphs are pure ports of the artist's
/// vector paths from a source SVG), [LayoEmotion.money] is a from-scratch
/// invention with no `.ai`/SVG source to trace — both the `$` eyes and the
/// bill-rain backdrop are drawn as plain primitive shapes (a stroked path for
/// each `$`, plain rounded rects for the bills) rather than Bézier ports, in
/// the same `396.15`-wide coordinate space every other emotion's glyphs share
/// so it drops into `LayoPainter` unchanged.
library;

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/widgets.dart';

/// How much each `$` eye's scale pulses at the shimmer's peak — a subtle
/// ~8% grow, matching the restraint of this mascot's other gentle idle
/// pulses (e.g. the antenna breath) rather than a distracting bounce.
const double _kMoneyShimmerScale = 0.08;

/// Paints [LayoEmotion.money]'s two `$`-sign eyes, each gently scale-pulsing
/// (a "shimmer") in place around its own center, driven by [moneyT].
///
/// Left `$` is centered around `(158, 206.5)`, right `$` around
/// `(235.5, 206.5)` — the same eye-row coordinates [LayoEmotion.love]'s
/// hearts use — each glyph a vertical stroke with a top and bottom curl (the
/// classic dollar-sign S-curve) plus a single vertical bar through the
/// middle, drawn as strokes rather than filled Bézier ports since there is no
/// source artwork to trace for this from-scratch emotion.
///
/// [canvas] is the target being painted onto. [k] is the uniform scale
/// factor mapping the shared `396.15`-wide coordinate space onto the painted
/// [Size]. [accentColor] strokes both glyphs. [moneyT] is the idle shimmer
/// phase in `0..1`, looping; `0` renders each glyph at its exact resting
/// scale. [paintSmoothed] is `LayoPainter`'s shared fill+stroke antialiasing
/// helper, threaded through so this free function does not need a
/// `LayoPainter` instance of its own (used here only for its stroke pass;
/// the dollar sign itself is drawn as a stroke, not a fill).
void paintMoneyEyes(
  Canvas canvas,
  double k, {
  required Color accentColor,
  required double moneyT,
  required void Function(Canvas canvas, Color color, double k, void Function(Paint paint) shapeOnto) paintSmoothed,
}) {
  final breath = math.sin(moneyT.clamp(0.0, 1.0) * math.pi);
  final scale = 1.0 + _kMoneyShimmerScale * breath;

  _paintDollarGlyph(canvas, k, center: const Offset(158, 206.5), scale: scale, accentColor: accentColor);
  _paintDollarGlyph(canvas, k, center: const Offset(235.5, 206.5), scale: scale, accentColor: accentColor);
}

/// Paints a single `$` glyph centered at [center] (in source units), scaled
/// by [scale] around its own center.
void _paintDollarGlyph(
  Canvas canvas,
  double k, {
  required Offset center,
  required double scale,
  required Color accentColor,
}) {
  const halfHeight = 26.0;
  const halfWidth = 13.0;

  final path = Path()
    // The vertical bar running the full height of the glyph.
    ..moveTo(center.dx, center.dy - halfHeight - 6)
    ..lineTo(center.dx, center.dy + halfHeight + 6)
    // The "S" curve: starts top-right, sweeps to top-left-middle, down to
    // bottom-right-middle, ending bottom-left.
    ..moveTo(center.dx + halfWidth, center.dy - halfHeight + 4)
    ..cubicTo(
      center.dx + halfWidth,
      center.dy - halfHeight - 6,
      center.dx - halfWidth,
      center.dy - halfHeight - 6,
      center.dx - halfWidth,
      center.dy - halfHeight + 10,
    )
    ..cubicTo(
      center.dx - halfWidth,
      center.dy - 2,
      center.dx + halfWidth,
      center.dy - 6,
      center.dx + halfWidth,
      center.dy + halfHeight - 10,
    )
    ..cubicTo(
      center.dx + halfWidth,
      center.dy + halfHeight + 6,
      center.dx - halfWidth,
      center.dy + halfHeight + 6,
      center.dx - halfWidth,
      center.dy + halfHeight - 4,
    );

  final paint = Paint()
    ..color = accentColor
    ..style = PaintingStyle.stroke
    ..strokeWidth = 6.5 * k
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..isAntiAlias = true;

  canvas.save();
  canvas.translate(center.dx * k, center.dy * k);
  canvas.scale(scale, scale);
  canvas.translate(-center.dx * k, -center.dy * k);
  canvas.drawPath(_scalePath(path, k), paint);
  canvas.restore();
}

/// Scales every point of [path] (given in source units) by [k], since
/// [Path] carries no built-in uniform-scale transform of its own short of a
/// full [Matrix4] `transform` call.
Path _scalePath(Path path, double k) {
  final matrix = Float64List.fromList([k, 0, 0, 0, 0, k, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1]);
  return path.transform(matrix);
}

/// One falling bill's own shape and phase, used by [paintMoneyBackdrop] to
/// derive a whole rain of bills from a small fixed set of per-bill seeds
/// rather than a live [math.Random] (which would make the backdrop
/// non-deterministic frame to frame and impossible to test).
class _BillSeed {
  const _BillSeed({required this.xFraction, required this.phaseOffset, required this.speed, required this.tilt});

  /// This bill's horizontal position, as a fraction (`0..1`) of the painted
  /// width — kept as a fraction (rather than a fixed source-unit `x`) so the
  /// rain spreads evenly regardless of the painted [Size].
  final double xFraction;

  /// This bill's own phase offset within the loop, in `0..1`, so bills do
  /// not all fall in lockstep.
  final double phaseOffset;

  /// This bill's relative fall speed multiplier, so nearer/farther bills
  /// (implied by this value alone, no real depth is drawn) drift at
  /// slightly different rates for visual variety.
  final double speed;

  /// This bill's fixed rotation, in radians, so the rain reads as tumbling
  /// bills rather than uniformly upright rectangles.
  final double tilt;
}

/// A small, fixed set of per-bill seeds driving [paintMoneyBackdrop] — see
/// [_BillSeed]. Deliberately hand-picked (not generated from a live
/// [math.Random]) so the backdrop is fully deterministic given [billRainT]
/// alone, which matters both for `shouldRepaint`-style diffing and for this
/// module's own tests.
const List<_BillSeed> _kBillSeeds = [
  _BillSeed(xFraction: 0.08, phaseOffset: 0.00, speed: 1.00, tilt: -0.35),
  _BillSeed(xFraction: 0.22, phaseOffset: 0.35, speed: 1.15, tilt: 0.22),
  _BillSeed(xFraction: 0.40, phaseOffset: 0.65, speed: 0.90, tilt: -0.18),
  _BillSeed(xFraction: 0.58, phaseOffset: 0.10, speed: 1.05, tilt: 0.30),
  _BillSeed(xFraction: 0.74, phaseOffset: 0.50, speed: 0.95, tilt: -0.28),
  _BillSeed(xFraction: 0.90, phaseOffset: 0.80, speed: 1.10, tilt: 0.15),
  _BillSeed(xFraction: 0.02, phaseOffset: 0.55, speed: 1.20, tilt: 0.40),
  _BillSeed(xFraction: 0.65, phaseOffset: 0.90, speed: 0.85, tilt: -0.40),
];

/// One bill rectangle's fixed size, in logical pixels (post-`k` scale, since
/// the backdrop is sized against the painted box itself rather than the
/// shared `396.15`-wide artwork coordinate space every other glyph in this
/// file uses) -- small enough to read as a banknote falling behind the
/// mascot rather than a large card obscuring it.
const double _kBillWidth = 22.0;

/// See [_kBillWidth].
const double _kBillHeight = 12.0;

/// Paints [LayoEmotion.money]'s idle "rain of bills" **background layer**: a
/// small fixed set of falling green banknote rectangles (each with a tiny
/// `$` mark), looping and drifting down behind everything else this painter
/// draws.
///
/// Called first, before the body, so nothing here can ever occlude the
/// mascot's own artwork — see `LayoPainter.paint`'s "Background layers"
/// section. [LayoPainter] clips this call to its own paint [size] before
/// invoking it, so the rain never spills past this widget's own box even
/// though conceptually it sits "behind the whole figure".
///
/// Each bill's vertical position loops smoothly from just above the top edge
/// to just below the bottom edge as [billRainT] sweeps `0..1` (its own
/// speed and horizontal position and tilt fixed per-bill by [_kBillSeeds]),
/// so distinct bills are never in lockstep with each other. At
/// `billRainT == 0` every bill still renders at its own phase-appropriate
/// position (there is no "at rest, invisible" pose for a continuous loop,
/// the same way [LayoEmotion.sleep]'s "zzz" fade has none).
///
/// [canvas] is the target being painted onto. [size] is the full painted
/// box this backdrop fills (not scaled by the shared artwork's own `k`,
/// since the rain is meant to fill this widget's own bounds regardless of
/// the mascot artwork's aspect ratio within it). [billColor] fills each
/// bill's base rectangle. [markColor] fills each bill's small `$` mark.
/// [billRainT] is the idle rain phase in `0..1`, looping.
void paintMoneyBackdrop(
  Canvas canvas,
  Size size, {
  required Color billColor,
  required Color markColor,
  required double billRainT,
}) {
  final t = billRainT.clamp(0.0, 1.0);
  final travel = size.height + _kBillHeight * 2;

  for (final seed in _kBillSeeds) {
    final phase = (t * seed.speed + seed.phaseOffset) % 1.0;
    final y = -_kBillHeight + phase * travel;
    final x = seed.xFraction * size.width;

    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(seed.tilt);

    final rect = Rect.fromCenter(center: Offset.zero, width: _kBillWidth, height: _kBillHeight);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(2.0));
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = billColor
        ..isAntiAlias = true,
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = markColor.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..isAntiAlias = true,
    );

    // A tiny centered "$" mark: a short vertical stroke plus two small
    // opposing curls, scaled down to fit inside the bill.
    final markPaint = Paint()
      ..color = markColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;
    canvas.drawLine(const Offset(0, -4), const Offset(0, 4), markPaint);
    canvas.drawArc(const Rect.fromLTRB(-3, -4, 3, 0), -math.pi / 2, math.pi, false, markPaint);
    canvas.drawArc(const Rect.fromLTRB(-3, 0, 3, 4), math.pi / 2, math.pi, false, markPaint);

    canvas.restore();
  }
}
