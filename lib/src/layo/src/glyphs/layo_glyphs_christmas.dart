/// [LayoEmotion.christmas]-only glyphs: the Santa hat **overlay** (with its
/// tucked-in poinsettia and holly sprig), the red-and-white sweater **body
/// overlay**, and the looping snowfall **background layer**.
///
/// Like [LayoEmotion.money] and [LayoEmotion.cool], this is a from-scratch
/// invention with no `.ai`/SVG source to trace — every shape here is a plain
/// primitive (paths built from lines/arcs/cubics, rounded rects, circles)
/// drawn directly in the same `396.15`-wide coordinate space every other
/// emotion's glyphs share, so it drops into `LayoPainter` unchanged. The
/// sweater introduces this file's own reusable **body-overlay** mechanism
/// (see `LayoPainter._paintEmotionBodyOverlay`) — the first time any emotion
/// dresses the body dome itself, rather than only the head (an overlay) or
/// the chest (a chest-insignia glyph).
library;

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Festive Christmas red, used for the hat's main body, the poinsettia's
/// petals, and the sweater's base — a warmer, brighter red than
/// [LayoEmotion.angry]'s own crimson accent, chosen to read as "Christmas
/// red" rather than "furious red".
const Color kChristmasRed = Color(0xFFC62828);

/// Holly-green, used for the holly sprig's leaves.
const Color kChristmasGreen = Color(0xFF1B5E20);

/// The poinsettia's small center and one of the sweater band's alternating
/// motif colors — warm gold.
const Color kChristmasGold = Color(0xFFF5CC24);

/// Snow/fur white, used for the hat's brim and pom-pom, the sweater's
/// zigzag band, and every snowflake.
const Color kChristmasWhite = Color(0xFFFFFFFF);

/// A near-black outline color used two ways in this file: as the bold
/// cartoon-sticker edge traced around the Santa hat's entire silhouette (see
/// [_boldOutlinePaint]) — so its white parts (the fur brim, the pom-pom)
/// never go invisible against this design system's light body/head — and,
/// at a lower alpha, for the snowfall's own hairline flake edges. Kept as
/// its own named constant (rather than reusing [kChristmasWhite] or a raw
/// literal) since it exists purely to define an edge, never to fill a shape.
const Color _kChristmasOutline = Color(0xFF1A1A1A);

// ---------------------------------------------------------------------------
// Santa hat + poinsettia + holly (head overlay)
// ---------------------------------------------------------------------------

/// The hat brim's own vertical center, in native units — level with the top
/// of the head shell's rounded corners, so the thick white fur brim sits
/// right at the head's own edge rather than floating above or sinking into
/// it.
const double _kHatBrimCenterY = 112.0;

/// The brim's half-height (its own thickness), in native units — a chunky
/// band rather than a thin trim line, matching a classic Santa hat's own
/// proportions.
const double _kHatBrimHalfHeight = 26.0;

/// The bold near-black outline stroke traced around the hat's cone, brim and
/// pom-pom, so the whole hat reads with a cartoon-sticker edge.
Paint _boldOutlinePaint(double k) => Paint()
  ..color = _kChristmasOutline
  ..style = PaintingStyle.stroke
  ..strokeWidth = 3.2 * k
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round
  ..isAntiAlias = true;

/// The cone base's left/right edges (native units), spanning the brim width.
const double _kHatBaseLeftX = 52.0;
const double _kHatBaseRightX = 343.0;

/// The cone's peak height (native units, up is negative y).
const double _kHatPeak = -26.0;

/// The cone's folded tip — where the right edge rises to and the fold happens.
const Offset _kHatTipRest = Offset(278, 2);

/// The pom-pom center — at the end of the fold, overlapping the tip.
const Offset _kHatPomPom = Offset(292, 8);

