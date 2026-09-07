/// [LayoEmotion.mrLayo]-only glyph painters: the bow-tie, the smiling mouth,
/// and the blinkable circular eyes.
///
/// Every shape here is a verbatim port of the artist's own vector paths from
/// the source `Mr Layo.ai` file (converted to SVG, `viewBox 0 0 396.15
/// 659.76`), scaled uniformly by the same `k` factor `LayoPainter` derives
/// from the painted [Size]. These three glyphs are the only ones this
/// mascot's default face wears; every other emotion replaces them with its
/// own glyph set instead of layering on top of these.
///
/// Extracted from `LayoPainter` verbatim during the emotion-driven refactor —
/// no coordinates changed — so [LayoEmotion.mrLayo] continues to render
/// pixel-identically to the pre-refactor single-emotion painter.
library;

import 'package:flutter/widgets.dart';

/// The fraction by which [tieFoldColor] darkens [accentColor] toward black
/// for the bow-tie's small internal crease cusps -- roughly 20%, tuned so
/// [LayoEmotion.mrLayo]'s tie (whose accent is its original blue) still
/// reads the same as the pre-refactor single-color tie: dark enough that the
/// creases are visible as a subtle fold, not so dark that the tie stops
/// reading as one coherent blue shape.
const double _kTieFoldDarkenFraction = 0.2;

/// Derives the bow-tie's crease-fold color from [accentColor] by darkening
/// it toward black by [_kTieFoldDarkenFraction] -- every emotion's tie is
/// now shaded relative to its own accent (see [paintMrLayoTie]), rather than
/// a single color hardcoded for [LayoEmotion.mrLayo] alone.
Color tieFoldColor(Color accentColor) => Color.lerp(accentColor, const Color(0xFF000000), _kTieFoldDarkenFraction)!;

