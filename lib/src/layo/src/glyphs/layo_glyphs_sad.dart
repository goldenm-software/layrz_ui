/// [LayoEmotion.sad]-only glyphs: two open eyes (circles, matching the shared
/// mascot's usual open-eyed look rather than a closed or downturned shape)
/// and a single tear that periodically wells up and slides down the left
/// eye. No mouth is drawn for this emotion at all.
///
/// [LayoEmotion.sad] is a from-scratch invention with no `.ai`/SVG source to
/// trace, so every shape here is a plain primitive (circles for the open
/// eyes, a teardrop path for the tear), in the same `396.15`-wide coordinate
/// space every other emotion's glyphs share.
library;

import 'package:flutter/widgets.dart';

/// Each eye's own center (in source units) and radius — the same `y 195.73`
/// row and `15.57` radius as [LayoEmotion.mrLayo]'s own open eyes, but pulled
/// closer to the screen's own horizontal center (`x 197.66`) than mrLayo's
/// exact `x 134.67`/`261.17` positions: `50` source units off-center rather
/// than mrLayo's own `~63`.
///
/// [LayoEmotion.mrLayo]'s wide eye spacing reads correctly there because its
/// smile fills the gap between the eyes, anchoring the center visually; this
/// emotion draws no mouth at all, so that same wide spacing reads as two
/// isolated dots pushed toward the screen's own edges rather than a
/// coherent pair of eyes. An initial pass moved the eyes in by `40` units
/// (to `x 157.66`/`237.66`), which read as too close together -- crammed
/// toward the middle rather than merely losing the mouth's own anchor -- so
/// this settles roughly halfway between that and mrLayo's own original
/// spacing, while keeping this emotion's sadness expressed entirely through
/// the tear rather than through a downturned or half-closed eye shape.
const Offset _kLeftEyeCenter = Offset(147.66, 195.73);
const Offset _kRightEyeCenter = Offset(247.66, 195.73);
const double _kEyeRadius = 15.57;

/// Paints [LayoEmotion.sad]'s two open eyes: a plain filled circle each, at
/// the shared mascot's usual open-eye geometry.
///
/// [canvas] is the target being painted onto. [k] is the uniform scale
/// factor mapping the shared `396.15`-wide coordinate space onto the painted
/// [Size]. [glyphColor] fills both eyes. [paintSmoothed] is `LayoPainter`'s
/// shared fill+stroke antialiasing helper, threaded through so this free
/// function does not need a `LayoPainter` instance of its own.
void paintSadEyes(
  Canvas canvas,
  double k, {
  required Color glyphColor,
  required void Function(Canvas canvas, Color color, double k, void Function(Paint paint) shapeOnto) paintSmoothed,
}) {
  for (final center in [_kLeftEyeCenter, _kRightEyeCenter]) {
    final scaledCenter = Offset(center.dx * k, center.dy * k);
    paintSmoothed(canvas, glyphColor, k, (paint) => canvas.drawCircle(scaledCenter, _kEyeRadius * k, paint));
  }
}

/// Paints [LayoEmotion.sad]'s single tear, welling up just beneath the left
/// eye and sliding straight down as [tearT] sweeps `0..1`; invisible at
/// `tearT <= 0` (between drips).
///
/// The tear is a simple teardrop: a circle with a pointed top, tracing the
/// classic droplet silhouette. Its vertical position interpolates from just
/// under the left eye's own lower rim down to well below the eye row (this
/// emotion draws no mouth for the drip to pass), and its opacity fades in
/// quickly at the start of the drip and back out just
/// before it reaches its lowest point, so it reads as one droplet appearing,
/// falling, and being absorbed rather than a shape that pops in and out
/// abruptly.
///
/// [canvas] is the target being painted onto. [k] is the uniform scale
/// factor mapping the shared `396.15`-wide coordinate space onto the painted
/// [Size]. [accentColor] fills the tear — this emotion's grey glyph color,
/// passed through by whichever name the caller uses for it.
/// [tearT] is the drip's own progress in `0..1`, `0` (and below) meaning no
/// tear is in progress. [paintSmoothed] is `LayoPainter`'s shared
/// fill+stroke antialiasing helper, threaded through so this free function
/// does not need a `LayoPainter` instance of its own.
void paintSadTear(
  Canvas canvas,
  double k, {
  required Color accentColor,
  required double tearT,
  required void Function(Canvas canvas, Color color, double k, void Function(Paint paint) shapeOnto) paintSmoothed,
}) {
  final t = tearT.clamp(0.0, 1.0);
  if (t <= 0.0) return;

  final startY = _kLeftEyeCenter.dy + _kEyeRadius + 2;
  final endY = startY + 70;
  final centerX = _kLeftEyeCenter.dx;
  final centerY = startY + (endY - startY) * t;

  // Fade in over the first 15% of the drip, and back out over the last 15%,
  // so the droplet does not pop discretely into or out of existence.
  final alpha = t < 0.15 ? (t / 0.15) : (t > 0.85 ? (1.0 - t) / 0.15 : 1.0);
  if (alpha <= 0.0) return;

  const radius = 6.0;
  final path = Path()
    ..moveTo(centerX * k, (centerY - radius * 1.6) * k)
    ..quadraticBezierTo(
      (centerX + radius) * k,
      (centerY - radius * 0.2) * k,
      (centerX + radius) * k,
      (centerY + radius * 0.4) * k,
    )
    ..arcToPoint(
      Offset((centerX - radius) * k, (centerY + radius * 0.4) * k),
      radius: Radius.circular(radius * k),
      clockwise: true,
    )
    ..quadraticBezierTo(
      (centerX - radius) * k,
      (centerY - radius * 0.2) * k,
      centerX * k,
      (centerY - radius * 1.6) * k,
    )
    ..close();

  paintSmoothed(
    canvas,
    accentColor.withValues(alpha: alpha.clamp(0.0, 1.0)),
    k,
    (paint) => canvas.drawPath(path, paint),
  );
}