/// Builds the red cone: one solid smooth shape, base on the brim, sweeping up
/// over a rounded peak and leaning right to the folded tip. Single closed
/// silhouette (no union); the fold's tuck is a separate crease line on top.
Path _christmasHatConePath(double k) {
  final baseY = _kHatBrimCenterY - 2;
  final tip = _kHatTipRest;

  return Path()
    ..moveTo(_kHatBaseLeftX * k, baseY * k)
    // Left side rises STEEPLY inward to a skinny peak (a narrower cone),
    // peaking around x160 where the fold begins.
    ..cubicTo(110 * k, 40 * k, 140 * k, (_kHatPeak - 4) * k, 160 * k, (_kHatPeak - 4) * k)
    // From the point, slim down-right into the folded tip.
    ..cubicTo(200 * k, (_kHatPeak + 10) * k, 245 * k, (tip.dy + 12) * k, tip.dx * k, tip.dy * k)
    // Right edge: a nearly-straight diagonal from the tip down to the far
    // bottom-right corner (control points held on the line so it doesn't
    // bulge), then the bottom edge straight-left to the base-left corner.
    ..cubicTo(
      (tip.dx + (_kHatBaseRightX - tip.dx) * 0.4) * k,
      (tip.dy + (baseY - tip.dy) * 0.4) * k,
      (tip.dx + (_kHatBaseRightX - tip.dx) * 0.75) * k,
      (tip.dy + (baseY - tip.dy) * 0.75) * k,
      _kHatBaseRightX * k,
      baseY * k,
    )
    ..lineTo(_kHatBaseLeftX * k, baseY * k)
    ..close();
}

/// Builds the fold crease — a dark line drawn ON the red near the tip that
/// reaches toward the pom-pom and doubles back on itself (a cusp), showing the
/// fabric tuck. Open path, stroked only.
Path _christmasHatCreasePath(double k) {
  final tip = _kHatTipRest;

  return Path()
    ..moveTo(215 * k, (_kHatPeak + 34) * k)
    ..cubicTo(255 * k, (_kHatPeak + 30) * k, (tip.dx - 26) * k, (tip.dy - 6) * k, (tip.dx - 14) * k, (tip.dy + 2) * k)
    ..cubicTo((tip.dx - 30) * k, (tip.dy - 4) * k, 250 * k, (_kHatPeak + 40) * k, 222 * k, (_kHatPeak + 44) * k);
}