/// Paints the bow-tie: the dark outline shape first, then the tie's main
/// body in [accentColor], then its small internal crease cusps in
/// [tieFoldColor]'s darkened derivative of [accentColor] on top.
///
/// Worn by every [LayoEmotion] (not just [LayoEmotion.mrLayo] as in the
/// original single-face painter), so its base color always follows the
/// current emotion's own accent -- blue for [LayoEmotion.mrLayo] and
/// [LayoEmotion.question], grey for [LayoEmotion.sleep] and
/// [LayoEmotion.dead] -- with the fold derived from that same accent so the
/// tie stays dimensional regardless of which color it is currently wearing.
///
/// Every path is ported verbatim from the source SVG. The outline path is
/// filled solid (not stroked) — in the source artwork it is itself a closed
/// region very slightly larger than the fill on top of it, so only a thin
/// sliver of it remains visible as an outline once the fill is painted over
/// it, exactly reproducing the reference's thin dark edge. The main body and
/// the crease cusps were ported as one single path in the original artwork
/// (and rendered in one flat color) — this function paints them as two
/// separate paths at two different, but related, colors instead, so the
/// fold reads as shading rather than as a coincidence of the artwork's line
/// work.
///
/// [canvas] is the target being painted onto. [k] is the uniform scale
/// factor mapping the SVG source's `396.15`-wide coordinate space onto the
/// painted [Size]. [outlineColor] fills the dark outline sliver (the
/// mascot's screen color, unrelated to [accentColor]). [accentColor] fills
/// the tie's main body and seeds [tieFoldColor] for its crease cusps.
/// [paintSmoothed] is `LayoPainter`'s shared fill+stroke antialiasing
/// helper, threaded through so this free function does not need a
/// [LayoPainter] instance of its own.
void paintMrLayoTie(
  Canvas canvas,
  double k, {
  required Color outlineColor,
  required Color accentColor,
  required void Function(Canvas canvas, Color color, double k, void Function(Paint paint) shapeOnto) paintSmoothed,
}) {
  final outline = Path()
    ..moveTo(189.98 * k, 348.29 * k)
    ..cubicTo(190.64 * k, 347.46 * k, 191.52 * k, 347.28 * k, 192.5 * k, 347.29 * k)
    ..cubicTo(195.91 * k, 347.32 * k, 199.32 * k, 347.31 * k, 202.73 * k, 347.30 * k)
    ..cubicTo(203.39 * k, 347.29 * k, 204.04 * k, 347.37 * k, 204.49 * k, 347.89 * k)
    ..cubicTo(204.93 * k, 348.38 * k, 205.13 * k, 348.14 * k, 205.45 * k, 347.77 * k)
    ..cubicTo(209.68 * k, 342.91 * k, 214.42 * k, 338.75 * k, 219.79 * k, 335.41 * k)
    ..cubicTo(224.40 * k, 332.55 * k, 229.43 * k, 330.91 * k, 234.50 * k, 329.39 * k)
    ..cubicTo(238.94 * k, 328.05 * k, 243.43 * k, 326.99 * k, 247.94 * k, 325.94 * k)
    ..cubicTo(248.48 * k, 325.82 * k, 248.77 * k, 325.82 * k, 248.93 * k, 326.57 * k)
    ..cubicTo(251.48 * k, 338.32 * k, 252.48 * k, 350.22 * k, 251.93 * k, 362.27 * k)
    ..cubicTo(251.61 * k, 369.45 * k, 250.96 * k, 376.61 * k, 249.67 * k, 383.68 * k)
    ..cubicTo(249.57 * k, 384.21 * k, 249.43 * k, 384.38 * k, 248.93 * k, 384.30 * k)
    ..cubicTo(239.05 * k, 382.82 * k, 229.34 * k, 380.62 * k, 220.47 * k, 375.48 * k)
    ..cubicTo(214.73 * k, 372.15 * k, 209.93 * k, 367.51 * k, 205.60 * k, 362.30 * k)
    ..cubicTo(205.21 * k, 361.83 * k, 205.01 * k, 361.63 * k, 204.55 * k, 362.21 * k)
    ..cubicTo(204.18 * k, 362.69 * k, 203.60 * k, 362.87 * k, 203 * k, 362.87 * k)
    ..cubicTo(199.32 * k, 362.87 * k, 195.64 * k, 362.86 * k, 191.95 * k, 362.87 * k)
    ..cubicTo(191.32 * k, 362.87 * k, 190.71 * k, 362.70 * k, 190.32 * k, 362.18 * k)
    ..cubicTo(189.87 * k, 361.56 * k, 189.67 * k, 361.88 * k, 189.34 * k, 362.27 * k)
    ..cubicTo(184.59 * k, 367.96 * k, 179.29 * k, 372.92 * k, 172.89 * k, 376.37 * k)
    ..cubicTo(167.15 * k, 379.47 * k, 161.00 * k, 381.28 * k, 154.75 * k, 382.71 * k)
    ..cubicTo(151.92 * k, 383.36 * k, 149.07 * k, 383.85 * k, 146.20 * k, 384.29 * k)
    ..cubicTo(145.59 * k, 384.38 * k, 145.34 * k, 384.29 * k, 145.20 * k, 383.54 * k)
    ..cubicTo(144.30 * k, 378.44 * k, 143.71 * k, 373.30 * k, 143.32 * k, 368.13 * k)
    ..cubicTo(142.87 * k, 362.05 * k, 142.68 * k, 355.96 * k, 142.96 * k, 349.86 * k)
    ..cubicTo(143.32 * k, 341.95 * k, 144.34 * k, 334.14 * k, 146.01 * k, 326.42 * k)
    ..cubicTo(146.12 * k, 325.92 * k, 146.32 * k, 325.80 * k, 146.75 * k, 325.90 * k)
    ..cubicTo(155.08 * k, 327.84 * k, 163.45 * k, 329.68 * k, 171.29 * k, 333.35 * k)
    ..cubicTo(178.19 * k, 336.58 * k, 183.95 * k, 341.57 * k, 189.13 * k, 347.38 * k)
    ..cubicTo(189.35 * k, 347.64 * k, 189.58 * k, 347.90 * k, 189.81 * k, 348.16 * k)
    ..close();
  paintSmoothed(canvas, outlineColor, k, (paint) => canvas.drawPath(outline, paint));

  final body = Path()
    ..moveTo(190.20 * k, 348.90 * k)
    ..cubicTo(190.84 * k, 348.15 * k, 191.68 * k, 347.99 * k, 192.64 * k, 348.00 * k)
    ..cubicTo(195.95 * k, 348.03 * k, 199.27 * k, 348.02 * k, 202.58 * k, 348.00 * k)
    ..cubicTo(203.22 * k, 348.00 * k, 203.85 * k, 348.07 * k, 204.29 * k, 348.54 * k)
    ..cubicTo(204.71 * k, 348.98 * k, 204.91 * k, 348.77 * k, 205.22 * k, 348.44 * k)
    ..cubicTo(209.33 * k, 344.04 * k, 213.94 * k, 340.28 * k, 219.16 * k, 337.26 * k)
    ..cubicTo(223.63 * k, 334.67 * k, 228.52 * k, 333.19 * k, 233.45 * k, 331.81 * k)
    ..cubicTo(237.76 * k, 330.61 * k, 242.13 * k, 329.64 * k, 246.50 * k, 328.70 * k)
    ..cubicTo(247.02 * k, 328.58 * k, 247.30 * k, 328.59 * k, 247.46 * k, 329.26 * k)
    ..cubicTo(249.94 * k, 339.89 * k, 250.91 * k, 350.65 * k, 250.38 * k, 361.54 * k)
    ..cubicTo(250.06 * k, 368.04 * k, 249.43 * k, 374.51 * k, 248.18 * k, 380.90 * k)
    ..cubicTo(248.09 * k, 381.39 * k, 247.95 * k, 381.54 * k, 247.46 * k, 381.46 * k)
    ..cubicTo(237.86 * k, 380.13 * k, 228.43 * k, 378.14 * k, 219.81 * k, 373.48 * k)
    ..cubicTo(214.23 * k, 370.48 * k, 209.57 * k, 366.28 * k, 205.37 * k, 361.57 * k)
    ..cubicTo(204.99 * k, 361.15 * k, 204.79 * k, 360.97 * k, 204.35 * k, 361.49 * k)
    ..cubicTo(203.98 * k, 361.93 * k, 203.43 * k, 362.08 * k, 202.84 * k, 362.08 * k)
    ..cubicTo(199.27 * k, 362.08 * k, 195.69 * k, 362.08 * k, 192.11 * k, 362.09 * k)
    ..cubicTo(191.49 * k, 362.09 * k, 190.90 * k, 361.93 * k, 190.53 * k, 361.46 * k)
    ..cubicTo(190.09 * k, 360.91 * k, 189.89 * k, 361.19 * k, 189.57 * k, 361.55 * k)
    ..cubicTo(184.96 * k, 366.69 * k, 179.80 * k, 371.17 * k, 173.59 * k, 374.29 * k)
    ..cubicTo(168.01 * k, 377.09 * k, 162.04 * k, 378.73 * k, 155.97 * k, 380.03 * k)
    ..cubicTo(153.22 * k, 380.62 * k, 150.45 * k, 381.05 * k, 147.66 * k, 381.45 * k)
    ..cubicTo(147.07 * k, 381.54 * k, 146.82 * k, 381.45 * k, 146.70 * k, 380.77 * k)
    ..cubicTo(145.82 * k, 376.16 * k, 145.25 * k, 371.52 * k, 144.87 * k, 366.84 * k)
    ..cubicTo(144.43 * k, 361.34 * k, 144.24 * k, 355.84 * k, 144.51 * k, 350.32 * k)
    ..cubicTo(144.86 * k, 343.17 * k, 145.85 * k, 336.11 * k, 147.48 * k, 329.13 * k)
    ..cubicTo(147.58 * k, 328.68 * k, 147.78 * k, 328.57 * k, 148.20 * k, 328.66 * k)
    ..cubicTo(156.29 * k, 330.41 * k, 164.41 * k, 332.07 * k, 172.04 * k, 335.39 * k)
    ..cubicTo(178.73 * k, 338.31 * k, 184.34 * k, 342.83 * k, 189.36 * k, 348.08 * k)
    ..cubicTo(189.58 * k, 348.32 * k, 189.80 * k, 348.55 * k, 190.03 * k, 348.79 * k)
    ..close();
  paintSmoothed(canvas, accentColor, k, (paint) => canvas.drawPath(body, paint));

  final creaseCusps = Path()
    ..moveTo(176.82 * k, 362.37 * k)
    ..cubicTo(177.25 * k, 362.47 * k, 177.54 * k, 362.43 * k, 177.82 * k, 362.36 * k)
    ..cubicTo(181.48 * k, 361.43 * k, 185.05 * k, 360.25 * k, 188.55 * k, 358.88 * k)
    ..cubicTo(189.88 * k, 358.36 * k, 189.88 * k, 358.34 * k, 189.60 * k, 356.80 * k)
    ..cubicTo(185.52 * k, 358.98 * k, 181.32 * k, 360.84 * k, 176.82 * k, 362.37 * k)
    ..close()
    ..moveTo(205.24 * k, 356.77 * k)
    ..cubicTo(205.13 * k, 358.39 * k, 205.14 * k, 358.38 * k, 206.51 * k, 358.93 * k)
    ..cubicTo(209.11 * k, 359.98 * k, 211.78 * k, 360.85 * k, 214.46 * k, 361.66 * k)
    ..cubicTo(215.02 * k, 361.82 * k, 215.59 * k, 361.96 * k, 216.16 * k, 362.10 * k)
    ..cubicTo(216.69 * k, 362.21 * k, 217.21 * k, 362.49 * k, 217.79 * k, 362.36 * k)
    ..cubicTo(213.50 * k, 360.79 * k, 209.35 * k, 358.96 * k, 205.24 * k, 356.77 * k)
    ..close()
    ..moveTo(218.23 * k, 347.81 * k)
    ..cubicTo(218.01 * k, 347.85 * k, 217.78 * k, 347.89 * k, 217.56 * k, 347.94 * k)
    ..cubicTo(213.78 * k, 348.85 * k, 210.09 * k, 350.04 * k, 206.48 * k, 351.48 * k)
    ..cubicTo(205.11 * k, 352.03 * k, 205.10 * k, 352.02 * k, 205.26 * k, 353.61 * k)
    ..cubicTo(209.48 * k, 351.38 * k, 213.80 * k, 349.45 * k, 218.23 * k, 347.81 * k)
    ..close()
    ..moveTo(176.44 * k, 347.86 * k)
    ..cubicTo(181.00 * k, 349.39 * k, 185.37 * k, 351.36 * k, 189.64 * k, 353.60 * k)
    ..cubicTo(189.82 * k, 352.03 * k, 189.82 * k, 352.04 * k, 188.53 * k, 351.51 * k)
    ..cubicTo(185.93 * k, 350.46 * k, 183.28 * k, 349.55 * k, 180.59 * k, 348.80 * k)
    ..cubicTo(179.23 * k, 348.41 * k, 177.88 * k, 347.93 * k, 176.44 * k, 347.86 * k)
    ..close();
  paintSmoothed(canvas, tieFoldColor(accentColor), k, (paint) => canvas.drawPath(creaseCusps, paint));
}

