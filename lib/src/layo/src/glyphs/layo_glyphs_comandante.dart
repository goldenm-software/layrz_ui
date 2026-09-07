/// [LayoEmotion.comandante]-only glyphs: the red beret **overlay**, the
/// chest ribbon rack, and the eyes, which rest exactly like
/// [LayoEmotion.mrLayo]'s two open circles but periodically wink the right
/// eye alone.
///
/// Every shape here is a verbatim port of the artist's own vector paths from
/// `comandante-layo.svg` (same `396.15`-wide source space as the mascot's
/// other emotions), scaled uniformly by the same `k` factor `LayoPainter`
/// derives from the painted [Size]. The beret spans roughly `x 0-352, y
/// 0-210` — tilted over the top-left of the head, overlapping the head
/// shell's own top edge — which is exactly why it is painted as an
/// **overlay** (after the head shell, see `LayoPainter`'s "Overlays"
/// section) rather than as a screen glyph confined to the dark screen
/// window every other emotion's glyphs live inside.
///
/// The chest ribbon rack ([paintComandanteChestInsignia]) is this emotion's
/// replacement for the bow-tie every other [LayoEmotion] wears
/// (`LayoPainter._wearsTie` excludes [LayoEmotion.comandante] alone) — two
/// stacked rows of small, multi-color-striped service-ribbon bars standing
/// in for the tie's usual spot, drawn on top of the body (not the overlay or
/// a screen glyph; see `LayoPainter.paint`'s own draw order) since it sits on
/// the chest, well below the head entirely.
///
/// The eyes themselves are this emotion's own screen glyph, dispatched from
/// `LayoPainter._paintEmotionGlyphs` like every other emotion's eyes — they
/// are not part of the overlay. At rest (`winkT == 0`) both eyes are open,
/// identical to [LayoEmotion.mrLayo]'s own two circles, at
/// [LayoEmotion.mrLayo]'s own eye-row coordinates (`y 195.73`) — **not** the
/// standalone `comandante-layo.svg` source's own eye geometry (`y 241.76`,
/// a different face layout, proportioned for a different base head, whose
/// eye row sits low enough to collide with this shared mascot's own mouth
/// at `y 224.26-261.20`); this emotion's face must share the same coordinate
/// system every other emotion's screen glyphs already use. [winkT] squashes
/// the **right** eye alone toward a thin ellipse and back, the same
/// technique [LayoEmotion.mrLayo]'s own `paintMrLayoEyes` uses for its
/// two-eye blink — the left eye is never touched by [winkT] and always
/// renders as the full open circle. The blue smile is [mrLayo]'s own
/// `paintMrLayoMouth`, unmodified — `LayoPainter` calls that directly rather
/// than duplicating it in this file.
library;

import 'package:flutter/widgets.dart';