/// Paints [LayoEmotion.christmas]'s Santa hat **overlay**: two simple red
/// pieces merged into one silhouette (see [paintChristmasHat]'s own union
/// merge below) — a plain rounded-mound **base dome** spanning almost the
/// head's own full width (see [_christmasHatBasePath]) and a diagonal
/// wedge/flag **fold** overlapping its peak, tapering down and to the right
/// to a small curled droop (see [_christmasHatFoldPath]) — together reading
/// as one continuous classic Santa hat despite being two independently
/// simple shapes. A white pom-pom hangs from the droop, a thick white fur
/// brim caps the head's full width below the base, and a small poinsettia
/// and holly sprig tuck against the brim's own opposite (left) side. Every
/// shape carries a bold near-black outline, reading as a classic cartoon
/// Santa hat.
///
/// Drawn on top of the head shell exactly like [paintComandanteBeret] and
/// `paintCoolSunglasses` (see `LayoPainter`'s "Overlays" section) — this
/// emotion has no antenna at all (see `LayoPainter._hasAntenna`), so nothing
/// constrains how far the fold may lean above the head, though it is
/// deliberately kept within the beret's own visual envelope rather than
/// towering over it.
///
/// [canvas] is the target being painted onto. [k] is the uniform scale
/// factor mapping the shared `396.15`-wide coordinate space onto the painted
/// [Size]. [pomPomSwayT] is the pom-pom's own idle sway phase in `0..1`,
/// looping; `0` renders it at its exact resting position. [paintSmoothed] is
/// `LayoPainter`'s shared fill+stroke antialiasing helper, threaded through
/// so this free function does not need a `LayoPainter` instance of its own.
void paintChristmasHat(
  Canvas canvas,
  double k, {
  required double pomPomSwayT,
  required void Function(Canvas canvas, Color color, double k, void Function(Paint paint) shapeOnto) paintSmoothed,
}) {
  // All four pieces are the artist's own paths (Gorrito e navida.ai), ported
  // verbatim via _hatPathFromSvg and mapped onto the head by _hatXf.

  final cone = _christmasHatConePath(k);

  // 1) Red cone body, filled + bold outline.
  paintSmoothed(canvas, kChristmasRed, k, (paint) => canvas.drawPath(cone, paint));
  canvas.drawPath(cone, _boldOutlinePaint(k));

  // The folded-over flip, in a DARKER red so it reads as fabric catching less
  // light than the main cone. Drapes from the peak (flip point at ~x155) over
  // and right to the pom-pom, with a longer tail.
  final flip = Path()
    ..moveTo(155 * k, (_kHatPeak - 4) * k)
    ..cubicTo(205 * k, (_kHatPeak - 14) * k, 270 * k, (_kHatPeak - 6) * k, 292 * k, 8 * k)
    ..cubicTo(282 * k, 30 * k, 230 * k, 30 * k, 190 * k, 18 * k)
    ..cubicTo(172 * k, 12 * k, 160 * k, 4 * k, 155 * k, (_kHatPeak - 4) * k)
    ..close();
  // A subtly darker red than the cone (not a heavy contrast) so the fold
  // reads as folded fabric without looking muddy.
  const flipRed = Color(0xFFB0222A);
  paintSmoothed(canvas, flipRed, k, (paint) => canvas.drawPath(flip, paint));
  canvas.drawPath(flip, _boldOutlinePaint(k));

  // 2) The fold crease -- a dark line on the red near the tip, doubling back
  // on itself so the fabric reads as folded. Stroked only.
  final crease = _christmasHatCreasePath(k);
  canvas.drawPath(
    crease,
    Paint()
      ..color = _kChristmasOutline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6 * k
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true,
  );

  // 3) White fur brim band across the bottom of the cone.
  final brimRect = Rect.fromLTRB(
    50 * k,
    (_kHatBrimCenterY - _kHatBrimHalfHeight) * k,
    345 * k,
    (_kHatBrimCenterY + _kHatBrimHalfHeight) * k,
  );
  final brim = RRect.fromRectAndRadius(brimRect, Radius.circular(_kHatBrimHalfHeight * k));
  paintSmoothed(canvas, kChristmasWhite, k, (paint) => canvas.drawRRect(brim, paint));
  canvas.drawRRect(brim, _boldOutlinePaint(k));

  // 4) The pom-pom at the folded tip, gently swaying on pomPomSwayT.
  final swaySin = math.sin(pomPomSwayT.clamp(0.0, 1.0) * math.pi * 2);
  final swayCos = math.cos(pomPomSwayT.clamp(0.0, 1.0) * math.pi * 2);
  const pomPomSwayRadius = 3.0;
  final pomPomCenter = Offset(
    (_kHatPomPom.dx + swaySin * pomPomSwayRadius) * k,
    (_kHatPomPom.dy + swayCos * pomPomSwayRadius * 0.5) * k,
  );
  paintSmoothed(canvas, kChristmasWhite, k, (paint) => canvas.drawCircle(pomPomCenter, 24 * k, paint));
  canvas.drawCircle(pomPomCenter, 24 * k, _boldOutlinePaint(k));

  // The poinsettia and holly tuck against the brim's own opposite (right)
  // side, well clear of the cone's own drooping tip and pom-pom on the left.
  _paintPoinsettia(canvas, k, center: const Offset(95, _kHatBrimCenterY), scale: 1.6);
  _paintHolly(canvas, k, center: const Offset(140, _kHatBrimCenterY - 2), scale: 1.6);
}

