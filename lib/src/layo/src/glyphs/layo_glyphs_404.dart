/// [LayoEmotion.layo404]-only glyphs: the digits "404" plus an underline
/// bar.
///
/// Every shape here is a verbatim port of the artist's own vector paths from
/// `emo-404.svg` (same `396.15`-wide source space as the mascot's other
/// emotions), scaled uniformly by the same `k` factor `LayoPainter` derives
/// from the painted [Size]. All glyphs paint in grey (the emotion's shared
/// [glyphColor]), matching [LayoEmotion.sleep] and [LayoEmotion.dead].
library;

import 'package:flutter/widgets.dart';

/// Paints the "404" digit glyphs and their underline bar for
/// [LayoEmotion.layo404], applying [glitchOpacity] uniformly to the whole
/// group and a small horizontal [glitchOffset] (in source units, pre-[k]
/// scale) so the group can flicker/jitter as one broken display.
///
/// Digit paths span roughly `x 114-281, y 174-249`; the underline bar spans
/// `x 198-258, y 263-268`. All four shapes are ported verbatim from
/// `emo-404.svg`.
///
/// [canvas] is the target being painted onto. [k] is the uniform scale
/// factor mapping the SVG source's `396.15`-wide coordinate space onto the
/// painted [Size]. [glyphColor] fills every shape, modulated by
/// [glitchOpacity]. [glitchOpacity] is `1.0` at rest (fully opaque, static);
/// a brief flicker burst drops it toward a low value for a few frames.
/// [glitchOffset] is a small horizontal jitter, in source units, `0.0` at
/// rest. [paintSmoothed] is `LayoPainter`'s shared fill+stroke antialiasing
/// helper, threaded through so this free function does not need a
/// `LayoPainter` instance of its own.
void paint404Glyphs(
  Canvas canvas,
  double k, {
  required Color glyphColor,
  required double glitchOpacity,
  required double glitchOffset,
  required void Function(Canvas canvas, Color color, double k, void Function(Paint paint) shapeOnto) paintSmoothed,
}) {
  final color = glyphColor.withValues(alpha: glitchOpacity.clamp(0.0, 1.0));

  canvas.save();
  canvas.translate(glitchOffset * k, 0);

  paintSmoothed(canvas, color, k, (paint) => canvas.drawPath(_firstFour(k), paint));
  paintSmoothed(canvas, color, k, (paint) => canvas.drawPath(_zero(k), paint));
  paintSmoothed(canvas, color, k, (paint) => canvas.drawPath(_secondFour(k), paint));
  paintSmoothed(canvas, color, k, (paint) => canvas.drawPath(_underline(k), paint));

  canvas.restore();
}

/// The first "4" digit, ported verbatim from `emo-404.svg`.
Path _firstFour(double k) {
  return Path()
    ..moveTo(146.218750 * k, 220.425781 * k)
    ..lineTo(126.527344 * k, 220.425781 * k)
    ..cubicTo(125.402344 * k, 220.425781 * k, 124.738281 * k, 219.167969 * k, 125.367188 * k, 218.238281 * k)
    ..lineTo(145.273438 * k, 188.839844 * k)
    ..cubicTo(145.273438 * k, 188.839844 * k, 145.917969 * k, 187.656250 * k, 147.101562 * k, 188.121094 * k)
    ..cubicTo(147.621094 * k, 188.382812 * k, 147.617188 * k, 189.343750 * k, 147.617188 * k, 189.640625 * k)
    ..cubicTo(147.667969 * k, 195.488281 * k, 147.617188 * k, 220.398438 * k, 147.617188 * k, 220.398438 * k)
    ..close()
    ..moveTo(156.843750 * k, 228.082031 * k)
    ..lineTo(164.003906 * k, 228.082031 * k)
    ..cubicTo(165.648438 * k, 228.082031 * k, 166.980469 * k, 226.750000 * k, 166.980469 * k, 225.109375 * k)
    ..lineTo(166.980469 * k, 223.375000 * k)
    ..cubicTo(166.980469 * k, 221.730469 * k, 165.648438 * k, 220.398438 * k, 164.003906 * k, 220.398438 * k)
    ..lineTo(156.843750 * k, 220.398438 * k)
    ..lineTo(156.843750 * k, 178.371094 * k)
    ..cubicTo(156.843750 * k, 176.726562 * k, 155.511719 * k, 175.394531 * k, 153.871094 * k, 175.394531 * k)
    ..lineTo(147.816406 * k, 175.394531 * k)
    ..cubicTo(146.839844 * k, 175.394531 * k, 145.929688 * k, 175.871094 * k, 145.375000 * k, 176.667969 * k)
    ..lineTo(114.496094 * k, 220.855469 * k)
    ..cubicTo(114.148438 * k, 221.355469 * k, 113.960938 * k, 221.949219 * k, 113.960938 * k, 222.558594 * k)
    ..lineTo(113.960938 * k, 225.109375 * k)
    ..cubicTo(113.960938 * k, 226.750000 * k, 115.292969 * k, 228.082031 * k, 116.937500 * k, 228.082031 * k)
    ..lineTo(147.601562 * k, 228.082031 * k)
    ..lineTo(147.601562 * k, 244.824219 * k)
    ..cubicTo(147.601562 * k, 246.468750 * k, 148.933594 * k, 247.800781 * k, 150.574219 * k, 247.800781 * k)
    ..lineTo(153.871094 * k, 247.800781 * k)
    ..cubicTo(155.511719 * k, 247.800781 * k, 156.843750 * k, 246.468750 * k, 156.843750 * k, 244.824219 * k)
    ..close();
}