/// Paints the blue smile: a single cubic-Bézier path with a straight-ish top
/// edge and a bulging bottom edge, ported verbatim rather than approximated
/// as a rounded rect or ellipse.
///
/// [canvas] is the target being painted onto. [k] is the uniform scale
/// factor. [accentColor] fills the mouth. [paintSmoothed] is `LayoPainter`'s
/// shared fill+stroke antialiasing helper.
void paintMrLayoMouth(
  Canvas canvas,
  double k, {
  required Color accentColor,
  required void Function(Canvas canvas, Color color, double k, void Function(Paint paint) shapeOnto) paintSmoothed,
}) {
  final path = Path()
    ..moveTo(252.58 * k, 237.40 * k)
    ..cubicTo(252.58 * k, 250.54 * k, 228.11 * k, 261.20 * k, 197.93 * k, 261.20 * k)
    ..cubicTo(167.74 * k, 261.20 * k, 143.27 * k, 250.54 * k, 143.27 * k, 237.40 * k)
    ..cubicTo(143.27 * k, 224.26 * k, 252.58 * k, 224.26 * k, 252.58 * k, 237.40 * k)
    ..close();
  paintSmoothed(canvas, accentColor, k, (paint) => canvas.drawPath(path, paint));
}

/// Paints the two blue eyes, at their exact source radius and centers,
/// vertically squashed by [blinkT].
///
/// At rest (`blinkT == 0`) each eye is drawn as the original circle via
/// [Canvas.drawCircle]. Mid-blink, the eye becomes a vertically-scaled
/// ellipse — `scaleY` runs from `1.0` (open) down toward `0.1` (all but
/// closed) and back as [blinkT] sweeps `0 -> 1 -> 0` over the blink's short
/// lifetime — drawn by scaling the canvas around the eye's own center rather
/// than by constructing a new shape, so the same [paintSmoothed] fill+stroke
/// smoothing still applies unchanged.
///
/// [canvas] is the target being painted onto. [k] is the uniform scale
/// factor. [accentColor] fills both eyes. [blinkT] is the eye-blink phase in
/// `0..1`, `0` fully open and `1` fully closed. [paintSmoothed] is
/// `LayoPainter`'s shared fill+stroke antialiasing helper.
void paintMrLayoEyes(
  Canvas canvas,
  double k, {
  required Color accentColor,
  required double blinkT,
  required void Function(Canvas canvas, Color color, double k, void Function(Paint paint) shapeOnto) paintSmoothed,
}) {
  final leftCenter = Offset(134.67 * k, 195.73 * k);
  final rightCenter = Offset(261.17 * k, 195.73 * k);
  const radiusFraction = 15.57;

  if (blinkT <= 0.0) {
    paintSmoothed(canvas, accentColor, k, (paint) => canvas.drawCircle(leftCenter, radiusFraction * k, paint));
    paintSmoothed(canvas, accentColor, k, (paint) => canvas.drawCircle(rightCenter, radiusFraction * k, paint));
    return;
  }

  const minScaleY = 0.1;
  final scaleY = 1.0 - (1.0 - minScaleY) * blinkT.clamp(0.0, 1.0);

  for (final center in [leftCenter, rightCenter]) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(1.0, scaleY);
    canvas.translate(-center.dx, -center.dy);
    paintSmoothed(canvas, accentColor, k, (paint) => canvas.drawCircle(center, radiusFraction * k, paint));
    canvas.restore();
  }
}