/// Paints a small Flor de Navidad (poinsettia): five-to-six red pointed
/// petals arranged radially around a small gold center, tucked against the
/// hat's own brim.
///
/// [canvas] is the target being painted onto. [k] is the uniform scale
/// factor. [center] is the poinsettia's own center, in native units. [scale]
/// uniformly scales every petal/center dimension (default `1.0`), so this
/// glyph can be sized up to read clearly against the hat's own thick brim
/// without re-deriving its own geometry.
void _paintPoinsettia(Canvas canvas, double k, {required Offset center, double scale = 1.0}) {
  const petalCount = 6;
  final petalLength = 20.0 * scale;
  final petalHalfWidth = 7.0 * scale;

  final petalPaint = Paint()
    ..color = kChristmasRed
    ..isAntiAlias = true;
  final petalOutlinePaint = Paint()
    ..color = kChristmasRed
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.6 * k
    ..isAntiAlias = true;

  for (var i = 0; i < petalCount; i++) {
    final angle = (i / petalCount) * math.pi * 2 - math.pi / 2;
    final tip = Offset(
      center.dx + math.cos(angle) * petalLength,
      center.dy + math.sin(angle) * petalLength,
    );
    final perpendicular = Offset(-math.sin(angle), math.cos(angle));
    final baseLeft = Offset(
      center.dx + perpendicular.dx * petalHalfWidth,
      center.dy + perpendicular.dy * petalHalfWidth,
    );
    final baseRight = Offset(
      center.dx - perpendicular.dx * petalHalfWidth,
      center.dy - perpendicular.dy * petalHalfWidth,
    );

    final petal = Path()
      ..moveTo(center.dx * k, center.dy * k)
      ..lineTo(baseLeft.dx * k, baseLeft.dy * k)
      ..quadraticBezierTo(tip.dx * k, tip.dy * k, baseRight.dx * k, baseRight.dy * k)
      ..close();
    canvas.drawPath(petal, petalPaint);
    canvas.drawPath(petal, petalOutlinePaint);
  }

  canvas.drawCircle(
    Offset(center.dx * k, center.dy * k),
    6.0 * scale * k,
    Paint()
      ..color = kChristmasGold
      ..isAntiAlias = true,
  );
}

/// Paints a small holly sprig: two-to-three pointed green leaves plus a
/// cluster of small red berries, tucked beside the poinsettia.
///
/// [canvas] is the target being painted onto. [k] is the uniform scale
/// factor. [center] is the sprig's own approximate center, in native units.
/// [scale] uniformly scales every leaf/berry dimension (default `1.0`), so
/// this glyph can be sized up to read clearly against the hat's own thick
/// brim without re-deriving its own geometry.
void _paintHolly(Canvas canvas, double k, {required Offset center, double scale = 1.0}) {
  final leafPaint = Paint()
    ..color = kChristmasGreen
    ..isAntiAlias = true;

  const leafAngles = [-0.7, 0.0, 0.7];
  for (final angle in leafAngles) {
    final tip = Offset(center.dx + math.sin(angle) * 18 * scale, center.dy - math.cos(angle) * 16 * scale);
    final leftBulge = Offset(
      center.dx + math.sin(angle - 0.6) * 9 * scale,
      center.dy - math.cos(angle - 0.6) * 8 * scale,
    );
    final rightBulge = Offset(
      center.dx + math.sin(angle + 0.6) * 9 * scale,
      center.dy - math.cos(angle + 0.6) * 8 * scale,
    );

    final leaf = Path()
      ..moveTo(center.dx * k, center.dy * k)
      ..quadraticBezierTo(leftBulge.dx * k, leftBulge.dy * k, tip.dx * k, tip.dy * k)
      ..quadraticBezierTo(rightBulge.dx * k, rightBulge.dy * k, center.dx * k, center.dy * k)
      ..close();
    canvas.drawPath(leaf, leafPaint);
  }

  final berryPaint = Paint()
    ..color = kChristmasRed
    ..isAntiAlias = true;
  final berryOffsets = [Offset(-4, 4) * scale, Offset(4, 5) * scale, Offset(0, 9) * scale];
  for (final offset in berryOffsets) {
    canvas.drawCircle(Offset((center.dx + offset.dx) * k, (center.dy + offset.dy) * k), 3.0 * scale * k, berryPaint);
  }
}

