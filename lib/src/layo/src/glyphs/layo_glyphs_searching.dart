/// [LayoEmotion.searching]-only glyph: a single blue magnifying-glass glyph
/// standing in for this emotion's whole face, no mouth.
///
/// [LayoEmotion.searching] is a from-scratch invention with no `.ai`/SVG
/// source to trace, so every shape here is a plain primitive (a ringed lens
/// circle plus a short angled handle), in the same `396.15`-wide coordinate
/// space every other emotion's glyphs share.
library;

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// The dark screen window's own rect, in source units — mirrors
/// `LayoPainter._screenRect` (pre-`k`) so this glyph can center itself on the
/// screen's exact center rather than [LayoEmotion.mrLayo]'s own eye row,
/// which sits above the screen's true vertical center.
const Rect _kScreenRect = Rect.fromLTRB(78.45, 123.02, 317.04, 308.80);

/// The lens ring's outer radius, in source units.
const double _kLensRadius = 34.0;

/// The lens ring's stroke width, in source units.
const double _kLensStrokeWidth = 9.0;

/// The handle's own length, in source units, measured from the lens ring's
/// own edge outward along its diagonal.
const double _kHandleLength = 34.0;

/// The handle's stroke width, in source units.
const double _kHandleStrokeWidth = 11.0;

/// The handle's angle, in radians, measured from straight down — a
/// classic bottom-right-angled magnifying-glass handle.
const double _kHandleAngle = math.pi / 4;

/// The whole glyph group's own bounding-box center, relative to the lens
/// ring's own center, in source units -- the handle extends further
/// bottom-right than the lens extends any other direction (its far tip sits
/// [_kLensRadius] + [_kHandleLength] out along [_kHandleAngle], well past
/// the lens ring's own bottom-right edge), so the *visual* center of lens
/// plus handle together sits down-and-right of the lens's own center by
/// roughly half that extra reach.
Offset get _kGroupCenterOffset {
  final handleTipX = (_kLensRadius + _kHandleLength) * math.sin(_kHandleAngle);
  final handleTipY = (_kLensRadius + _kHandleLength) * math.cos(_kHandleAngle);
  // The group's bounding box spans [-_kLensRadius, handleTipX] horizontally
  // and [-_kLensRadius, handleTipY] vertically (relative to the lens
  // center); its own center is the midpoint of each span.
  return Offset((handleTipX - _kLensRadius) / 2, (handleTipY - _kLensRadius) / 2);
}

/// The lens ring's own resting center, in source units -- offset up-and-left
/// from the screen's exact center by [_kGroupCenterOffset], so the *whole*
/// glyph group (lens plus handle) balances on the screen's true center
/// rather than the lens alone.
Offset get _kLensCenter => _kScreenRect.center - _kGroupCenterOffset;

/// The peak horizontal scan distance (in source units) the whole glyph
/// group travels from its resting center during one scan cycle -- small
/// enough (paired with the group's own bounding-box half-extents, roughly
/// 34-48 source units) that the glyph never crosses the screen's own edges
/// (half-width ~119, half-height ~93 around [_kScreenRect]'s own center).
const double _kScanRangeX = 26.0;

/// The peak vertical scan distance (in source units) the whole glyph group
/// travels from its resting center during one scan cycle — smaller than
/// [_kScanRangeX] so the motion reads primarily as side-to-side.
const double _kScanRangeY = 8.0;

/// Paints [LayoEmotion.searching]'s magnifying-glass glyph alone, scanning
/// side to side (and slightly up and down) as [scanT] sweeps `0..1`,
/// looping. No mouth is drawn for this emotion.
///
/// [canvas] is the target being painted onto. [k] is the uniform scale
/// factor mapping the shared `396.15`-wide coordinate space onto the painted
/// [Size]. [accentColor] strokes both the lens ring and the handle. [scanT]
/// is the idle scan phase in `0..1`, looping; `0` renders the glyph at its
/// exact resting position, centered on the screen. [paintSmoothed] is
/// `LayoPainter`'s shared fill+stroke antialiasing helper, threaded through
/// so this free function does not need a `LayoPainter` instance of its own
/// (used here only for its stroke pass).
void paintSearchingGlyph(
  Canvas canvas,
  double k, {
  required Color accentColor,
  required double scanT,
  required void Function(Canvas canvas, Color color, double k, void Function(Paint paint) shapeOnto) paintSmoothed,
}) {
  final phase = scanT.clamp(0.0, 1.0) * 2 * math.pi;
  final offsetX = _kScanRangeX * math.sin(phase);
  final offsetY = _kScanRangeY * math.sin(phase * 2);

  final center = Offset((_kLensCenter.dx + offsetX) * k, (_kLensCenter.dy + offsetY) * k);

  paintSmoothed(
    canvas,
    accentColor,
    k,
    (paint) => canvas.drawCircle(
      center,
      _kLensRadius * k,
      paint
        ..style = PaintingStyle.stroke
        ..strokeWidth = _kLensStrokeWidth * k,
    ),
  );

  final handleStart = Offset(
    center.dx + _kLensRadius * k * math.sin(_kHandleAngle),
    center.dy + _kLensRadius * k * math.cos(_kHandleAngle),
  );
  final handleEnd = Offset(
    center.dx + (_kLensRadius + _kHandleLength) * k * math.sin(_kHandleAngle),
    center.dy + (_kLensRadius + _kHandleLength) * k * math.cos(_kHandleAngle),
  );

  canvas.drawLine(
    handleStart,
    handleEnd,
    Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _kHandleStrokeWidth * k
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true,
  );
}
