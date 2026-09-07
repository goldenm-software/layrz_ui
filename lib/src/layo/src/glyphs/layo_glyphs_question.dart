/// [LayoEmotion.question]-only glyphs: two question-mark stems and their
/// dots, standing in for this emotion's eyes. No mouth is drawn for
/// [LayoEmotion.question].
///
/// Every shape here is a verbatim port of the artist's own vector paths from
/// `question.svg` (same `396.15`-wide source space as the mascot's other
/// emotions), scaled uniformly by the same `k` factor `LayoPainter` derives
/// from the painted [Size].
library;

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// The maximum rotation each "?" glyph sways through as [wiggleT] sweeps
/// `0..1`, in radians -- roughly 5 degrees, a small, gentle sway rather than
/// a frantic shake.
const double _kWiggleAngle = 0.09;

/// The phase offset (as a fraction of a full `0..1` cycle) applied to the
/// right glyph's wiggle relative to the left, so the two "?" do not swing in
/// perfect lockstep.
const double _kWigglePhaseOffset = 0.15;

/// Paints the two blue "?" glyphs (a curved stem plus a dot beneath it, each)
/// that serve as [LayoEmotion.question]'s eyes, gently wiggling with
/// [wiggleT].
///
/// Left glyph spans roughly `x 153-191` (stem) with its dot around
/// `x 160-176, y 240-256`; the right glyph mirrors it around
/// `x 211-248` (stem) with its dot around `x 217-234`. Both glyph shapes,
/// including the small ellipsis-cusp curls partway down each stem, are
/// ported verbatim from `question.svg` — none are re-derived as a simplified
/// question-mark glyph.
///
/// Each glyph (stem + dot together) rotates as a single rigid unit around its
/// own approximate center -- the midpoint of its combined stem+dot bounding
/// box, `(172, 213.5) * k` for the left glyph and `(229.5, 213.5) * k` for
/// the right -- by a small sine-eased angle derived from [wiggleT], with
/// the right glyph's phase offset slightly from the left's (see
/// [_kWigglePhaseOffset]) so the pair reads as a loose, organic sway rather
/// than a single rigid shake. At `wiggleT == 0` both glyphs render at their
/// exact original, unrotated positions. This wiggle stands in for this
/// emotion's eye-blink -- its "eyes" are the question marks themselves, so
/// [LayoPainter._isBlinkable] excludes [LayoEmotion.question] and this
/// animation plays instead.
///
/// [canvas] is the target being painted onto. [k] is the uniform scale
/// factor mapping the SVG source's `396.15`-wide coordinate space onto the
/// painted [Size]. [accentColor] fills every glyph piece. [wiggleT] is the
/// idle wiggle phase in `0..1`, looping. [paintSmoothed] is `LayoPainter`'s
/// shared fill+stroke antialiasing helper, threaded through so this free
/// function does not need a `LayoPainter` instance of its own.
void paintQuestionEyes(
  Canvas canvas,
  double k, {
  required Color accentColor,
  required double wiggleT,
  required void Function(Canvas canvas, Color color, double k, void Function(Paint paint) shapeOnto) paintSmoothed,
}) {
  final leftAngle = _kWiggleAngle * math.sin(wiggleT.clamp(0.0, 1.0) * 2 * math.pi);
  final rightAngle = _kWiggleAngle * math.sin((wiggleT.clamp(0.0, 1.0) + _kWigglePhaseOffset) * 2 * math.pi);

  canvas.save();
  canvas.translate(172 * k, 213.5 * k);
  canvas.rotate(leftAngle);
  canvas.translate(-172 * k, -213.5 * k);
  _paintQuestionGlyph(canvas, k, accentColor: accentColor, paintSmoothed: paintSmoothed, isLeft: true);
  canvas.restore();

  canvas.save();
  canvas.translate(229.5 * k, 213.5 * k);
  canvas.rotate(rightAngle);
  canvas.translate(-229.5 * k, -213.5 * k);
  _paintQuestionGlyph(canvas, k, accentColor: accentColor, paintSmoothed: paintSmoothed, isLeft: false);
  canvas.restore();
}

/// Paints a single "?" glyph (stem + dot), [isLeft] selecting which of the
/// two source paths to draw. Split out of [paintQuestionEyes] so the wiggle
/// rotation in that function can wrap each glyph's own `save`/`rotate`/
/// `restore` around exactly one glyph's paint calls.
void _paintQuestionGlyph(
  Canvas canvas,
  double k, {
  required Color accentColor,
  required void Function(Canvas canvas, Color color, double k, void Function(Paint paint) shapeOnto) paintSmoothed,
  required bool isLeft,
}) {
  if (isLeft) {
    _paintLeftQuestionGlyph(canvas, k, accentColor: accentColor, paintSmoothed: paintSmoothed);
  } else {
    _paintRightQuestionGlyph(canvas, k, accentColor: accentColor, paintSmoothed: paintSmoothed);
  }
}

