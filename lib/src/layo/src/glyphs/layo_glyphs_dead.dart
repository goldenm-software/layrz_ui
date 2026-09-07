/// [LayoEmotion.dead]-only glyphs: two grey "X" marks standing in for this
/// emotion's eyes. No mouth is drawn for [LayoEmotion.dead].
///
/// Every shape here is a verbatim port of the artist's own vector paths from
/// `dead.svg` (same `396.15`-wide source space as the mascot's other
/// emotions), scaled uniformly by the same `k` factor `LayoPainter` derives
/// from the painted [Size].
library;

import 'package:flutter/widgets.dart';

/// Paints the two "X" marks — left spanning roughly `x 126-178`, right
/// spanning `x 220-271`, both `y 189-241` — that serve as [LayoEmotion.dead]'s
/// eyes. Each "X" is two crossed diagonal strokes (four shapes total), ported
/// verbatim from `dead.svg`.
///
/// [canvas] is the target being painted onto. [k] is the uniform scale
/// factor mapping the SVG source's `396.15`-wide coordinate space onto the
/// painted [Size]. [glyphColor] fills every stroke. [paintSmoothed] is
/// `LayoPainter`'s shared fill+stroke antialiasing helper, threaded through
/// so this free function does not need a `LayoPainter` instance of its own.
void paintDeadEyes(
  Canvas canvas,
  double k, {
  required Color glyphColor,
  required void Function(Canvas canvas, Color color, double k, void Function(Paint paint) shapeOnto) paintSmoothed,
}) {
  final leftStrokeA = Path()
    ..moveTo(133.464844 * k, 189.148438 * k)
    ..lineTo(177.417969 * k, 233.101562 * k)
    ..cubicTo(177.855469 * k, 233.539062 * k, 177.855469 * k, 234.246094 * k, 177.417969 * k, 234.683594 * k)
    ..lineTo(172.089844 * k, 240.007812 * k)
    ..cubicTo(171.652344 * k, 240.445312 * k, 170.945312 * k, 240.445312 * k, 170.507812 * k, 240.007812 * k)
    ..lineTo(126.558594 * k, 196.058594 * k)
    ..cubicTo(126.121094 * k, 195.621094 * k, 126.121094 * k, 194.914062 * k, 126.558594 * k, 194.476562 * k)
    ..lineTo(131.886719 * k, 189.148438 * k)
    ..cubicTo(132.320312 * k, 188.714844 * k, 133.03125 * k, 188.714844 * k, 133.464844 * k, 189.148438 * k)
    ..close();
  paintSmoothed(canvas, glyphColor, k, (paint) => canvas.drawPath(leftStrokeA, paint));

  final leftStrokeB = Path()
    ..moveTo(126.527344 * k, 233.125 * k)
    ..lineTo(170.550781 * k, 189.105469 * k)
    ..cubicTo(170.96875 * k, 188.6875 * k, 171.644531 * k, 188.6875 * k, 172.058594 * k, 189.105469 * k)
    ..lineTo(177.457031 * k, 194.503906 * k)
    ..cubicTo(177.875 * k, 194.917969 * k, 177.875 * k, 195.597656 * k, 177.457031 * k, 196.011719 * k)
    ..lineTo(133.4375 * k, 240.035156 * k)
    ..cubicTo(133.019531 * k, 240.453125 * k, 132.34375 * k, 240.453125 * k, 131.925781 * k, 240.035156 * k)
    ..lineTo(126.527344 * k, 234.636719 * k)
    ..cubicTo(126.113281 * k, 234.21875 * k, 126.113281 * k, 233.542969 * k, 126.527344 * k, 233.125 * k)
    ..close();
  paintSmoothed(canvas, glyphColor, k, (paint) => canvas.drawPath(leftStrokeB, paint));

  final rightStrokeA = Path()
    ..moveTo(226.953125 * k, 189.628906 * k)
    ..lineTo(270.90625 * k, 233.578125 * k)
    ..cubicTo(271.34375 * k, 234.015625 * k, 271.34375 * k, 234.722656 * k, 270.90625 * k, 235.160156 * k)
    ..lineTo(265.578125 * k, 240.488281 * k)
    ..cubicTo(265.140625 * k, 240.921875 * k, 264.433594 * k, 240.921875 * k, 263.996094 * k, 240.488281 * k)
    ..lineTo(220.046875 * k, 196.535156 * k)
    ..cubicTo(219.609375 * k, 196.097656 * k, 219.609375 * k, 195.390625 * k, 220.046875 * k, 194.953125 * k)
    ..lineTo(225.375 * k, 189.628906 * k)
    ..cubicTo(225.8125 * k, 189.191406 * k, 226.519531 * k, 189.191406 * k, 226.953125 * k, 189.628906 * k)
    ..close();
  paintSmoothed(canvas, glyphColor, k, (paint) => canvas.drawPath(rightStrokeA, paint));

  final rightStrokeB = Path()
    ..moveTo(220.015625 * k, 233.605469 * k)
    ..lineTo(264.039062 * k, 189.582031 * k)
    ..cubicTo(264.453125 * k, 189.167969 * k, 265.132812 * k, 189.167969 * k, 265.546875 * k, 189.582031 * k)
    ..lineTo(270.945312 * k, 194.980469 * k)
    ..cubicTo(271.363281 * k, 195.398438 * k, 271.363281 * k, 196.074219 * k, 270.945312 * k, 196.492188 * k)
    ..lineTo(226.925781 * k, 240.511719 * k)
    ..cubicTo(226.507812 * k, 240.929688 * k, 225.832031 * k, 240.929688 * k, 225.414062 * k, 240.511719 * k)
    ..lineTo(220.015625 * k, 235.117188 * k)
    ..cubicTo(219.597656 * k, 234.699219 * k, 219.597656 * k, 234.023438 * k, 220.015625 * k, 233.605469 * k)
    ..close();
  paintSmoothed(canvas, glyphColor, k, (paint) => canvas.drawPath(rightStrokeB, paint));
}
