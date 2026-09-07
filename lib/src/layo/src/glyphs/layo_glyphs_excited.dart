/// [LayoEmotion.excited]-only glyph: two star-shaped eyes alone, no mouth.
///
/// [LayoEmotion.excited] is a from-scratch invention with no `.ai`/SVG source
/// to trace, so every shape here is a plain primitive (a five-pointed star
/// path for each eye), in the same `396.15`-wide coordinate space every
/// other emotion's glyphs share.
library;

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Each star eye's own resting center, in source units — the same `y
/// 195.73` row as [LayoEmotion.mrLayo]'s own eyes, but pulled closer to the
/// screen's own horizontal center (`x 197.66`) than mrLayo's exact `x
/// 134.67`/`261.17` positions: `50` source units off-center rather than
/// mrLayo's own `~63`.
///
/// [LayoEmotion.mrLayo]'s wide eye spacing reads correctly there because its
/// smile fills the gap between the eyes, anchoring the center visually; this
/// emotion draws no mouth at all, so that same wide spacing reads as two
/// isolated stars pushed toward the screen's own edges rather than a
/// coherent pair of eyes. An initial pass moved the stars in by `40` units
/// (to `x 157.66`/`237.66`), which read as too close together -- crammed
/// toward the middle rather than merely losing the mouth's own anchor -- so
/// this settles roughly halfway between that and mrLayo's own original
/// spacing.
const Offset _kLeftStarCenter = Offset(147.66, 195.73);
const Offset _kRightStarCenter = Offset(247.66, 195.73);

/// The star's own outer/inner point radii, in source units -- a classic
/// five-pointed star silhouette.
const double _kStarOuterRadius = 18.0;
const double _kStarInnerRadius = 7.5;

/// How much each star's scale pulses at the twinkle's peak.
const double _kTwinkleScale = 0.16;

/// The peak rotation (in radians) each star sways through as it twinkles.
const double _kTwinkleRotation = 0.22;

/// The phase offset (as a fraction of a full `0..1` cycle) applied to the
/// right star's twinkle relative to the left, so the two do not sparkle in
/// perfect lockstep.
const double _kTwinklePhaseOffset = 0.3;

/// The peak vertical bounce (in source units) the whole glyph group lifts by
/// at the bounce's peak.
const double _kBouncePeak = 6.0;

/// Paints [LayoEmotion.excited]'s two star-shaped eyes alone, each
/// independently twinkling (scale-pulse plus a slight rotation) as
/// [sparkleT] sweeps `0..1`, looping -- the whole group lifted by a small
/// energetic bounce derived from [bounceT]. No mouth is drawn for this
/// emotion.
///
/// [canvas] is the target being painted onto. [k] is the uniform scale
/// factor mapping the shared `396.15`-wide coordinate space onto the painted
/// [Size]. [accentColor] fills both stars. [sparkleT] is the idle twinkle
/// phase in `0..1`, looping; `0` renders each star at its exact resting
/// scale/rotation. [bounceT] is the idle bounce phase in `0..1`, looping, in
/// sync with [sparkleT]'s own cycle; `0` renders the whole group at its
/// exact resting vertical position. [paintSmoothed] is `LayoPainter`'s
/// shared fill+stroke antialiasing helper, threaded through so this free
/// function does not need a `LayoPainter` instance of its own.
void paintExcitedGlyphs(
  Canvas canvas,
  double k, {
  required Color accentColor,
  required double sparkleT,
  required double bounceT,
  required void Function(Canvas canvas, Color color, double k, void Function(Paint paint) shapeOnto) paintSmoothed,
}) {
  final bounce = math.sin(bounceT.clamp(0.0, 1.0) * math.pi);
  final liftY = -_kBouncePeak * bounce;

  canvas.save();
  canvas.translate(0, liftY * k);

  _paintTwinklingStar(
    canvas,
    k,
    center: _kLeftStarCenter,
    sparkleT: sparkleT,
    phaseOffset: 0.0,
    accentColor: accentColor,
    paintSmoothed: paintSmoothed,
  );
  _paintTwinklingStar(
    canvas,
    k,
    center: _kRightStarCenter,
    sparkleT: sparkleT,
    phaseOffset: _kTwinklePhaseOffset,
    accentColor: accentColor,
    paintSmoothed: paintSmoothed,
  );

  canvas.restore();
}

/// Paints a single star eye at [center], scale-pulsing and rotating in place
/// with a phase offset of [phaseOffset] within the shared [sparkleT] cycle.
void _paintTwinklingStar(
  Canvas canvas,
  double k, {
  required Offset center,
  required double sparkleT,
  required double phaseOffset,
  required Color accentColor,
  required void Function(Canvas canvas, Color color, double k, void Function(Paint paint) shapeOnto) paintSmoothed,
}) {
  final phase = (sparkleT.clamp(0.0, 1.0) + phaseOffset) % 1.0;
  final breath = math.sin(phase * 2 * math.pi);
  final scale = 1.0 + _kTwinkleScale * breath;
  final rotation = _kTwinkleRotation * breath;

  final scaledCenter = Offset(center.dx * k, center.dy * k);
  final path = _starPath(center, k);

  canvas.save();
  canvas.translate(scaledCenter.dx, scaledCenter.dy);
  canvas.rotate(rotation);
  canvas.scale(scale);
  canvas.translate(-scaledCenter.dx, -scaledCenter.dy);
  paintSmoothed(canvas, accentColor, k, (paint) => canvas.drawPath(path, paint));
  canvas.restore();
}

/// Builds a five-pointed star [Path] centered at [center] (in source units,
/// scaled by [k]), alternating [_kStarOuterRadius] and [_kStarInnerRadius] at
/// each of its ten vertices, starting straight up.
Path _starPath(Offset center, double k) {
  final path = Path();
  const points = 5;
  for (var i = 0; i < points * 2; i++) {
    final radius = i.isEven ? _kStarOuterRadius : _kStarInnerRadius;
    final angle = (math.pi / points) * i - math.pi / 2;
    final x = (center.dx + radius * math.cos(angle)) * k;
    final y = (center.dy + radius * math.sin(angle)) * k;
    if (i == 0) {
      path.moveTo(x, y);
    } else {
      path.lineTo(x, y);
    }
  }
  path.close();
  return path;
}
