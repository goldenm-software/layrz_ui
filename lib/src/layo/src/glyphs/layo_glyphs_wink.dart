/// [LayoEmotion.wink]-only glyph: the same two blue eyes as [LayoEmotion.mrLayo],
/// but the **right** eye alone periodically winks shut while the left stays
/// open — unlike [LayoEmotion.comandante] (whose wink pairs with a beret
/// overlay and no tie at all), this emotion wears the ordinary tie and
/// antenna every ordinary [LayoEmotion] wears. The mouth reuses
/// [LayoEmotion.mrLayo]'s own smile unmodified.
///
/// [LayoEmotion.wink] is a from-scratch invention with no `.ai`/SVG source of
/// its own to trace, but its eyes are geometrically identical to
/// [LayoEmotion.mrLayo]'s own (and to [LayoEmotion.comandante]'s own
/// right-eye wink technique) — the same `396.15`-wide coordinate space, the
/// same eye-row coordinates, and the same squash-toward-ellipse wink
/// mechanism.
library;

import 'package:flutter/widgets.dart';

/// Paints [LayoEmotion.wink]'s eyes: two open blue circles at rest, with
/// [winkT] squashing the **right** eye alone toward a thin ellipse and
/// back — the same one-eye wink technique
/// [LayoEmotion.comandante]'s own `paintComandanteEyes` uses, reused here at
/// [LayoEmotion.mrLayo]'s own exact eye-row coordinates.
///
/// [canvas] is the target being painted onto. [k] is the uniform scale
/// factor mapping the SVG source's `396.15`-wide coordinate space onto the
/// painted [Size]. [accentColor] fills both eyes. [winkT] is the right eye's
/// wink phase in `0..1`, `0` fully open and `1` fully closed. [paintSmoothed]
/// is `LayoPainter`'s shared fill+stroke antialiasing helper, threaded
/// through so this free function does not need a `LayoPainter` instance of
/// its own.
void paintWinkEyes(
  Canvas canvas,
  double k, {
  required Color accentColor,
  required double winkT,
  required void Function(Canvas canvas, Color color, double k, void Function(Paint paint) shapeOnto) paintSmoothed,
}) {
  const leftCenter = Offset(134.67, 195.73);
  const rightCenter = Offset(261.17, 195.73);
  const radius = 15.57;

  // Left eye: always the plain open circle, completely unaffected by
  // winkT -- this is what makes the wink a one-eye animation rather than a
  // two-eye blink.
  paintSmoothed(
    canvas,
    accentColor,
    k,
    (paint) => canvas.drawCircle(Offset(leftCenter.dx * k, leftCenter.dy * k), radius * k, paint),
  );

  if (winkT <= 0.0) {
    paintSmoothed(
      canvas,
      accentColor,
      k,
      (paint) => canvas.drawCircle(Offset(rightCenter.dx * k, rightCenter.dy * k), radius * k, paint),
    );
    return;
  }

  const minScaleY = 0.1;
  final scaleY = 1.0 - (1.0 - minScaleY) * winkT.clamp(0.0, 1.0);
  final center = Offset(rightCenter.dx * k, rightCenter.dy * k);

  canvas.save();
  canvas.translate(center.dx, center.dy);
  canvas.scale(1.0, scaleY);
  canvas.translate(-center.dx, -center.dy);
  paintSmoothed(canvas, accentColor, k, (paint) => canvas.drawCircle(center, radius * k, paint));
  canvas.restore();
}