// ---------------------------------------------------------------------------
// Sweater (body overlay)
// ---------------------------------------------------------------------------

/// The outer body dome's own path, in native units — an exact copy of
/// `LayoPainter._paintBody`'s `outer` path, duplicated here (rather than
/// threaded through as a parameter) so this file's sweater can redraw it in
/// red without `LayoPainter` needing to expose its private body geometry.
Path _outerBodyDomePath(double k) {
  return Path()
    ..moveTo(395.30 * k, 553.49 * k)
    ..cubicTo(395.30 * k, 412.90 * k, 306.81 * k, 298.94 * k, 197.66 * k, 298.94 * k)
    ..cubicTo(88.50 * k, 298.94 * k, 0 * k, 412.90 * k, 0 * k, 553.49 * k)
    ..cubicTo(0 * k, 694.08 * k, 395.30 * k, 694.10 * k, 395.30 * k, 553.49 * k)
    ..close();
}

/// The inner body panel's own path, in native units — an exact copy of
/// `LayoPainter._paintBody`'s `inner` path, duplicated here (rather than
/// threaded through as a parameter) so this file's sweater can redraw it in
/// red without `LayoPainter` needing to expose its private body geometry.
Path _innerBodyDomePath(double k) {
  return Path()
    ..moveTo(344.16 * k, 550.26 * k)
    ..cubicTo(346.09 * k, 410.56 * k, 286.93 * k, 323.56 * k, 196.83 * k, 323.64 * k)
    ..cubicTo(106.56 * k, 323.72 * k, 45.04 * k, 422.35 * k, 49.50 * k, 550.26 * k)
    ..cubicTo(53.89 * k, 675.35 * k, 342.43 * k, 675.41 * k, 344.16 * k, 550.26 * k)
    ..close();
}

/// The outer sweater dome's own darker red — [LayoEmotion.christmas]'s
/// recoloring of `LayoPainter.bodyOuterColor`'s own light default
/// (`0xFFEAE9EA`). Deliberately the *darker* of the two sweater reds even
/// though the plain body's own outer shell is the *lighter* of its two greys
/// — the inversion the maintainer asked for, so the same rim/depth
/// separation the plain body has still reads once both domes are red.
const Color kChristmasSweaterOuterRed = Color(0xFF8E1414);

/// The inner sweater dome's own lighter red — [LayoEmotion.christmas]'s
/// recoloring of `LayoPainter.bodyInnerColor`'s own darker-grey default
/// (`0xFFD4D2D3`). See [kChristmasSweaterOuterRed] for why this is the
/// *lighter* of the two reds despite recoloring the plain body's own
/// *darker* inner panel.
const Color kChristmasSweaterInnerRed = Color(0xFFD33030);