/// Paints the left "?" glyph's dot and stem. Ported verbatim from
/// `question.svg`.
void _paintLeftQuestionGlyph(
  Canvas canvas,
  double k, {
  required Color accentColor,
  required void Function(Canvas canvas, Color color, double k, void Function(Paint paint) shapeOnto) paintSmoothed,
}) {
  final leftDot = Path()
    ..moveTo(167.984375 * k, 239.953125 * k)
    ..cubicTo(172.453125 * k, 239.953125 * k, 176.078125 * k, 243.574219 * k, 176.078125 * k, 248.046875 * k)
    ..cubicTo(176.078125 * k, 252.515625 * k, 172.453125 * k, 256.136719 * k, 167.984375 * k, 256.136719 * k)
    ..cubicTo(163.515625 * k, 256.136719 * k, 159.890625 * k, 252.515625 * k, 159.890625 * k, 248.046875 * k)
    ..cubicTo(159.890625 * k, 243.574219 * k, 163.515625 * k, 239.953125 * k, 167.984375 * k, 239.953125 * k)
    ..close();
  paintSmoothed(canvas, accentColor, k, (paint) => canvas.drawPath(leftDot, paint));

  final leftStem = Path()
    ..moveTo(165.820312 * k, 234.324219 * k)
    ..cubicTo(164.296875 * k, 234.246094 * k, 163.125 * k, 232.953125 * k, 163.195312 * k, 231.429688 * k)
    ..cubicTo(163.140625 * k, 228.449219 * k, 163.5625 * k, 225.476562 * k, 164.453125 * k, 222.628906 * k)
    ..cubicTo(165.238281 * k, 220.238281 * k, 166.324219 * k, 217.953125 * k, 167.683594 * k, 215.835938 * k)
    ..cubicTo(168.992188 * k, 213.839844 * k, 170.367188 * k, 211.84375 * k, 171.804688 * k, 209.847656 * k)
    ..cubicTo(173.769531 * k, 207.238281 * k, 175.59375 * k, 204.523438 * k, 177.265625 * k, 201.714844 * k)
    ..cubicTo(178.652344 * k, 199.171875 * k, 179.34375 * k, 196.300781 * k, 179.257812 * k, 193.402344 * k)
    ..cubicTo(179.355469 * k, 191.035156 * k, 178.761719 * k, 188.691406 * k, 177.554688 * k, 186.65625 * k)
    ..cubicTo(176.492188 * k, 184.976562 * k, 174.980469 * k, 183.625 * k, 173.191406 * k, 182.753906 * k)
    ..cubicTo(171.484375 * k, 181.917969 * k, 169.605469 * k, 181.480469 * k, 167.703125 * k, 181.480469 * k)
    ..cubicTo(165.226562 * k, 181.453125 * k, 162.765625 * k, 181.875 * k, 160.441406 * k, 182.726562 * k)
    ..cubicTo(159.394531 * k, 183.109375 * k, 158.371094 * k, 183.554688 * k, 157.375 * k, 184.054688 * k)
    ..cubicTo(156.046875 * k, 184.617188 * k, 154.511719 * k, 183.992188 * k, 153.949219 * k, 182.664062 * k)
    ..cubicTo(153.820312 * k, 182.359375 * k, 153.753906 * k, 182.035156 * k, 153.746094 * k, 181.707031 * k)
    ..lineTo(153.40625 * k, 178.375 * k)
    ..cubicTo(153.269531 * k, 177.21875 * k, 153.820312 * k, 176.089844 * k, 154.8125 * k, 175.480469 * k)
    ..cubicTo(159.4375 * k, 172.738281 * k, 164.742188 * k, 171.355469 * k, 170.121094 * k, 171.488281 * k)
    ..cubicTo(173.996094 * k, 171.355469 * k, 177.828125 * k, 172.355469 * k, 181.144531 * k, 174.363281 * k)
    ..cubicTo(184.054688 * k, 176.191406 * k, 186.390625 * k, 178.796875 * k, 187.890625 * k, 181.886719 * k)
    ..cubicTo(190.558594 * k, 187.558594 * k, 190.917969 * k, 194.046875 * k, 188.890625 * k, 199.980469 * k)
    ..cubicTo(188.035156 * k, 202.25 * k, 186.902344 * k, 204.410156 * k, 185.527344 * k, 206.40625 * k)
    ..cubicTo(184.15625 * k, 208.402344 * k, 182.738281 * k, 210.394531 * k, 181.273438 * k, 212.390625 * k)
    ..cubicTo(179.246094 * k, 215.101562 * k, 177.355469 * k, 217.914062 * k, 175.609375 * k, 220.8125 * k)
    ..cubicTo(173.871094 * k, 223.8125 * k, 173 * k, 227.230469 * k, 173.082031 * k, 230.691406 * k)
    ..lineTo(173.082031 * k, 231.382812 * k)
    ..cubicTo(173.152344 * k, 232.902344 * k, 171.980469 * k, 234.195312 * k, 170.457031 * k, 234.273438 * k)
    ..close();
  paintSmoothed(canvas, accentColor, k, (paint) => canvas.drawPath(leftStem, paint));
}