/// Paints [LayoEmotion.comandante]'s eyes: two open blue circles at rest,
/// with [winkT] squashing the **right** eye alone toward a thin ellipse and
/// back — a one-eye version of [LayoEmotion.mrLayo]'s own two-eye blink.
///
/// Both eyes reuse [LayoEmotion.mrLayo]'s own eye-row coordinates exactly
/// (`cx="134.67"`/`cx="261.17"`, `cy="195.73"`, `r="15.57"`) — the shared
/// mascot's eye row, not `comandante-layo.svg`'s own standalone layout,
/// whose eyes sit much lower (`y 241.76`) at a height that would collide
/// with this shared face's mouth.
///
/// Unlike [LayoEmotion.mrLayo]'s [blinkT] (which closes both eyes together,
/// briefly, on an infrequent schedule, then reopens), [winkT] here closes
/// only the right eye — the Chávez-style signature wink this emotion is
/// named for — while the left eye stays open throughout, at every value of
/// [winkT]. Both parameters share the same `0` (open) to `1` (fully closed)
/// convention and the same squash-toward-ellipse technique, so
/// `LayoPainter`/`Layo` can drive [winkT] with the exact same kind of
/// infrequent, jittered, short-lived controller [blinkT] already uses for
/// [LayoEmotion.mrLayo] — only aimed at one eye instead of two.
///
/// [canvas] is the target being painted onto. [k] is the uniform scale
/// factor mapping the SVG source's `396.15`-wide coordinate space onto the
/// painted [Size]. [accentColor] fills both eyes. [winkT] is the right eye's
/// wink phase in `0..1`, `0` fully open and `1` fully closed; defaults are
/// the caller's responsibility (this function always honors whatever value
/// it is given). [paintSmoothed] is `LayoPainter`'s shared fill+stroke
/// antialiasing helper, threaded through so this free function does not need
/// a `LayoPainter` instance of its own.
void paintComandanteEyes(
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
  // second [LayoEmotion.mrLayo]-style two-eye blink.
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

/// How much [paintComandanteBeret] scales the beret's native horizontal
/// coordinates (before the shared `k` factor) so it caps the head shell's
/// full width without exposing either of the head's top corners underneath
/// it.
///
/// The source beret (drawn for a different base head) is a **tilted,
/// asymmetric** silhouette: its left tail extends down much further than
/// its right side, which tapers to a much shorter, higher-flopped tip past
/// native `x≈325` -- a real beret's brim genuinely does this, worn at an
/// angle, but it means the shape's *typical* lower edge across most of its
/// width (not the left tail's own extremity) is what actually determines
/// how far down the beret must sit to clear both of the head shell's
/// rounded top corners (`61.43-334.07`, top edge `98.89`, corner radius
/// `36.5`). This value — verified by sampling the ported path's own lower
/// edge in `~2`-native-unit steps across its full width against the head
/// shell's exact rounded-corner curve, not just its flat top edge — is the
/// smallest horizontal scale (paired with [_kBeretFitScaleY] and
/// [_kBeretFitTranslate]) at which no such gap remains.
const double _kBeretFitScaleX = 1.05;

/// How much [paintComandanteBeret] scales the beret's native vertical
/// coordinates (before the shared `k` factor) -- close to (but still a
/// touch smaller than) [_kBeretFitScaleX], giving the beret a full, puffy
/// crown rather than a flattened cap. [LayoEmotion.comandante] has no
/// antenna at all (see `LayoPainter._hasAntenna`), so nothing constrains how
/// tall the crown can rise above the head -- this value was chosen purely
/// for a proportionate, "real beret" silhouette, tall enough to read as a
/// domed crown without looking absurd. [_kBeretFitTranslate] is tuned
/// alongside it so the main brim (not the crown) still clears both of the
/// head shell's rounded top corners everywhere across its width.
const double _kBeretFitScaleY = 0.90;

/// How far [paintComandanteBeret] translates the beret's native coordinates
/// (after [_kBeretFitScaleX]/[_kBeretFitScaleY], before the shared `k`
/// factor) to sit it on top of the head shell: `dx` centers the
/// horizontally-scaled beret on the head shell's own center; `dy` is tuned
/// alongside [_kBeretFitScaleY] (see that constant's own doc comment for the
/// full derivation) so the beret's lower edge clears the head shell's
/// rounded top corners everywhere across its width, while its left tail's
/// own extremity (the lowest point on the whole shape) still maps to
/// roughly `y≈168` — comfortably above the eyes (`y 195.73` in this
/// emotion's own face) and the rest of the screen below them.
const Offset _kBeretFitTranslate = Offset(12.83, -20.0);

/// Paints [LayoEmotion.comandante]'s red beret overlay: a dark maroon
/// under-layer, a brighter red body on top, and two tiny highlight slivers
/// for the fold where the beret's brim meets its crown.
///
/// Every path is ported verbatim (at the source's own native coordinates)
/// from the source SVG, in the artist's own draw order (each layer painted
/// over the previous one):
///
/// * `#521010` (dark maroon) — the beret's under-shadow/base layer, painted
///   first so only the sliver the layers above do not cover reads as a
///   darker crease.
/// * `#90191c` (brighter red) — the beret's main body, on top of the maroon
///   base.
/// * `#1f0d0d` and `#6a1717` — two small highlight/shadow slivers at the
///   brim's tip, painted last.
///
/// Unlike every other glyph in this design system, the beret's native
/// coordinates are **not** proportioned for this mascot's own head -- the
/// source SVG's beret (`x 0-352, y 2-208`) is both wider and much taller
/// (relative to its width) than this mascot's head shell wants to wear (`x
/// 61.43-334.07`, top edge at `y 98.89`) -- a beret drawn at its native
/// proportions either exposes the head's rounded top corners (too small) or
/// balloons into a tall dome (scaled uniformly large enough to cover them).
/// Rather than re-deriving every control point by hand, this function draws
/// the ported paths at their exact native coordinates inside a **non-uniform**
/// canvas transform: [canvas.translate] by [_kBeretFitTranslate] then
/// [canvas.scale] by [_kBeretFitScaleX] horizontally and the deliberately
/// smaller [_kBeretFitScaleY] vertically (both applied, alongside the shared
/// `k`, via [canvas.save]/[canvas.restore] around every path below) -- so the
/// verbatim port and the fit onto this particular head (width for coverage,
/// height for a flat cap rather than a dome) are separate, independently
/// tunable concerns rather than baked together into re-fitted control points
/// that would no longer trace back to the source file.
///
/// [canvas] is the target being painted onto. [k] is the uniform scale
/// factor mapping the SVG source's `396.15`-wide coordinate space onto the
/// painted [Size]. [paintSmoothed] is `LayoPainter`'s shared fill+stroke
/// antialiasing helper, threaded through so this free function does not need
/// a `LayoPainter` instance of its own.
void paintComandanteBeret(
  Canvas canvas,
  double k, {
  required void Function(Canvas canvas, Color color, double k, void Function(Paint paint) shapeOnto) paintSmoothed,
}) {
  canvas.save();
  canvas.scale(k);
  canvas.translate(_kBeretFitTranslate.dx, _kBeretFitTranslate.dy);
  canvas.scale(_kBeretFitScaleX, _kBeretFitScaleY);

  final base = Path()
    ..moveTo(351.70, 95.24)
    ..cubicTo(349.73, 102.21, 345.51, 108.27, 341.59, 114.43)
    ..cubicTo(335.96, 123.27, 329.68, 131.80, 325.10, 141.14)
    ..cubicTo(324.56, 142.25, 324.09, 143.38, 323.56, 144.50)
    ..cubicTo(322.47, 146.82, 321.95, 148.95, 322.90, 151.64)
    ..cubicTo(324.50, 156.16, 323.65, 160.74, 320.82, 164.87)
    ..cubicTo(318.60, 168.12, 315.15, 169.38, 310.97, 168.64)
    ..cubicTo(295.24, 165.86, 279.31, 164.74, 263.33, 163.83)
    ..cubicTo(248.32, 162.98, 233.30, 162.68, 218.28, 162.61)
    ..cubicTo(204.92, 162.56, 191.54, 162.73, 178.18, 163.34)
    ..cubicTo(168.85, 163.77, 159.50, 164.07, 150.17, 164.52)
    ..cubicTo(135.91, 165.21, 121.69, 166.30, 107.50, 167.70)
    ..cubicTo(102.41, 168.20, 97.35, 168.87, 92.26, 169.33)
    ..cubicTo(90.76, 169.47, 89.79, 169.97, 88.83, 170.97)
    ..cubicTo(76.54, 183.77, 62.30, 194.52, 45.52, 202.56)
    ..cubicTo(40.21, 205.10, 34.62, 207.15, 28.61, 208.04)
    ..cubicTo(15.63, 209.96, 7.21, 205.52, 2.84, 194.61)
    ..cubicTo(-0.33, 186.68, -0.29, 178.47, 0.32, 170.26)
    ..cubicTo(0.69, 165.30, 1.41, 160.32, 2.91, 155.54)
    ..cubicTo(4.32, 151.06, 6.33, 146.72, 8.24, 142.37)
    ..cubicTo(14.85, 127.26, 25.03, 114.04, 36.09, 101.22)
    ..cubicTo(64.58, 68.20, 101.68, 44.94, 143.66, 27.12)
    ..cubicTo(158.00, 21.03, 172.69, 15.68, 187.56, 10.66)
    ..cubicTo(192.39, 9.03, 197.36, 7.72, 202.12, 5.84)
    ..cubicTo(205.41, 4.54, 209.36, 4.54, 212.99, 3.80)
    ..cubicTo(230.42, 0.21, 247.20, 3.13, 263.54, 8.41)
    ..cubicTo(291.29, 17.39, 315.24, 31.63, 336.43, 49.68)
    ..cubicTo(344.61, 56.65, 348.04, 65.49, 350.56, 74.81)
    ..cubicTo(351.04, 76.60, 351.34, 78.43, 351.72, 80.25)
    ..cubicTo(352.34, 81.16, 351.53, 82.27, 352.24, 83.00)
    ..lineTo(352.24, 92.68)
    ..cubicTo(351.56, 93.40, 352.34, 94.38, 351.70, 95.24)
    ..close();
  paintSmoothed(canvas, const Color(0xFF521010), k, (paint) => canvas.drawPath(base, paint));

  final body = Path()
    ..moveTo(197.55, 87.95)
    ..cubicTo(187.09, 88.50, 176.92, 90.50, 166.88, 92.95)
    ..cubicTo(146.04, 98.03, 126.51, 105.88, 107.63, 115.05)
    ..cubicTo(104.57, 116.54, 102.78, 119.17, 100.73, 121.52)
    ..cubicTo(89.61, 134.34, 80.08, 148.11, 69.93, 161.51)
    ..cubicTo(62.56, 171.24, 54.60, 180.58, 45.41, 189.07)
    ..cubicTo(43.60, 190.74, 41.19, 191.87, 39.84, 193.94)
    ..cubicTo(39.66, 194.26, 39.48, 194.57, 39.03, 194.64)
    ..cubicTo(39.60, 194.63, 39.88, 194.21, 40.27, 193.95)
    ..cubicTo(44.31, 192.70, 47.35, 190.13, 50.61, 187.86)
    ..cubicTo(55.94, 184.15, 60.71, 179.89, 65.37, 175.55)
    ..cubicTo(66.68, 174.32, 68.03, 173.51, 69.99, 173.32)
    ..cubicTo(73.16, 173.01, 76.31, 172.50, 79.52, 172.06)
    ..cubicTo(79.54, 173.10, 78.68, 173.43, 78.13, 173.90)
    ..cubicTo(68.49, 182.21, 58.53, 190.18, 46.82, 196.24)
    ..cubicTo(38.92, 200.32, 30.60, 202.96, 21.23, 202.18)
    ..cubicTo(16.35, 201.77, 12.81, 199.75, 10.71, 195.80)
    ..cubicTo(8.34, 191.33, 7.65, 186.54, 7.33, 181.71)
    ..cubicTo(5.96, 161.35, 13.54, 143.16, 25.33, 126.13)
    ..cubicTo(48.43, 92.78, 79.24, 66.27, 117.50, 46.43)
    ..cubicTo(140.85, 34.32, 165.29, 24.26, 190.78, 16.17)
    ..cubicTo(199.62, 13.36, 208.52, 10.65, 217.79, 9.14)
    ..cubicTo(229.38, 7.25, 240.78, 8.57, 252.02, 11.26)
    ..cubicTo(273.02, 16.29, 291.59, 25.53, 308.92, 36.88)
    ..cubicTo(316.95, 42.14, 324.49, 47.90, 331.39, 54.29)
    ..cubicTo(347.29, 69.03, 350.09, 90.40, 338.29, 107.80)
    ..cubicTo(334.11, 113.96, 329.58, 119.93, 325.37, 126.07)
    ..cubicTo(321.58, 131.61, 318.54, 137.47, 316.41, 143.68)
    ..cubicTo(315.95, 145.02, 315.39, 145.68, 313.55, 145.40)
    ..cubicTo(297.02, 142.92, 280.35, 141.59, 263.62, 140.57)
    ..cubicTo(238.62, 139.05, 213.61, 138.91, 188.59, 139.46)
    ..cubicTo(166.97, 139.94, 145.40, 141.12, 123.87, 143.04)
    ..cubicTo(111.86, 144.11, 99.88, 145.36, 87.93, 146.87)
    ..cubicTo(87.65, 146.03, 88.39, 145.63, 88.77, 145.16)
    ..cubicTo(93.24, 139.65, 97.88, 134.24, 102.20, 128.64)
    ..cubicTo(107.93, 121.23, 115.66, 116.10, 124.64, 112.06)
    ..cubicTo(141.77, 104.35, 159.75, 98.73, 178.25, 94.27)
    ..cubicTo(186.53, 92.27, 194.86, 90.44, 203.17, 88.54)
    ..cubicTo(203.93, 87.73, 205.09, 88.03, 206.22, 87.69)
    ..cubicTo(203.22, 88.26, 200.36, 87.23, 197.55, 87.95)
    ..close();
  paintSmoothed(canvas, const Color(0xFF90191C), k, (paint) => canvas.drawPath(body, paint));

  final tinySliverA = Path()
    ..moveTo(197.55, 87.95)
    ..cubicTo(200.64, 87.22, 203.79, 87.42, 206.96, 87.57)
    ..cubicTo(205.77, 88.14, 204.55, 88.56, 203.18, 88.54)
    ..cubicTo(201.44, 87.35, 199.41, 88.30, 197.55, 87.95)
    ..close();
  paintSmoothed(canvas, const Color(0xFF1F0D0D), k, (paint) => canvas.drawPath(tinySliverA, paint));

  final tinySliverB = Path()
    ..moveTo(40.27, 193.96)
    ..cubicTo(39.91, 195.00, 39.06, 195.36, 37.34, 195.40)
    ..cubicTo(38.46, 194.75, 39.15, 194.35, 39.83, 193.95)
    ..cubicTo(39.98, 193.91, 40.12, 193.91, 40.27, 193.96)
    ..close();
  paintSmoothed(canvas, const Color(0xFF6A1717), k, (paint) => canvas.drawPath(tinySliverB, paint));

  canvas.restore();
}

/// One ribbon bar's own vertical stripe colors, left to right -- each entry
/// in [_kRibbonBarStripes] is one bar's full stripe sequence. Colors are a
/// deliberately varied mix of classic service-ribbon tones (greens, reds,
/// blues, gold, white, navy) so the six bars read as a real decorated
/// ribbon rack rather than six copies of the same bar.
const List<List<Color>> _kRibbonBarStripes = [
  [Color(0xFFB71C1C), Color(0xFFFFD600), Color(0xFFB71C1C)],
  [Color(0xFF1B5E20), Color(0xFFFFFFFF), Color(0xFF1B5E20)],
  [Color(0xFF0D47A1), Color(0xFFFFD600), Color(0xFF0D47A1)],
  [Color(0xFFFFFFFF), Color(0xFF1A237E), Color(0xFFFFFFFF)],
  [Color(0xFF1B5E20), Color(0xFFB71C1C), Color(0xFFFFD600)],
  [Color(0xFF0D47A1), Color(0xFFFFFFFF), Color(0xFFB71C1C)],
];

/// Where [paintComandanteChestInsignia] centers the whole ribbon rack
/// horizontally -- deliberately offset to the **right** of the shared
/// artwork's own vertical axis (`x 197.66`, the body/head/antenna's own
/// center), the way a real ribbon rack sits over the wearer's own left
/// breast pocket, which reads as screen-right on a face-forward figure.
const double _kRibbonRackCenterX = 197.66 + 55.0;

/// The topmost row's own top edge, in native coordinates -- just below the
/// face shadow's own bottom edge (`y 339.15`, `LayoPainter._paintFaceShadow`)
/// and the head/body seam, on the upper chest of the inner body dome
/// (`LayoPainter._paintBody`'s `inner` path spans roughly `y 323-675`), the
/// same upper-chest spot a real ribbon rack sits just below the shoulder.
const double _kRibbonRackTopY = 350.0;

/// Each individual ribbon bar's width and height, in native units -- small
/// and rectangular, like a real service ribbon.
const double _kRibbonBarWidth = 32.0;

/// See [_kRibbonBarWidth].
const double _kRibbonBarHeight = 9.0;

/// Horizontal gap between adjacent bars within one row.
const double _kRibbonBarGutterX = 4.0;

/// Vertical gap between the two stacked rows.
const double _kRibbonBarGutterY = 4.0;

/// How many bars sit side by side in each row.
const int _kRibbonBarsPerRow = 3;

/// Paints [LayoEmotion.comandante]'s chest ribbon rack: two stacked rows of
/// small, multi-color-striped service-ribbon bars -- this emotion's
/// replacement for the bow-tie every other [LayoEmotion] wears (see this
/// file's own top-of-file doc comment).
///
/// Each bar is a plain rect, subdivided into a handful of equal-width
/// vertical color stripes (see [_kRibbonBarStripes] for the exact per-bar
/// palettes) -- a compact, legible stand-in for a real ribbon's woven
/// pattern rather than an over-detailed illustration, matching the
/// maintainer's request to keep this glyph modest and simple. Purely
/// static -- no animation parameter is threaded through here.
///
/// [canvas] is the target being painted onto. [k] is the uniform scale
/// factor mapping the SVG source's `396.15`-wide coordinate space onto the
/// painted [Size]. [paintSmoothed] is `LayoPainter`'s shared fill+stroke
/// antialiasing helper, threaded through so this free function does not need
/// a `LayoPainter` instance of its own.
void paintComandanteChestInsignia(
  Canvas canvas,
  double k, {
  required void Function(Canvas canvas, Color color, double k, void Function(Paint paint) shapeOnto) paintSmoothed,
}) {
  final rowWidth = _kRibbonBarsPerRow * _kRibbonBarWidth + (_kRibbonBarsPerRow - 1) * _kRibbonBarGutterX;
  final rackLeft = _kRibbonRackCenterX - rowWidth / 2;

  for (var barIndex = 0; barIndex < _kRibbonBarStripes.length; barIndex++) {
    final row = barIndex ~/ _kRibbonBarsPerRow;
    final col = barIndex % _kRibbonBarsPerRow;

    final barLeft = rackLeft + col * (_kRibbonBarWidth + _kRibbonBarGutterX);
    final barTop = _kRibbonRackTopY + row * (_kRibbonBarHeight + _kRibbonBarGutterY);

    final stripes = _kRibbonBarStripes[barIndex];
    final stripeWidth = _kRibbonBarWidth / stripes.length;

    for (var stripeIndex = 0; stripeIndex < stripes.length; stripeIndex++) {
      final stripeLeft = barLeft + stripeIndex * stripeWidth;
      final rect = Rect.fromLTWH(stripeLeft * k, barTop * k, stripeWidth * k, _kRibbonBarHeight * k);
      canvas.drawRect(
        rect,
        Paint()
          ..color = stripes[stripeIndex]
          ..isAntiAlias = true,
      );
    }
  }
}