/// Paints [LayoEmotion.christmas]'s **body overlay**: a full red-and-white
/// Christmas sweater recoloring the *entire* body — both the outer dome and
/// the inner panel — preserving the exact same two-tone rim/depth
/// separation the plain grey body has (see [kChristmasSweaterOuterRed] and
/// [kChristmasSweaterInnerRed]), plus a white fair-isle zigzag band across the
/// chest and a small snowflake motif above it.
///
/// This is the first emotion to dress the body itself — every earlier
/// costumed emotion only touched the head ([LayoEmotion.comandante]'s beret,
/// [LayoEmotion.cool]'s sunglasses) or the chest
/// ([LayoEmotion.comandante]'s ribbon rack) — introducing
/// `LayoPainter._paintEmotionBodyOverlay` as a new, reusable dispatch
/// mechanism any future costumed emotion can plug into the same way.
///
/// Drawn immediately after `LayoPainter._paintBody`, so both dome shapes
/// are redrawn here at their own exact geometry (see [_outerBodyDomePath]
/// and [_innerBodyDomePath]) directly on top of the plain grey body,
/// occluding it completely rather than tinting it — the sweater spans the
/// *full* body silhouette, not a chest-only patch. Everything drawn here is
/// additionally clipped to the outer dome's own silhouette, so nothing can
/// ever spill past the body's own edge.
///
/// [canvas] is the target being painted onto. [k] is the uniform scale
/// factor mapping the shared `396.15`-wide coordinate space onto the painted
/// [Size]. [paintSmoothed] is `LayoPainter`'s shared fill+stroke
/// antialiasing helper, threaded through so this free function does not need
/// a `LayoPainter` instance of its own.
void paintChristmasSweater(
  Canvas canvas,
  double k, {
  required void Function(Canvas canvas, Color color, double k, void Function(Paint paint) shapeOnto) paintSmoothed,
}) {
  final outerDome = _outerBodyDomePath(k);
  final innerDome = _innerBodyDomePath(k);

  canvas.save();
  canvas.clipPath(outerDome);

  paintSmoothed(canvas, kChristmasSweaterOuterRed, k, (paint) => canvas.drawPath(outerDome, paint));
  paintSmoothed(canvas, kChristmasSweaterInnerRed, k, (paint) => canvas.drawPath(innerDome, paint));

  _paintFairIsleBand(canvas, k, topY: 470);
  _paintSweaterSnowflake(canvas, k, center: const Offset(196.83, 400), radius: 24);

  canvas.restore();
}

/// Paints a horizontal fair-isle zigzag band across the sweater's chest: a
/// row of small white chevrons.
void _paintFairIsleBand(Canvas canvas, double k, {required double topY}) {
  const bandHeight = 26.0;
  const chevronWidth = 24.0;
  const left = 40.0;
  const right = 355.0;

  final band = Rect.fromLTRB(left * k, topY * k, right * k, (topY + bandHeight) * k);
  canvas.drawRect(
    band,
    Paint()
      ..color = kChristmasWhite.withValues(alpha: 0.92)
      ..isAntiAlias = true,
  );

  final chevronPaint = Paint()
    ..color = kChristmasRed
    ..style = PaintingStyle.stroke
    ..strokeWidth = 5.0 * k
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..isAntiAlias = true;

  var x = left - chevronWidth / 2;
  while (x < right + chevronWidth) {
    final path = Path()
      ..moveTo(x * k, topY * k)
      ..lineTo((x + chevronWidth / 2) * k, (topY + bandHeight) * k)
      ..lineTo((x + chevronWidth) * k, topY * k);
    canvas.drawPath(path, chevronPaint);
    x += chevronWidth;
  }
}

/// Paints a single simple six-point snowflake motif knitted above the
/// sweater's own fair-isle band.
void _paintSweaterSnowflake(Canvas canvas, double k, {required Offset center, required double radius}) {
  final paint = Paint()
    ..color = kChristmasWhite.withValues(alpha: 0.92)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 4.0 * k
    ..strokeCap = StrokeCap.round
    ..isAntiAlias = true;

  final c = Offset(center.dx * k, center.dy * k);
  for (var i = 0; i < 6; i++) {
    final angle = (i / 6) * math.pi * 2;
    final end = Offset(c.dx + math.cos(angle) * radius * k, c.dy + math.sin(angle) * radius * k);
    canvas.drawLine(c, end, paint);

    final branchBase = Offset(c.dx + math.cos(angle) * radius * k * 0.6, c.dy + math.sin(angle) * radius * k * 0.6);
    for (final delta in [-0.5, 0.5]) {
      final branchAngle = angle + delta;
      final branchEnd = Offset(
        branchBase.dx + math.cos(branchAngle) * radius * k * 0.28,
        branchBase.dy + math.sin(branchAngle) * radius * k * 0.28,
      );
      canvas.drawLine(branchBase, branchEnd, paint);
    }
  }
}

