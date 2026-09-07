/// [LayoEmotion.alert]-only glyphs: two orange "!" glyphs (a stem + a dot
/// each) standing in for this emotion's eyes. No mouth is drawn for
/// [LayoEmotion.alert].
///
/// Every shape here is a verbatim port of the artist's own vector paths from
/// `emo-warning.svg` (same `396.15`-wide source space as the mascot's other
/// emotions), scaled uniformly by the same `k` factor `LayoPainter` derives
/// from the painted [Size]. The source artwork's own fill is overridden by
/// the caller's `accentColor` (this emotion's exact `#FF9800` orange), rather
/// than hardcoding the source fill.
library;

import 'package:flutter/widgets.dart';

/// Each stem's resting half-width (in source units), derived from the
/// original rounded-rect stem paths (`176.132812 - 159.945312 == 16.1875`
/// wide, so `8.09375` either side of the stem's own centerline).
const double _kStemHalfWidth = 8.09375;

/// How far (in source units) the stem's *top* edge widens outward, per
/// side, at the attention beat's peak -- tuned so the top reads clearly as
/// an inverted-triangle/funnel silhouette (wide at top, tapering to the
/// stem's normal narrow width at the bottom) without the top corners
/// crossing into the neighbouring glyph or off the screen edge.
const double _kTopWidenPeak = 9.5;

/// The stem's fixed rounded-corner radius (in source units), matching the
/// original path's own corner rounding, reused for the (still narrow,
/// unanimated) bottom corners of the funnel shape at every [double]
/// envelope value.
const double _kCornerRadius = 3.95;

/// Paints [LayoEmotion.alert]'s two "!" glyphs (stem + dot each). The dot
/// stays in place; the stem's own silhouette animates its *top* edge
/// outward into an inverted-triangle/funnel shape at the attention beat's
/// peak, tapering back to the stem's normal narrow rectangle at rest, with a
/// sharp, punchy easing derived from [pulseT].
///
/// Left glyph's stem spans roughly `x 160-176, y 172-234`, its dot around
/// `x 160-176, y 240-256`; the right glyph mirrors it around `x 217-234`
/// (stem) with its dot around `x 217-234, y 240-256`, both ported verbatim
/// from `emo-warning.svg`. The stem's funnel silhouette at rest exactly
/// reproduces that same rounded-rect outline (see [_stemPath] at
/// `topWiden == 0`); only [pulseT] moving away from `0` changes its shape.
///
/// [canvas] is the target being painted onto. [k] is the uniform scale
/// factor mapping the SVG source's `396.15`-wide coordinate space onto the
/// painted [Size]. [accentColor] fills every glyph piece. [pulseT] is the
/// idle attention-pulse phase in `0..1`; `0` (or a value between bursts)
/// renders each stem at its exact original, unwidened geometry.
/// [paintSmoothed] is `LayoPainter`'s shared fill+stroke antialiasing
/// helper, threaded through so this free function does not need a
/// `LayoPainter` instance of its own.
void paintAlertGlyphs(
  Canvas canvas,
  double k, {
  required Color accentColor,
  required double pulseT,
  required void Function(Canvas canvas, Color color, double k, void Function(Paint paint) shapeOnto) paintSmoothed,
}) {
  // A sharp, snappy easeOutBack curve: 0 at t == 0 (at rest, unwidened),
  // overshoots past 1.0 partway through, then settles back to 1.0 at
  // t == 1 -- giving the punchy "snap" the maintainer asked for, distinct
  // from question's gentle sine wiggle.
  final t = pulseT.clamp(0.0, 1.0);
  const c1 = 1.70158;
  const c3 = c1 + 1;
  final eased = 1 + c3 * (t - 1) * (t - 1) * (t - 1) + c1 * (t - 1) * (t - 1);
  final envelope = eased.clamp(0.0, 1.3);
  final topWiden = _kTopWidenPeak * envelope;

  _paintBang(
    canvas,
    k,
    accentColor: accentColor,
    topWiden: topWiden,
    stemCenterX: 168.0,
    stemTop: 171.570312,
    stemBottom: 233.957031,
    dot: _leftDot(k),
    paintSmoothed: paintSmoothed,
  );
  _paintBang(
    canvas,
    k,
    accentColor: accentColor,
    topWiden: topWiden,
    stemCenterX: 225.625,
    stemTop: 171.937500,
    stemBottom: 234.324219,
    dot: _rightDot(k),
    paintSmoothed: paintSmoothed,
  );
}

