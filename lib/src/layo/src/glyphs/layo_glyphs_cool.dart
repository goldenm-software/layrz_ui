/// [LayoEmotion.cool]-only glyph: a blue sunglasses **overlay** — two lenses
/// joined by a bridge — drawn on top of the head shell exactly like
/// [LayoEmotion.comandante]'s beret (see `LayoPainter`'s "Overlays" section),
/// hiding the eyes underneath entirely. The mouth underneath reuses
/// [LayoEmotion.mrLayo]'s own smile unmodified.
///
/// [LayoEmotion.cool] is a from-scratch invention with no `.ai`/SVG source to
/// trace, so the sunglasses are drawn as plain primitives (two rounded-rect
/// lenses plus a bridge bar), in the same `396.15`-wide coordinate space
/// every other emotion's glyphs share. The lenses and bridge are filled in
/// this emotion's own blue accent (the same blue as the mouth and antenna
/// dot) rather than a literal dark tint — a dark fill reads as nearly
/// invisible against the mascot's own dark screen background, so the accent
/// blue is what actually makes the glasses read clearly there.
library;

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// The sunglasses bar's own vertical center, in source units —
/// [LayoEmotion.mrLayo]'s own eye-row height (`y 195.73`), so the lenses sit
/// exactly where the eyes they hide would be.
const double _kGlassesCenterY = 195.73;

/// Each lens's own half-width, in source units.
const double _kLensHalfWidth = 32.0;

/// Each lens's own half-height, in source units.
const double _kLensHalfHeight = 19.0;

/// Each lens's own corner radius, in source units.
const double _kLensCornerRadius = 9.0;

/// The horizontal distance from the shared vertical axis (`x 197.66`) to
/// each lens's own center, in source units.
const double _kLensOffsetX = 63.0;

/// The bridge bar's own height, in source units.
const double _kBridgeHeight = 6.0;

/// The peak width (as a fraction of [_kLensHalfWidth] * 2) of the gleam
/// sweep highlight.
const double _kGleamWidthFraction = 0.28;

/// Paints [LayoEmotion.cool]'s sunglasses overlay: two rounded-rect lenses
/// joined by a bridge, both filled in [accentColor], with a subtle gleam
/// sweeping across the right lens as [gleamT] sweeps `0..1`.
///
/// [gleamT] is `0` between gleams (no highlight visible) and sweeps `0..1`
/// across a single gleam's lifetime, the highlight's own horizontal position
/// tracking that sweep left to right across the lens.
///
/// [canvas] is the target being painted onto. [k] is the uniform scale
/// factor mapping the shared `396.15`-wide coordinate space onto the painted
/// [Size]. [accentColor] fills both lenses and the bridge — this emotion's
/// own blue accent, matching the mouth and antenna dot, so the glasses read
/// clearly against the dark screen behind them. [gleamT] is the idle
/// gleam-sweep phase in `0..1`, `0` meaning no gleam in progress.
/// [paintSmoothed] is `LayoPainter`'s shared fill+stroke antialiasing
/// helper, threaded through so this free function does not need a
/// `LayoPainter` instance of its own.
void paintCoolSunglasses(
  Canvas canvas,
  double k, {
  required Color accentColor,
  required double gleamT,
  required void Function(Canvas canvas, Color color, double k, void Function(Paint paint) shapeOnto) paintSmoothed,
}) {
  final leftCenter = Offset((197.66 - _kLensOffsetX) * k, _kGlassesCenterY * k);
  final rightCenter = Offset((197.66 + _kLensOffsetX) * k, _kGlassesCenterY * k);

  final bridge = Rect.fromLTRB(
    leftCenter.dx + _kLensHalfWidth * k * 0.6,
    _kGlassesCenterY * k - _kBridgeHeight * k / 2,
    rightCenter.dx - _kLensHalfWidth * k * 0.6,
    _kGlassesCenterY * k + _kBridgeHeight * k / 2,
  );
  canvas.drawRect(
    bridge,
    Paint()
      ..color = accentColor
      ..isAntiAlias = true,
  );

  _paintLens(canvas, k, center: leftCenter, accentColor: accentColor, paintSmoothed: paintSmoothed);
  _paintLens(canvas, k, center: rightCenter, accentColor: accentColor, paintSmoothed: paintSmoothed);

  final t = gleamT.clamp(0.0, 1.0);
  if (t > 0.0) {
    _paintGleam(canvas, k, lensCenter: rightCenter, gleamT: t);
  }
}

/// Paints a single rounded-rect lens at [center] (already in painted-pixel
/// coordinates, i.e. pre-scaled by [k]), filled in [accentColor].
void _paintLens(
  Canvas canvas,
  double k, {
  required Offset center,
  required Color accentColor,
  required void Function(Canvas canvas, Color color, double k, void Function(Paint paint) shapeOnto) paintSmoothed,
}) {
  final rrect = RRect.fromRectAndRadius(
    Rect.fromCenter(center: center, width: _kLensHalfWidth * 2 * k, height: _kLensHalfHeight * 2 * k),
    Radius.circular(_kLensCornerRadius * k),
  );
  paintSmoothed(canvas, accentColor, k, (paint) => canvas.drawRRect(rrect, paint));
}

/// Paints a soft diagonal gleam highlight sweeping across [lensCenter]'s own
/// lens, its horizontal position tracking [gleamT] from the lens's left edge
/// to its right edge.
void _paintGleam(
  Canvas canvas,
  double k, {
  required Offset lensCenter,
  required double gleamT,
}) {
  final envelope = math.sin(gleamT * math.pi);
  if (envelope <= 0.0) return;

  final sweepX = lensCenter.dx - _kLensHalfWidth * k + (2 * _kLensHalfWidth * k) * gleamT;
  final gleamWidth = _kLensHalfWidth * 2 * k * _kGleamWidthFraction;

  final rect = Rect.fromCenter(
    center: Offset(sweepX, lensCenter.dy),
    width: gleamWidth,
    height: _kLensHalfHeight * 2 * k,
  );

  canvas.save();
  canvas.clipRRect(
    RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: lensCenter,
        width: _kLensHalfWidth * 2 * k,
        height: _kLensHalfHeight * 2 * k,
      ),
      Radius.circular(_kLensCornerRadius * k),
    ),
  );
  canvas.drawRect(
    rect,
    Paint()
      ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.28 * envelope)
      ..isAntiAlias = true,
  );
  canvas.restore();
}