// ---------------------------------------------------------------------------
// Snowfall (background layer)
// ---------------------------------------------------------------------------

/// One falling snowflake's own position and phase, used by
/// [paintChristmasSnowfall] to derive a whole snowfall from a small fixed
/// set of per-flake seeds rather than a live [math.Random] (which would make
/// the backdrop non-deterministic frame to frame and impossible to test) —
/// the same technique [LayoEmotion.money]'s own `_BillSeed` uses for its
/// bill rain.
class _SnowflakeSeed {
  const _SnowflakeSeed({
    required this.xFraction,
    required this.phaseOffset,
    required this.speed,
    required this.driftAmplitude,
    required this.radius,
  });

  /// This flake's horizontal position, as a fraction (`0..1`) of the painted
  /// width, before drift is applied.
  final double xFraction;

  /// This flake's own phase offset within the loop, in `0..1`, so flakes do
  /// not all fall in lockstep.
  final double phaseOffset;

  /// This flake's relative fall speed multiplier.
  final double speed;

  /// How far this flake drifts side to side, in logical pixels, as it falls.
  final double driftAmplitude;

  /// This flake's own radius, in logical pixels.
  final double radius;
}

/// A small, fixed set of per-flake seeds driving [paintChristmasSnowfall] —
/// see [_SnowflakeSeed]. Deliberately hand-picked (not generated from a live
/// [math.Random]) so the backdrop is fully deterministic given [snowT]
/// alone, mirroring [LayoEmotion.money]'s own `_kBillSeeds`.
const List<_SnowflakeSeed> _kSnowflakeSeeds = [
  _SnowflakeSeed(xFraction: 0.05, phaseOffset: 0.00, speed: 1.00, driftAmplitude: 10, radius: 3.0),
  _SnowflakeSeed(xFraction: 0.15, phaseOffset: 0.30, speed: 0.80, driftAmplitude: 14, radius: 4.5),
  _SnowflakeSeed(xFraction: 0.28, phaseOffset: 0.55, speed: 1.15, driftAmplitude: 8, radius: 2.5),
  _SnowflakeSeed(xFraction: 0.40, phaseOffset: 0.10, speed: 0.90, driftAmplitude: 12, radius: 3.5),
  _SnowflakeSeed(xFraction: 0.55, phaseOffset: 0.70, speed: 1.05, driftAmplitude: 16, radius: 4.0),
  _SnowflakeSeed(xFraction: 0.68, phaseOffset: 0.20, speed: 0.85, driftAmplitude: 9, radius: 2.8),
  _SnowflakeSeed(xFraction: 0.80, phaseOffset: 0.45, speed: 1.10, driftAmplitude: 13, radius: 3.8),
  _SnowflakeSeed(xFraction: 0.90, phaseOffset: 0.85, speed: 0.95, driftAmplitude: 11, radius: 3.0),
  _SnowflakeSeed(xFraction: 0.02, phaseOffset: 0.60, speed: 1.20, driftAmplitude: 7, radius: 2.2),
  _SnowflakeSeed(xFraction: 0.95, phaseOffset: 0.05, speed: 0.75, driftAmplitude: 15, radius: 4.2),
  _SnowflakeSeed(xFraction: 0.35, phaseOffset: 0.90, speed: 1.00, driftAmplitude: 10, radius: 3.2),
  _SnowflakeSeed(xFraction: 0.60, phaseOffset: 0.15, speed: 0.88, driftAmplitude: 12, radius: 3.6),
];