/// Paints a single "!" glyph: the dot at its fixed resting geometry, and the
/// stem via [_stemPath] widened at the top by [topWiden].
void _paintBang(
  Canvas canvas,
  double k, {
  required Color accentColor,
  required double topWiden,
  required double stemCenterX,
  required double stemTop,
  required double stemBottom,
  required Path dot,
  required void Function(Canvas canvas, Color color, double k, void Function(Paint paint) shapeOnto) paintSmoothed,
}) {
  final stem = _stemPath(
    k,
    centerX: stemCenterX,
    top: stemTop,
    bottom: stemBottom,
    topWiden: topWiden,
  );
  paintSmoothed(canvas, accentColor, k, (paint) => canvas.drawPath(stem, paint));
  paintSmoothed(canvas, accentColor, k, (paint) => canvas.drawPath(dot, paint));
}

/// Builds one stem's funnel silhouette: a flat top edge widened outward by
/// [topWiden] on each side (forming an inverted-triangle/funnel at
/// `topWiden > 0`), tapering via straight diagonal flanks down to the
/// stem's normal narrow width at the bottom, with the same rounded corners
/// (radius [_kCornerRadius]) at both the top and bottom ends regardless of
/// [topWiden].
///
/// At `topWiden == 0` this reproduces the original stem's own rounded-rect
/// silhouette exactly (the top and bottom edges both at
/// [_kStemHalfWidth] from [centerX]), so a default-constructed (unanimated)
/// painter still renders the source artwork's stem unchanged.
Path _stemPath(
  double k, {
  required double centerX,
  required double top,
  required double bottom,
  required double topWiden,
}) {
  final halfTop = (_kStemHalfWidth + topWiden).clamp(_kCornerRadius, double.infinity);
  const halfBottom = _kStemHalfWidth;
  final r = _kCornerRadius;

  final left = centerX - halfTop;
  final right = centerX + halfTop;
  final bottomLeft = centerX - halfBottom;
  final bottomRight = centerX + halfBottom;

  return Path()
    // Top-left rounded corner, then flat top edge, then top-right rounded
    // corner.
    ..moveTo((left + r) * k, top * k)
    ..lineTo((right - r) * k, top * k)
    ..quadraticBezierTo(right * k, top * k, right * k, (top + r) * k)
    // Right flank: a straight taper down to the bottom's narrow width.
    ..lineTo(bottomRight * k, (bottom - r) * k)
    ..quadraticBezierTo(bottomRight * k, bottom * k, (bottomRight - r) * k, bottom * k)
    // Flat bottom edge.
    ..lineTo((bottomLeft + r) * k, bottom * k)
    ..quadraticBezierTo(bottomLeft * k, bottom * k, bottomLeft * k, (bottom - r) * k)
    // Left flank: a straight taper back up to the (possibly widened) top.
    ..lineTo(left * k, (top + r) * k)
    ..quadraticBezierTo(left * k, top * k, (left + r) * k, top * k)
    ..close();
}

/// The left "!" glyph's dot, ported verbatim from `emo-warning.svg`.
Path _leftDot(double k) {
  return Path()
    ..moveTo(168.039062 * k, 239.953125 * k)
    ..cubicTo(172.507812 * k, 239.953125 * k, 176.132812 * k, 243.578125 * k, 176.132812 * k, 248.046875 * k)
    ..cubicTo(176.132812 * k, 252.515625 * k, 172.507812 * k, 256.136719 * k, 168.039062 * k, 256.136719 * k)
    ..cubicTo(163.570312 * k, 256.136719 * k, 159.945312 * k, 252.515625 * k, 159.945312 * k, 248.046875 * k)
    ..cubicTo(159.945312 * k, 243.578125 * k, 163.570312 * k, 239.953125 * k, 168.039062 * k, 239.953125 * k)
    ..close();
}

/// The right "!" glyph's dot, ported verbatim from `emo-warning.svg`.
Path _rightDot(double k) {
  return Path()
    ..moveTo(225.617188 * k, 240.312500 * k)
    ..cubicTo(230.085938 * k, 240.312500 * k, 233.707031 * k, 243.933594 * k, 233.707031 * k, 248.406250 * k)
    ..cubicTo(233.707031 * k, 252.875000 * k, 230.085938 * k, 256.496094 * k, 225.617188 * k, 256.496094 * k)
    ..cubicTo(221.144531 * k, 256.496094 * k, 217.523438 * k, 252.875000 * k, 217.523438 * k, 248.406250 * k)
    ..cubicTo(217.523438 * k, 243.933594 * k, 221.144531 * k, 240.312500 * k, 225.617188 * k, 240.312500 * k)
    ..close();
}