/// Paints the right "?" glyph's dot and stem. Ported verbatim from
/// `question.svg`.
void _paintRightQuestionGlyph(
  Canvas canvas,
  double k, {
  required Color accentColor,
  required void Function(Canvas canvas, Color color, double k, void Function(Paint paint) shapeOnto) paintSmoothed,
}) {
  final rightDot = Path()
    ..moveTo(225.558594 * k, 240.3125 * k)
    ..cubicTo(230.03125 * k, 240.3125 * k, 233.652344 * k, 243.933594 * k, 233.652344 * k, 248.40625 * k)
    ..cubicTo(233.652344 * k, 252.875 * k, 230.03125 * k, 256.496094 * k, 225.558594 * k, 256.496094 * k)
    ..cubicTo(221.089844 * k, 256.496094 * k, 217.46875 * k, 252.875 * k, 217.46875 * k, 248.40625 * k)
    ..cubicTo(217.46875 * k, 243.933594 * k, 221.089844 * k, 240.3125 * k, 225.558594 * k, 240.3125 * k)
    ..close();
  paintSmoothed(canvas, accentColor, k, (paint) => canvas.drawPath(rightDot, paint));

  final rightStem = Path()
    ..moveTo(223.164062 * k, 234.324219 * k)
    ..cubicTo(221.644531 * k, 234.246094 * k, 220.472656 * k, 232.953125 * k, 220.539062 * k, 231.429688 * k)
    ..cubicTo(220.484375 * k, 228.449219 * k, 220.910156 * k, 225.476562 * k, 221.796875 * k, 222.628906 * k)
    ..cubicTo(222.582031 * k, 220.238281 * k, 223.667969 * k, 217.953125 * k, 225.03125 * k, 215.835938 * k)
    ..cubicTo(226.339844 * k, 213.839844 * k, 227.714844 * k, 211.84375 * k, 229.152344 * k, 209.847656 * k)
    ..cubicTo(231.113281 * k, 207.234375 * k, 232.9375 * k, 204.519531 * k, 234.609375 * k, 201.714844 * k)
    ..cubicTo(236 * k, 199.171875 * k, 236.691406 * k, 196.300781 * k, 236.605469 * k, 193.402344 * k)
    ..cubicTo(236.703125 * k, 191.035156 * k, 236.109375 * k, 188.691406 * k, 234.902344 * k, 186.65625 * k)
    ..cubicTo(233.835938 * k, 184.976562 * k, 232.328125 * k, 183.625 * k, 230.539062 * k, 182.753906 * k)
    ..cubicTo(228.832031 * k, 181.917969 * k, 226.953125 * k, 181.480469 * k, 225.050781 * k, 181.480469 * k)
    ..cubicTo(222.574219 * k, 181.453125 * k, 220.113281 * k, 181.875 * k, 217.785156 * k, 182.726562 * k)
    ..cubicTo(216.742188 * k, 183.109375 * k, 215.71875 * k, 183.550781 * k, 214.722656 * k, 184.054688 * k)
    ..cubicTo(213.394531 * k, 184.617188 * k, 211.859375 * k, 183.992188 * k, 211.296875 * k, 182.664062 * k)
    ..cubicTo(211.167969 * k, 182.359375 * k, 211.097656 * k, 182.035156 * k, 211.089844 * k, 181.707031 * k)
    ..lineTo(210.753906 * k, 178.375 * k)
    ..cubicTo(210.617188 * k, 177.21875 * k, 211.160156 * k, 176.09375 * k, 212.148438 * k, 175.480469 * k)
    ..cubicTo(216.78125 * k, 172.742188 * k, 222.085938 * k, 171.355469 * k, 227.464844 * k, 171.488281 * k)
    ..cubicTo(231.34375 * k, 171.355469 * k, 235.175781 * k, 172.355469 * k, 238.492188 * k, 174.363281 * k)
    ..cubicTo(241.398438 * k, 176.195312 * k, 243.734375 * k, 178.800781 * k, 245.238281 * k, 181.886719 * k)
    ..cubicTo(247.914062 * k, 187.558594 * k, 248.273438 * k, 194.046875 * k, 246.234375 * k, 199.980469 * k)
    ..cubicTo(245.390625 * k, 202.25 * k, 244.261719 * k, 204.410156 * k, 242.882812 * k, 206.40625 * k)
    ..cubicTo(241.511719 * k, 208.402344 * k, 240.09375 * k, 210.394531 * k, 238.632812 * k, 212.390625 * k)
    ..cubicTo(236.53125 * k, 215.214844 * k, 234.636719 * k, 218.019531 * k, 232.953125 * k, 220.8125 * k)
    ..cubicTo(231.226562 * k, 223.816406 * k, 230.355469 * k, 227.230469 * k, 230.441406 * k, 230.691406 * k)
    ..lineTo(230.441406 * k, 231.382812 * k)
    ..cubicTo(230.507812 * k, 232.902344 * k, 229.335938 * k, 234.195312 * k, 227.816406 * k, 234.273438 * k)
    ..close();
  paintSmoothed(canvas, accentColor, k, (paint) => canvas.drawPath(rightStem, paint));
}