/// Paints [LayoEmotion.christmas]'s idle "snowfall" **background layer**: a
/// small fixed set of falling white snowflakes (simple six-point stars),
/// looping and drifting down behind everything else this painter draws.
///
/// Called first, before the body, so nothing here can ever occlude the
/// mascot's own artwork — see `LayoPainter.paint`'s "Background layers"
/// section and [LayoEmotion.money]'s own `paintMoneyBackdrop`, which this
/// mirrors closely. [LayoPainter] clips this call to its own paint [size]
/// before invoking it, so the snowfall never spills past this widget's own
/// box even though conceptually it sits "behind the whole figure".
///
/// Each flake's vertical position loops smoothly from just above the top
/// edge to just below the bottom edge as [snowT] sweeps `0..1` (its own
/// speed, horizontal position, and drift amplitude fixed per-flake by
/// [_kSnowflakeSeeds]), with a gentle side-to-side sine drift layered on top
/// so the fall reads as gently tumbling rather than perfectly vertical. At
/// `snowT == 0` every flake still renders at its own phase-appropriate
/// position — there is no "at rest, invisible" pose for a continuous loop,
/// the same way [LayoEmotion.money]'s bill rain has none.
///
/// [canvas] is the target being painted onto. [size] is the full painted
/// box this backdrop fills (not scaled by the shared artwork's own `k`,
/// since the snowfall is meant to fill this widget's own bounds regardless
/// of the mascot artwork's aspect ratio within it). [snowT] is the idle
/// snowfall phase in `0..1`, looping.
void paintChristmasSnowfall(Canvas canvas, Size size, {required double snowT}) {
  final t = snowT.clamp(0.0, 1.0);
  final maxRadius = _kSnowflakeSeeds.map((s) => s.radius).reduce(math.max);
  final travel = size.height + maxRadius * 4;

  final paint = Paint()
    ..color = kChristmasWhite
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.4
    ..strokeCap = StrokeCap.round
    ..isAntiAlias = true;
  final dotPaint = Paint()
    ..color = kChristmasWhite
    ..isAntiAlias = true;
  // A slim near-black outline behind every flake -- the backdrop is drawn
  // first, well before the body/head exist, so this cannot tell (short of
  // re-deriving the body's own silhouette here) whether a given flake will
  // end up over the light figure/background or the dark screen once the
  // rest of `paint` draws on top -- but a hairline dark ring reads as a
  // subtle "snow has depth/shadow" edge against the dark screen too, so
  // applying it unconditionally keeps every flake visible everywhere
  // without needing that distinction. See `_outlinePaint` (this file's
  // hat/pom-pom helper); kept separate here since these outlines are drawn
  // at the raw painted-[Size] scale, not the shared artwork's own `k`.
  final dotOutlinePaint = Paint()
    ..color = _kChristmasOutline.withValues(alpha: 0.55)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.8
    ..isAntiAlias = true;
  final starOutlinePaint = Paint()
    ..color = _kChristmasOutline.withValues(alpha: 0.55)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.6
    ..strokeCap = StrokeCap.round
    ..isAntiAlias = true;

  for (final seed in _kSnowflakeSeeds) {
    final phase = (t * seed.speed + seed.phaseOffset) % 1.0;
    final y = -maxRadius * 2 + phase * travel;
    final drift = math.sin(phase * math.pi * 2) * seed.driftAmplitude;
    final x = seed.xFraction * size.width + drift;
    final center = Offset(x, y);

    if (seed.radius <= 3.0) {
      // Small flakes render as a plain soft dot -- reads as distant snow
      // without the cost of six strokes per flake.
      canvas.drawCircle(center, seed.radius, dotOutlinePaint);
      canvas.drawCircle(center, seed.radius, dotPaint);
      continue;
    }

    // The outline is drawn first, a touch wider than the white stroke on
    // top of it, so only a thin dark ring survives around the star's own
    // edge rather than the outline showing through its center.
    for (var i = 0; i < 3; i++) {
      final angle = (i / 3) * math.pi;
      final dx = math.cos(angle) * seed.radius;
      final dy = math.sin(angle) * seed.radius;
      final from = Offset(center.dx - dx, center.dy - dy);
      final to = Offset(center.dx + dx, center.dy + dy);
      canvas.drawLine(from, to, starOutlinePaint);
      canvas.drawLine(from, to, paint);
    }
  }
}
