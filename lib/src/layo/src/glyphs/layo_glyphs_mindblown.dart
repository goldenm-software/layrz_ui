/// [LayoEmotion.mindBlown]-only glyphs: two magenta spiral eyes plus an open
/// "O" mouth.
///
/// [LayoEmotion.mindBlown] is a from-scratch invention with no `.ai`/SVG
/// source to trace, so every shape here is a plain primitive (an Archimedean
/// spiral path for each eye, a stroked circle for the mouth), in the same
/// `396.15`-wide coordinate space every other emotion's glyphs share. Because
/// this emotion draws a mouth, its eyes sit at [LayoEmotion.mrLayo]'s own
/// canonical eye-row spacing rather than the closer mouthless spacing
/// [LayoEmotion.excited] and [LayoEmotion.sad] use.
library;

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Each spiral eye's own resting center, in source units — [LayoEmotion.mrLayo]'s
/// own canonical eye-row coordinates, since this emotion draws a mouth to
/// anchor that wider spacing.
const Offset _kLeftEyeCenter = Offset(134.67, 195.73);
const Offset _kRightEyeCenter = Offset(261.17, 195.73);

/// The spiral's own outermost radius, in source units.
const double _kSpiralMaxRadius = 16.5;

/// How many full turns each spiral's path winds through.
const double _kSpiralTurns = 2.2;

/// The spiral's stroke width, in source units.
const double _kSpiralStrokeWidth = 3.2;

/// How many straight segments approximate each spiral's curve — enough for a
/// visually smooth spiral without an excessive point count.
const int _kSpiralSegments = 64;

/// The open "O" mouth's own resting center, in source units — directly below
/// the eye row, at [LayoEmotion.mrLayo]'s own mouth height.
const Offset _kMouthCenter = Offset(197.93, 245.0);

/// The mouth's outer radius, in source units.
const double _kMouthRadius = 17.0;

/// The mouth's stroke width, in source units.
const double _kMouthStrokeWidth = 9.0;

/// The peak scale/shake amplitude of a "pop" burst, applied to the whole
/// glyph group.
const double _kPopScale = 0.14;

/// The peak horizontal shake amplitude (in source units) of a "pop" burst.
const double _kPopShakeAmplitude = 3.0;

/// How many shake cycles a single pop burst completes.
const double _kPopShakeCycles = 3.0;

/// Paints [LayoEmotion.mindBlown]'s two spiral eyes and open "O" mouth,
/// spinning both spirals continuously as [spinT] sweeps `0..1`, looping, and
/// layering a periodic jittered "pop" burst (a quick scale/shake on the
/// whole glyph group) driven by [popT].
///
/// [canvas] is the target being painted onto. [k] is the uniform scale
/// factor mapping the shared `396.15`-wide coordinate space onto the painted
/// [Size]. [accentColor] strokes both spirals and the mouth. [spinT] is the
/// idle spiral-spin phase in `0..1`, looping; `0` renders both spirals at
/// their exact resting rotation. [popT] is the pop-burst phase in `0..1`, `0`
/// at rest between bursts. [paintSmoothed] is `LayoPainter`'s shared
/// fill+stroke antialiasing helper, threaded through so this free function
/// does not need a `LayoPainter` instance of its own.
void paintMindBlownGlyphs(
  Canvas canvas,
  double k, {
  required Color accentColor,
  required double spinT,
  required double popT,
  required void Function(Canvas canvas, Color color, double k, void Function(Paint paint) shapeOnto) paintSmoothed,
}) {
  final pop = popT.clamp(0.0, 1.0);
  final envelope = pop <= 0.0 ? 0.0 : math.sin(pop * math.pi);
  final scale = 1.0 + _kPopScale * envelope;
  final shakeX = _kPopShakeAmplitude * math.sin(pop * _kPopShakeCycles * 2 * math.pi) * envelope;

  final groupCenter = Offset(197.93 * k, 220.0 * k);

  canvas.save();
  canvas.translate(groupCenter.dx, groupCenter.dy);
  canvas.translate(shakeX * k, 0);
  canvas.scale(scale);
  canvas.translate(-groupCenter.dx, -groupCenter.dy);

  final rotation = spinT.clamp(0.0, 1.0) * 2 * math.pi;
  _paintSpiralEye(canvas, k, center: _kLeftEyeCenter, rotation: rotation, accentColor: accentColor);
  _paintSpiralEye(canvas, k, center: _kRightEyeCenter, rotation: -rotation, accentColor: accentColor);

  paintSmoothed(
    canvas,
    accentColor,
    k,
    (paint) => canvas.drawCircle(
      Offset(_kMouthCenter.dx * k, _kMouthCenter.dy * k),
      _kMouthRadius * k,
      paint
        ..style = PaintingStyle.stroke
        ..strokeWidth = _kMouthStrokeWidth * k,
    ),
  );

  canvas.restore();
}

/// Paints a single Archimedean-spiral eye at [center] (in source units),
/// rotated by [rotation] radians around its own center.
void _paintSpiralEye(
  Canvas canvas,
  double k, {
  required Offset center,
  required double rotation,
  required Color accentColor,
}) {
  final scaledCenter = Offset(center.dx * k, center.dy * k);
  final path = Path();

  for (var i = 0; i <= _kSpiralSegments; i++) {
    final fraction = i / _kSpiralSegments;
    final angle = fraction * _kSpiralTurns * 2 * math.pi + rotation;
    final radius = fraction * _kSpiralMaxRadius;
    final x = scaledCenter.dx + radius * k * math.cos(angle);
    final y = scaledCenter.dy + radius * k * math.sin(angle);
    if (i == 0) {
      path.moveTo(x, y);
    } else {
      path.lineTo(x, y);
    }
  }

  canvas.drawPath(
    path,
    Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _kSpiralStrokeWidth * k
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true,
  );
}
