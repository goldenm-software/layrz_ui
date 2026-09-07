/// [LayoEmotion.working]-only glyph: two amber gears (a larger one and a
/// smaller one, meshed side by side) standing in for this emotion's whole
/// face, no mouth.
///
/// [LayoEmotion.working] is a from-scratch invention with no `.ai`/SVG source
/// to trace, so every shape here is a plain primitive (a toothed gear
/// polygon with a center bore), in the same `396.15`-wide coordinate space
/// every other emotion's glyphs share.
library;

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// The dark screen window's own rect, in source units — mirrors
/// `LayoPainter._screenRect` (pre-`k`) so the two-gear group can be centered
/// on the screen's exact center rather than [LayoEmotion.mrLayo]'s own eye
/// row, which sits above the screen's true vertical center.
const Rect _kScreenRect = Rect.fromLTRB(78.45, 123.02, 317.04, 308.80);

/// The larger gear's own resting center relative to the un-centered layout
/// (screen-left of the smaller gear, which sits up and to its right,
/// meshing at their shared edge) before the whole-group centering offset
/// below is applied.
const Offset _kBigGearRawCenter = Offset(172.0, 195.73);

/// The smaller gear's own resting center relative to the same un-centered
/// layout as [_kBigGearRawCenter].
const Offset _kSmallGearRawCenter = Offset(233.0, 165.0);

/// The larger gear's outer (tooth-tip) radius, in source units.
const double _kBigGearOuterRadius = 34.0;

/// The larger gear's inner (tooth-root) radius, in source units.
const double _kBigGearInnerRadius = 26.0;

/// The larger gear's center bore radius, in source units.
const double _kBigGearBoreRadius = 11.0;

/// The smaller gear's outer (tooth-tip) radius, in source units — roughly
/// 60% of the larger gear's own, so it reads clearly as the smaller of the
/// pair.
const double _kSmallGearOuterRadius = 20.0;

/// The smaller gear's inner (tooth-root) radius, in source units.
const double _kSmallGearInnerRadius = 15.0;

/// The smaller gear's center bore radius, in source units.
const double _kSmallGearBoreRadius = 6.5;

/// How many teeth each gear has.
const int _kGearTeeth = 8;

/// The two-gear group's own bounding box under the raw (un-centered) layout,
/// combining the larger gear's own outer circle and the smaller gear's own
/// outer circle -- used to derive [_kGroupCenteringOffset] so the *whole*
/// meshed pair balances on the screen's true center.
Rect get _kRawGroupBounds {
  final big = Rect.fromCircle(center: _kBigGearRawCenter, radius: _kBigGearOuterRadius);
  final small = Rect.fromCircle(center: _kSmallGearRawCenter, radius: _kSmallGearOuterRadius);
  return big.expandToInclude(small);
}

/// How far to translate both gears (in source units) so the raw layout's own
/// bounding-box center ([_kRawGroupBounds]) lands exactly on the screen's
/// true center ([_kScreenRect]'s own center) -- applied once to both
/// [_kBigGearRawCenter] and [_kSmallGearRawCenter] alike, so their relative
/// positions (and the meshing at their shared edge) are unchanged.
Offset get _kGroupCenteringOffset => _kScreenRect.center - _kRawGroupBounds.center;

/// The larger gear's own resting center, in source units, after centering
/// the whole two-gear group on the screen.
Offset get _kBigGearCenter => _kBigGearRawCenter + _kGroupCenteringOffset;

/// The smaller gear's own resting center, in source units, after centering
/// the whole two-gear group on the screen.
Offset get _kSmallGearCenter => _kSmallGearRawCenter + _kGroupCenteringOffset;

/// Paints [LayoEmotion.working]'s two meshed gears alone, continuously
/// rotating (the smaller gear counter-rotating against the larger one, like
/// real meshed teeth) as [gearT] sweeps `0..1`, looping. No mouth is drawn
/// for this emotion.
///
/// [canvas] is the target being painted onto. [k] is the uniform scale
/// factor mapping the shared `396.15`-wide coordinate space onto the painted
/// [Size]. [accentColor] fills both gears. [gearT] is the idle rotation
/// phase in `0..1`, looping; `0` renders both gears at their exact resting
/// rotation. [paintSmoothed] is `LayoPainter`'s shared fill+stroke
/// antialiasing helper, threaded through so this free function does not need
/// a `LayoPainter` instance of its own.
void paintWorkingGlyphs(
  Canvas canvas,
  double k, {
  required Color accentColor,
  required double gearT,
  required void Function(Canvas canvas, Color color, double k, void Function(Paint paint) shapeOnto) paintSmoothed,
}) {
  final t = gearT.clamp(0.0, 1.0);
  final bigRotation = t * 2 * math.pi;
  final smallRotation = -t * 2 * math.pi * (_kBigGearOuterRadius / _kSmallGearOuterRadius);

  _paintGear(
    canvas,
    k,
    center: _kBigGearCenter,
    outerRadius: _kBigGearOuterRadius,
    innerRadius: _kBigGearInnerRadius,
    boreRadius: _kBigGearBoreRadius,
    rotation: bigRotation,
    accentColor: accentColor,
    paintSmoothed: paintSmoothed,
  );
  _paintGear(
    canvas,
    k,
    center: _kSmallGearCenter,
    outerRadius: _kSmallGearOuterRadius,
    innerRadius: _kSmallGearInnerRadius,
    boreRadius: _kSmallGearBoreRadius,
    rotation: smallRotation,
    accentColor: accentColor,
    paintSmoothed: paintSmoothed,
  );
}

/// Paints a single gear at [center] (in source units), rotated by
/// [rotation] radians around its own center: a toothed ring path (alternating
/// [outerRadius] and [innerRadius] at each tooth flank) with a punched-out
/// center [boreRadius] hole via the even-odd fill rule.
void _paintGear(
  Canvas canvas,
  double k, {
  required Offset center,
  required double outerRadius,
  required double innerRadius,
  required double boreRadius,
  required double rotation,
  required Color accentColor,
  required void Function(Canvas canvas, Color color, double k, void Function(Paint paint) shapeOnto) paintSmoothed,
}) {
  final scaledCenter = Offset(center.dx * k, center.dy * k);

  final path = Path()..fillType = PathFillType.evenOdd;
  const pointsPerTooth = 4;
  final totalPoints = _kGearTeeth * pointsPerTooth;
  for (var i = 0; i < totalPoints; i++) {
    final angle = (2 * math.pi / totalPoints) * i;
    final isOuter = (i % pointsPerTooth) < 2;
    final radius = isOuter ? outerRadius : innerRadius;
    final x = scaledCenter.dx + radius * k * math.cos(angle);
    final y = scaledCenter.dy + radius * k * math.sin(angle);
    if (i == 0) {
      path.moveTo(x, y);
    } else {
      path.lineTo(x, y);
    }
  }
  path.close();
  path.addOval(Rect.fromCircle(center: scaledCenter, radius: boreRadius * k));

  canvas.save();
  canvas.translate(scaledCenter.dx, scaledCenter.dy);
  canvas.rotate(rotation);
  canvas.translate(-scaledCenter.dx, -scaledCenter.dy);
  paintSmoothed(canvas, accentColor, k, (paint) => canvas.drawPath(path, paint));
  canvas.restore();
}
