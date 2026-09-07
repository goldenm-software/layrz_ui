/// [LayoEmotion.success]-only glyph: a double check mark (a messaging-style
/// "read receipt" ✓✓, two overlapping strokes with the second offset to the
/// right), standing in for this emotion's whole face. No separate mouth/eyes
/// are drawn for [LayoEmotion.success] — the double check is the whole
/// glyph.
///
/// [LayoEmotion.success] is a from-scratch invention with no `.ai`/SVG source
/// to trace, so each check is a plain two-segment stroked path (a short leg
/// then a long leg), in the same `396.15`-wide coordinate space every other
/// emotion's glyphs share.
library;

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// The first (base, left) check mark's own three corner points, in source
/// units: the short leg's start (left), its corner (the check's own low
/// point), and the long leg's end (upper right).
///
/// Shifted `21.255` units left of the original single-check's own resting
/// position (`x 150/186/250`) so that the *pair's* combined bounding box —
/// this check plus the second, offset by [_kSecondCheckOffset] — centers
/// horizontally on the screen window's own center (`x
/// (78.45 + 317.04) / 2 = 197.745`, see `LayoPainter._screenRect`): the pair
/// spans `x 150-288` unshifted (center `219`), `21.255` units right of the
/// screen's own center, so shifting both checks left by that same amount
/// centers the group without changing their relative offset from each
/// other or their vertical position.
const Offset _kCheckStart = Offset(128.745, 210);
const Offset _kCheckCorner = Offset(164.745, 246);
const Offset _kCheckEnd = Offset(228.745, 165);

/// How far the second check mark is offset from the first, in source units
/// — to the right (and very slightly down), so the two strokes overlap
/// rather than sitting side by side, reading as the classic messaging
/// "double tick" rather than two separate check marks.
const Offset _kSecondCheckOffset = Offset(38, 6);

/// The combined path length of both legs (short leg + long leg), in source
/// units, precomputed so [paintSuccessGlyph] can convert [drawT]'s `0..1`
/// fraction into "how far along the whole check" without recomputing this
/// every frame. Both checks share this same length (the second is a pure
/// translation of the first), so one precomputed pair of leg lengths serves
/// both strokes.
double get _kShortLegLength => (_kCheckCorner - _kCheckStart).distance;
double get _kLongLegLength => (_kCheckEnd - _kCheckCorner).distance;

/// Builds one check mark's own path, drawn from [start] through [corner] to
/// [end] and truncated at [drawnLength] units along its combined two-leg
/// length (short leg first, then long leg) — the geometry
/// [paintSuccessGlyph] reuses once for the base check and again, translated
/// by [_kSecondCheckOffset], for the second.
Path _checkPath({
  required Offset start,
  required Offset corner,
  required Offset end,
  required double drawnLength,
}) {
  final path = Path()..moveTo(start.dx, start.dy);
  if (drawnLength <= _kShortLegLength) {
    final segmentT = _kShortLegLength == 0 ? 0.0 : drawnLength / _kShortLegLength;
    final point = Offset.lerp(start, corner, segmentT)!;
    path.lineTo(point.dx, point.dy);
  } else {
    path.lineTo(corner.dx, corner.dy);
    final remaining = drawnLength - _kShortLegLength;
    final segmentT = _kLongLegLength == 0 ? 0.0 : (remaining / _kLongLegLength).clamp(0.0, 1.0);
    final point = Offset.lerp(corner, end, segmentT)!;
    path.lineTo(point.dx, point.dy);
  }
  return path;
}

/// Paints [LayoEmotion.success]'s double check mark: two overlapping check
/// strokes (the second offset to the right and slightly down, per
/// [_kSecondCheckOffset]), each animating its own stroke on from the short
/// leg through to the long leg in lockstep as [drawT] sweeps `0..1`, then
/// settling together with a quick pop/bounce scale derived from [popT].
///
/// At `drawT == 1.0` both checks render at their full, exact resting geometry
/// regardless of [popT]; [popT] only ever scales the *complete* pair (never a
/// partially-drawn one) around their shared bounding-box center, so the two
/// animations compose cleanly: draw-in finishes, then the settle plays.
///
/// [canvas] is the target being painted onto. [k] is the uniform scale
/// factor mapping the shared `396.15`-wide coordinate space onto the painted
/// [Size]. [accentColor] strokes both checks. [drawT] is the stroke's own
/// draw-in progress in `0..1`, `1.0` meaning fully drawn (this emotion's
/// resting pose — a static double check with nothing left to draw is exactly
/// what "success" looks like at rest, the same way [LayoEmotion.dead]'s
/// [dropT]-like fields default to their resting extreme rather than an
/// "unanimated" zero). [popT] is the settle bounce's own progress in `0..1`,
/// `0` meaning no bounce in progress (double check at its exact base scale).
/// Both default to their own caller's responsibility; this function always
/// honors whatever values it is given.
void paintSuccessGlyph(
  Canvas canvas,
  double k, {
  required Color accentColor,
  required double drawT,
  required double popT,
}) {
  final draw = drawT.clamp(0.0, 1.0);
  final totalLength = _kShortLegLength + _kLongLegLength;
  final drawnLength = totalLength * draw;

  final basePath = _checkPath(
    start: _kCheckStart,
    corner: _kCheckCorner,
    end: _kCheckEnd,
    drawnLength: drawnLength,
  );
  final secondPath = _checkPath(
    start: _kCheckStart + _kSecondCheckOffset,
    corner: _kCheckCorner + _kSecondCheckOffset,
    end: _kCheckEnd + _kSecondCheckOffset,
    drawnLength: drawnLength,
  );

  // A quick overshoot-then-settle bounce: scales briefly past 1.0 then back,
  // derived from a sine so it starts and ends exactly at 1.0.
  final pop = popT.clamp(0.0, 1.0);
  final bounceScale = 1.0 + 0.18 * _bounceEnvelope(pop);

  // The shared bounding box spans both checks (the second reaches further
  // right/down than the first), so the bounce pivots around the pair's own
  // combined center rather than the base check's alone.
  final bounds = Rect.fromPoints(_kCheckStart, _kCheckEnd + _kSecondCheckOffset);
  final pivot = bounds.center;

  final paint = Paint()
    ..color = accentColor
    ..style = PaintingStyle.stroke
    ..strokeWidth = 15.0 * k
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..isAntiAlias = true;

  canvas.save();
  canvas.scale(k);
  if (bounceScale != 1.0) {
    canvas.translate(pivot.dx, pivot.dy);
    canvas.scale(bounceScale);
    canvas.translate(-pivot.dx, -pivot.dy);
  }
  // The base (left) check first, then the second (right-offset) check on
  // top, matching the classic double-tick's own reading order.
  canvas.drawPath(basePath, paint);
  canvas.drawPath(secondPath, paint);
  canvas.restore();
}

/// Derives the settle bounce's own envelope from [popT] (`0..1`): a damped
/// sine -- one full oscillation whose amplitude decays across the sweep, so
/// the check overshoots briefly past its resting scale then relaxes back to
/// it, rather than moving symmetrically out and back or sustaining a wobble.
double _bounceEnvelope(double popT) {
  if (popT <= 0.0 || popT >= 1.0) return 0.0;
  final decay = 1.0 - popT;
  final oscillation = math.sin(popT * 2 * math.pi * 1.3);
  return decay * oscillation * 0.45;
}
