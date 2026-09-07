/// [LayoEmotion.smug]-only glyphs: two half-lidded blue eyes (a lid line
/// across the top of each) plus an asymmetric smirk.
///
/// [LayoEmotion.smug] is a from-scratch invention with no `.ai`/SVG source to
/// trace, so every shape here is a plain primitive (a circle with a
/// straight-chord lid cut across its top, plus an asymmetric smirk path), in
/// the same `396.15`-wide coordinate space every other emotion's glyphs
/// share. Because this emotion draws a mouth, its eyes sit at
/// [LayoEmotion.mrLayo]'s own canonical eye-row spacing.
library;

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Each eye's own resting center, in source units — [LayoEmotion.mrLayo]'s
/// own canonical eye-row coordinates.
const Offset _kLeftEyeCenter = Offset(134.67, 195.73);
const Offset _kRightEyeCenter = Offset(261.17, 195.73);

/// Each eye's own radius, in source units — [LayoEmotion.mrLayo]'s own eye
/// radius.
const double _kEyeRadius = 15.57;

/// How far down from the eye's own top edge the half-lid line sits at rest,
/// as a fraction of [_kEyeRadius] (`0` is the very top, `1` is the center) --
/// roughly a third of the way down, reading as a relaxed half-closed lid
/// rather than either barely-there or fully shut.
const double _kLidRestFraction = 0.35;

/// How much further the lid line descends at the pulse's peak, as an
/// additional fraction of [_kEyeRadius] on top of [_kLidRestFraction] --
/// small, since this emotion's idle motion is deliberately subtle/understated
/// rather than a full blink.
const double _kLidPulseFraction = 0.12;

/// The smirk's own resting center, in source units — directly below the eye
/// row, at [LayoEmotion.mrLayo]'s own mouth height.
const Offset _kSmirkCenter = Offset(197.93, 245.0);

/// The smirk's half-width, in source units.
const double _kSmirkHalfWidth = 34.0;

/// How far the smirk's raised corner lifts above its resting baseline, in
/// source units -- the asymmetry that reads as a smirk rather than a plain
/// smile.
const double _kSmirkLift = 13.0;

/// How far the smirk's flat corner droops below its resting baseline, in
/// source units.
const double _kSmirkDroop = 2.0;

/// The smirk's stroke width, in source units.
const double _kSmirkStrokeWidth = 8.0;

/// How much further the smirk's raised corner lifts at the pulse's peak, in
/// source units on top of [_kSmirkLift] -- kept small to match the eyes'
/// own understated pulse.
const double _kSmirkPulseLift = 4.0;

/// Paints [LayoEmotion.smug]'s two half-lidded eyes and asymmetric smirk,
/// applying a subtle, understated periodic lid/smirk raise driven by
/// [smugT].
///
/// [smugT] is `0` at rest (its resting half-lid and smirk shape) and sweeps
/// `0..1` across a single pulse's lifetime, easing in and back out (peaking
/// near the middle) so the pulse reads as a brief knowing raise rather than a
/// linear wipe.
///
/// [canvas] is the target being painted onto. [k] is the uniform scale
/// factor mapping the shared `396.15`-wide coordinate space onto the painted
/// [Size]. [accentColor] fills both eyes and strokes the smirk. [smugT] is
/// the idle lid/smirk-raise phase in `0..1`. [paintSmoothed] is
/// `LayoPainter`'s shared fill+stroke antialiasing helper, threaded through
/// so this free function does not need a `LayoPainter` instance of its own.
void paintSmugGlyphs(
  Canvas canvas,
  double k, {
  required Color accentColor,
  required double smugT,
  required void Function(Canvas canvas, Color color, double k, void Function(Paint paint) shapeOnto) paintSmoothed,
}) {
  final t = smugT.clamp(0.0, 1.0);
  final envelope = t <= 0.0 ? 0.0 : math.sin(t * math.pi);

  _paintHalfLiddedEye(canvas, k, center: _kLeftEyeCenter, envelope: envelope, accentColor: accentColor);
  _paintHalfLiddedEye(canvas, k, center: _kRightEyeCenter, envelope: envelope, accentColor: accentColor);
  _paintSmirk(canvas, k, envelope: envelope, accentColor: accentColor);
}

/// Paints a single half-lidded eye at [center] (in source units): the full
/// circle filled first, then a lid chord drawn in the base background by
/// clipping the circle to the region below the lid line -- rather than
/// painting a matching background color over the top (which would break for
/// a caller behind a different background), this draws the visible lower
/// arc directly via a clipped circle.
void _paintHalfLiddedEye(
  Canvas canvas,
  double k, {
  required Offset center,
  required double envelope,
  required Color accentColor,
}) {
  final scaledCenter = Offset(center.dx * k, center.dy * k);
  final lidDepth = (_kLidRestFraction + _kLidPulseFraction * envelope) * _kEyeRadius;
  final lidY = scaledCenter.dy - _kEyeRadius * k + lidDepth * k;

  canvas.save();
  canvas.clipRect(
    Rect.fromLTRB(
      scaledCenter.dx - _kEyeRadius * k - 1,
      lidY,
      scaledCenter.dx + _kEyeRadius * k + 1,
      scaledCenter.dy + _kEyeRadius * k + 1,
    ),
  );
  canvas.drawCircle(
    scaledCenter,
    _kEyeRadius * k,
    Paint()
      ..color = accentColor
      ..isAntiAlias = true,
  );
  canvas.restore();
}

/// Paints the asymmetric smirk: a curved stroke whose right corner lifts
/// well above the baseline and whose left corner droops slightly below it,
/// reading as one side raised in a knowing half-smile.
void _paintSmirk(
  Canvas canvas,
  double k, {
  required double envelope,
  required Color accentColor,
}) {
  final baseline = Offset(_kSmirkCenter.dx * k, _kSmirkCenter.dy * k);
  final left = Offset(baseline.dx - _kSmirkHalfWidth * k, baseline.dy + _kSmirkDroop * k);
  final right = Offset(
    baseline.dx + _kSmirkHalfWidth * k,
    baseline.dy - (_kSmirkLift + _kSmirkPulseLift * envelope) * k,
  );
  final control = Offset(baseline.dx, baseline.dy + (_kSmirkDroop * 0.5) * k);

  final path = Path()
    ..moveTo(left.dx, left.dy)
    ..quadraticBezierTo(control.dx, control.dy, right.dx, right.dy);

  canvas.drawPath(
    path,
    Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _kSmirkStrokeWidth * k
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true,
  );
}