/// The "0" digit, ported verbatim from `emo-404.svg`.
Path _zero(double k) {
  return Path()
    ..moveTo(183.238281 * k, 211.933594 * k)
    ..cubicTo(183.238281 * k, 230.757812 * k, 189.031250 * k, 241.449219 * k, 197.941406 * k, 241.449219 * k)
    ..cubicTo(207.968750 * k, 241.449219 * k, 212.757812 * k, 229.753906 * k, 212.757812 * k, 211.265625 * k)
    ..cubicTo(212.757812 * k, 193.441406 * k, 208.191406 * k, 181.746094 * k, 198.050781 * k, 181.746094 * k)
    ..cubicTo(189.476562 * k, 181.746094 * k, 183.238281 * k, 192.214844 * k, 183.238281 * k, 211.933594 * k)
    ..close()
    ..moveTo(222.558594 * k, 210.816406 * k)
    ..cubicTo(222.558594 * k, 235.437500 * k, 213.421875 * k, 249.027344 * k, 197.382812 * k, 249.027344 * k)
    ..cubicTo(183.238281 * k, 249.027344 * k, 173.660156 * k, 235.769531 * k, 173.433594 * k, 211.824219 * k)
    ..cubicTo(173.433594 * k, 187.535156 * k, 183.906250 * k, 174.171875 * k, 198.609375 * k, 174.171875 * k)
    ..cubicTo(213.871094 * k, 174.171875 * k, 222.558594 * k, 187.761719 * k, 222.558594 * k, 210.816406 * k)
    ..close();
}

/// The second "4" digit, ported verbatim from `emo-404.svg`.
Path _secondFour(double k) {
  return Path()
    ..moveTo(260.492188 * k, 220.425781 * k)
    ..lineTo(240.800781 * k, 220.425781 * k)
    ..cubicTo(239.675781 * k, 220.425781 * k, 239.011719 * k, 219.167969 * k, 239.640625 * k, 218.238281 * k)
    ..lineTo(259.546875 * k, 188.839844 * k)
    ..cubicTo(259.546875 * k, 188.839844 * k, 260.191406 * k, 187.656250 * k, 261.378906 * k, 188.121094 * k)
    ..cubicTo(261.894531 * k, 188.382812 * k, 261.890625 * k, 189.343750 * k, 261.890625 * k, 189.640625 * k)
    ..cubicTo(261.941406 * k, 195.488281 * k, 261.890625 * k, 220.398438 * k, 261.890625 * k, 220.398438 * k)
    ..close()
    ..moveTo(271.117188 * k, 228.082031 * k)
    ..lineTo(278.281250 * k, 228.082031 * k)
    ..cubicTo(279.921875 * k, 228.082031 * k, 281.253906 * k, 226.750000 * k, 281.253906 * k, 225.109375 * k)
    ..lineTo(281.253906 * k, 223.375000 * k)
    ..cubicTo(281.253906 * k, 221.730469 * k, 279.921875 * k, 220.398438 * k, 278.281250 * k, 220.398438 * k)
    ..lineTo(271.117188 * k, 220.398438 * k)
    ..lineTo(271.117188 * k, 178.371094 * k)
    ..cubicTo(271.117188 * k, 176.726562 * k, 269.785156 * k, 175.394531 * k, 268.144531 * k, 175.394531 * k)
    ..lineTo(262.089844 * k, 175.394531 * k)
    ..cubicTo(261.117188 * k, 175.394531 * k, 260.207031 * k, 175.871094 * k, 259.648438 * k, 176.667969 * k)
    ..lineTo(228.769531 * k, 220.855469 * k)
    ..cubicTo(228.421875 * k, 221.355469 * k, 228.234375 * k, 221.949219 * k, 228.234375 * k, 222.558594 * k)
    ..lineTo(228.234375 * k, 225.109375 * k)
    ..cubicTo(228.234375 * k, 226.750000 * k, 229.566406 * k, 228.082031 * k, 231.210938 * k, 228.082031 * k)
    ..lineTo(261.875000 * k, 228.082031 * k)
    ..lineTo(261.875000 * k, 244.824219 * k)
    ..cubicTo(261.875000 * k, 246.468750 * k, 263.207031 * k, 247.800781 * k, 264.847656 * k, 247.800781 * k)
    ..lineTo(268.144531 * k, 247.800781 * k)
    ..cubicTo(269.785156 * k, 247.800781 * k, 271.117188 * k, 246.468750 * k, 271.117188 * k, 244.824219 * k)
    ..close();
}

/// The underline bar beneath "404", ported verbatim from `emo-404.svg`.
Path _underline(double k) {
  return Path()
    ..moveTo(255.675781 * k, 267.613281 * k)
    ..lineTo(200.792969 * k, 267.613281 * k)
    ..cubicTo(199.421875 * k, 267.613281 * k, 198.296875 * k, 266.492188 * k, 198.296875 * k, 265.121094 * k)
    ..cubicTo(198.296875 * k, 263.750000 * k, 199.421875 * k, 262.625000 * k, 200.792969 * k, 262.625000 * k)
    ..lineTo(255.675781 * k, 262.625000 * k)
    ..cubicTo(257.046875 * k, 262.625000 * k, 258.167969 * k, 263.750000 * k, 258.167969 * k, 265.121094 * k)
    ..cubicTo(258.167969 * k, 266.492188 * k, 257.046875 * k, 267.613281 * k, 255.675781 * k, 267.613281 * k)
    ..close();
}
