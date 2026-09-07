/// [LayoEmotion.idea]-only glyphs: a lightbulb outline plus its base and
/// filament bars, standing in for this emotion's face. No separate mouth is
/// drawn for [LayoEmotion.idea] — the bulb is the whole glyph.
///
/// Every shape here is a verbatim port of the artist's own vector paths from
/// `emo-idea.svg` (same `396.15`-wide source space as the mascot's other
/// emotions), scaled uniformly by the same `k` factor `LayoPainter` derives
/// from the painted [Size]. The source artwork's own fill is overridden by
/// the caller's `accentColor` (this emotion's exact `#F5CC24` yellow),
/// rather than hardcoding the source fill.
library;

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Paints [LayoEmotion.idea]'s lightbulb glyph (outline, base, and filament
/// bars), with a soft glow ring behind it and a brightness modulation on the
/// fill itself, both driven by [glowT] and [flashT].
///
/// [glowT] is the idle continuous glow-pulse phase in `0..1`, looping,
/// interpreted the same sine-eased "breath" way as the antenna's own pulse:
/// it drives a low-alpha glow ring's radius/opacity and a gentle brightness
/// lift on the bulb fill. [flashT] is an occasional stronger "insight" flash
/// in `0..1` (`0` between flashes); at its peak the bulb fill brightens
/// further, on top of whatever [glowT] is doing. At `glowT == 0` and
/// `flashT == 0` the bulb renders at its exact original, unmodified fill and
/// no glow ring is drawn.
///
/// Bulb outline spans roughly `x 160-233, y 163-250`; the base/filament bars
/// span `x 183-211, y 253-264`. All shapes are ported verbatim from
/// `emo-idea.svg`.
///
/// The glow ring's radius grows well beyond the bulb's own bounds at a
/// strong "insight" flash (`flashT` near `1.0`), so `LayoPainter` clips this
/// entire call to the dark screen's own rect before invoking it -- the
/// bulb's light must stay enclosed behind the screen glass rather than
/// spilling onto the head shell or body, exactly like every other emotion's
/// glyphs never paint outside that window. This function itself does not
/// clip; it relies on its caller having already done so.
///
/// [canvas] is the target being painted onto. [k] is the uniform scale
/// factor mapping the SVG source's `396.15`-wide coordinate space onto the
/// painted [Size]. [accentColor] is the bulb's base fill (this emotion's
/// yellow). [paintSmoothed] is `LayoPainter`'s shared fill+stroke
/// antialiasing helper, threaded through so this free function does not need
/// a `LayoPainter` instance of its own.
void paintIdeaGlyphs(
  Canvas canvas,
  double k, {
  required Color accentColor,
  required double glowT,
  required double flashT,
  required void Function(Canvas canvas, Color color, double k, void Function(Paint paint) shapeOnto) paintSmoothed,
}) {
  final breath = math.sin(glowT.clamp(0.0, 1.0) * math.pi);
  final flash = flashT.clamp(0.0, 1.0);

  final glowCenter = Offset(197 * k, 210 * k);
  final glowAlpha = 0.22 * breath + 0.35 * flash;
  if (glowAlpha > 0.0) {
    final glowRadius = (52 + 18 * breath + 24 * flash) * k;
    canvas.drawCircle(
      glowCenter,
      glowRadius,
      Paint()
        ..color = accentColor.withValues(alpha: glowAlpha.clamp(0.0, 1.0))
        ..style = PaintingStyle.fill
        ..isAntiAlias = true,
    );
  }

  final brightness = (0.12 * breath + 0.3 * flash).clamp(0.0, 1.0);
  final fillColor = Color.lerp(accentColor, const Color(0xFFFFFFFF), brightness)!;

  paintSmoothed(canvas, fillColor, k, (paint) => canvas.drawPath(_bulbOutline(k), paint));
  paintSmoothed(canvas, fillColor, k, (paint) => canvas.drawPath(_filamentSpiral(k), paint));
  paintSmoothed(canvas, fillColor, k, (paint) => canvas.drawPath(_baseTop(k), paint));
  paintSmoothed(canvas, fillColor, k, (paint) => canvas.drawPath(_baseBottom(k), paint));
}

/// The bulb's outer glass outline, ported verbatim from `emo-idea.svg`.
Path _bulbOutline(double k) {
  return Path()
    ..moveTo(227.933594 * k, 199.210938 * k)
    ..cubicTo(227.476562 * k, 206.042969 * k, 224.933594 * k, 212.570312 * k, 220.648438 * k, 217.910156 * k)
    ..cubicTo(218.652344 * k, 220.464844 * k, 216.769531 * k, 223.050781 * k, 214.972656 * k, 225.722656 * k)
    ..cubicTo(212.667969 * k, 229.054688 * k, 211.472656 * k, 233.027344 * k, 211.558594 * k, 237.078125 * k)
    ..cubicTo(211.605469 * k, 238.863281 * k, 211.519531 * k, 240.648438 * k, 211.300781 * k, 242.417969 * k)
    ..cubicTo(211.226562 * k, 242.957031 * k, 211.093750 * k, 243.484375 * k, 210.910156 * k, 243.996094 * k)
    ..cubicTo(210.656250 * k, 244.964844 * k, 209.722656 * k, 245.597656 * k, 208.726562 * k, 245.472656 * k)
    ..lineTo(185.156250 * k, 245.472656 * k)
    ..cubicTo(183.378906 * k, 245.472656 * k, 182.781250 * k, 244.992188 * k, 182.371094 * k, 243.277344 * k)
    ..cubicTo(182.125000 * k, 242.179688 * k, 182.000000 * k, 241.058594 * k, 181.992188 * k, 239.933594 * k)
    ..cubicTo(181.933594 * k, 238.039062 * k, 181.941406 * k, 236.140625 * k, 181.781250 * k, 234.253906 * k)
    ..cubicTo(181.425781 * k, 231.246094 * k, 180.332031 * k, 228.371094 * k, 178.601562 * k, 225.882812 * k)
    ..cubicTo(176.605469 * k, 222.890625 * k, 174.390625 * k, 220.015625 * k, 172.234375 * k, 217.113281 * k)
    ..cubicTo(168.820312 * k, 212.679688 * k, 166.617188 * k, 207.441406 * k, 165.828125 * k, 201.906250 * k)
    ..cubicTo(164.507812 * k, 192.117188 * k, 167.445312 * k, 183.664062 * k, 174.390625 * k, 176.648438 * k)
    ..cubicTo(178.843750 * k, 172.132812 * k, 184.601562 * k, 169.128906 * k, 190.851562 * k, 168.058594 * k)
    ..cubicTo(204.113281 * k, 165.484375 * k, 217.542969 * k, 171.644531 * k, 224.242188 * k, 183.375000 * k)
    ..cubicTo(226.992188 * k, 188.179688 * k, 228.277344 * k, 193.683594 * k, 227.933594 * k, 199.210938 * k)
    ..close()
    ..moveTo(231.796875 * k, 191.476562 * k)
    ..cubicTo(230.863281 * k, 186.351562 * k, 228.734375 * k, 181.523438 * k, 225.578125 * k, 177.378906 * k)
    ..cubicTo(219.976562 * k, 169.867188 * k, 211.621094 * k, 164.890625 * k, 202.347656 * k, 163.546875 * k)
    ..cubicTo(197.855469 * k, 162.828125 * k, 193.265625 * k, 162.968750 * k, 188.828125 * k, 163.964844 * k)
    ..cubicTo(183.203125 * k, 165.128906 * k, 177.957031 * k, 167.691406 * k, 173.582031 * k, 171.410156 * k)
    ..cubicTo(164.171875 * k, 179.492188 * k, 159.960938 * k, 189.742188 * k, 161.406250 * k, 202.093750 * k)
    ..cubicTo(162.222656 * k, 208.507812 * k, 164.734375 * k, 214.585938 * k, 168.679688 * k, 219.707031 * k)
    ..cubicTo(170.785156 * k, 222.519531 * k, 172.972656 * k, 225.273438 * k, 174.886719 * k, 228.238281 * k)
    ..cubicTo(176.171875 * k, 230.046875 * k, 177.011719 * k, 232.132812 * k, 177.343750 * k, 234.324219 * k)
    ..cubicTo(177.496094 * k, 235.949219 * k, 177.566406 * k, 237.582031 * k, 177.550781 * k, 239.214844 * k)
    ..cubicTo(177.554688 * k, 240.675781 * k, 177.679688 * k, 242.132812 * k, 177.921875 * k, 243.574219 * k)
    ..cubicTo(178.121094 * k, 244.835938 * k, 178.585938 * k, 246.042969 * k, 179.289062 * k, 247.109375 * k)
    ..cubicTo(180.523438 * k, 248.906250 * k, 182.605469 * k, 249.933594 * k, 184.785156 * k, 249.820312 * k)
    ..lineTo(208.683594 * k, 249.820312 * k)
    ..cubicTo(211.457031 * k, 249.972656 * k, 214.000000 * k, 248.289062 * k, 214.949219 * k, 245.679688 * k)
    ..cubicTo(215.351562 * k, 244.648438 * k, 215.609375 * k, 243.570312 * k, 215.718750 * k, 242.468750 * k)
    ..cubicTo(216.000000 * k, 240.210938 * k, 215.917969 * k, 237.937500 * k, 216.019531 * k, 235.671875 * k)
    ..cubicTo(216.089844 * k, 233.644531 * k, 216.636719 * k, 231.660156 * k, 217.617188 * k, 229.882812 * k)
    ..cubicTo(219.199219 * k, 227.183594 * k, 220.980469 * k, 224.605469 * k, 222.945312 * k, 222.171875 * k)
    ..cubicTo(225.332031 * k, 219.238281 * k, 227.363281 * k, 216.031250 * k, 229.000000 * k, 212.621094 * k)
    ..cubicTo(232.117188 * k, 206.039062 * k, 233.097656 * k, 198.644531 * k, 231.796875 * k, 191.476562 * k)
    ..close();
}

/// The filament's spiral highlight, ported verbatim from `emo-idea.svg`.
Path _filamentSpiral(double k) {
  return Path()
    ..moveTo(195.593750 * k, 175.121094 * k)
    ..cubicTo(200.679688 * k, 175.300781 * k, 205.656250 * k, 176.667969 * k, 210.121094 * k, 179.113281 * k)
    ..cubicTo(216.339844 * k, 182.570312 * k, 220.910156 * k, 188.382812 * k, 222.804688 * k, 195.238281 * k)
    ..cubicTo(223.011719 * k, 195.957031 * k, 223.195312 * k, 196.687500 * k, 223.363281 * k, 197.414062 * k)
    ..cubicTo(223.695312 * k, 198.570312 * k, 223.031250 * k, 199.773438 * k, 221.875000 * k, 200.109375 * k)
    ..cubicTo(221.820312 * k, 200.125000 * k, 221.765625 * k, 200.136719 * k, 221.707031 * k, 200.148438 * k)
    ..cubicTo(220.496094 * k, 200.390625 * k, 219.316406 * k, 199.605469 * k, 219.078125 * k, 198.394531 * k)
    ..cubicTo(219.070312 * k, 198.367188 * k, 219.066406 * k, 198.339844 * k, 219.062500 * k, 198.312500 * k)
    ..cubicTo(218.066406 * k, 193.289062 * k, 215.402344 * k, 188.750000 * k, 211.496094 * k, 185.429688 * k)
    ..cubicTo(208.253906 * k, 182.722656 * k, 204.359375 * k, 180.898438 * k, 200.203125 * k, 180.132812 * k)
    ..cubicTo(198.105469 * k, 179.726562 * k, 195.972656 * k, 179.515625 * k, 193.835938 * k, 179.503906 * k)
    ..cubicTo(192.640625 * k, 179.531250 * k, 191.648438 * k, 178.582031 * k, 191.621094 * k, 177.386719 * k)
    ..lineTo(191.621094 * k, 177.367188 * k)
    ..cubicTo(191.597656 * k, 176.148438 * k, 192.570312 * k, 175.144531 * k, 193.785156 * k, 175.121094 * k)
    ..cubicTo(193.792969 * k, 175.121094 * k, 193.800781 * k, 175.121094 * k, 193.808594 * k, 175.121094 * k)
    ..cubicTo(194.425781 * k, 175.101562 * k, 195.003906 * k, 175.121094 * k, 195.593750 * k, 175.121094 * k)
    ..close();
}

/// The top base/collar bar beneath the bulb, ported verbatim from
/// `emo-idea.svg`.
Path _baseTop(double k) {
  return Path()
    ..moveTo(196.742188 * k, 257.457031 * k)
    ..lineTo(184.765625 * k, 257.457031 * k)
    ..cubicTo(183.578125 * k, 257.496094 * k, 182.578125 * k, 256.562500 * k, 182.539062 * k, 255.375000 * k)
    ..cubicTo(182.523438 * k, 254.941406 * k, 182.640625 * k, 254.515625 * k, 182.871094 * k, 254.152344 * k)
    ..cubicTo(183.332031 * k, 253.417969 * k, 184.164062 * k, 253.003906 * k, 185.027344 * k, 253.085938 * k)
    ..lineTo(208.585938 * k, 253.085938 * k)
    ..cubicTo(209.816406 * k, 253.011719 * k, 210.875000 * k, 253.953125 * k, 210.949219 * k, 255.183594 * k)
    ..cubicTo(210.949219 * k, 255.195312 * k, 210.949219 * k, 255.207031 * k, 210.949219 * k, 255.218750 * k)
    ..cubicTo(210.996094 * k, 256.410156 * k, 210.066406 * k, 257.410156 * k, 208.878906 * k, 257.457031 * k)
    ..cubicTo(208.828125 * k, 257.457031 * k, 208.777344 * k, 257.457031 * k, 208.726562 * k, 257.457031 * k)
    ..close();
}

/// The lower base bar beneath the bulb, ported verbatim from
/// `emo-idea.svg`.
Path _baseBottom(double k) {
  return Path()
    ..moveTo(196.710938 * k, 264.250000 * k)
    ..lineTo(188.726562 * k, 264.250000 * k)
    ..cubicTo(187.519531 * k, 264.308594 * k, 186.496094 * k, 263.378906 * k, 186.437500 * k, 262.171875 * k)
    ..cubicTo(186.378906 * k, 260.964844 * k, 187.312500 * k, 259.937500 * k, 188.519531 * k, 259.878906 * k)
    ..lineTo(204.761719 * k, 259.878906 * k)
    ..cubicTo(205.953125 * k, 259.777344 * k, 207.003906 * k, 260.656250 * k, 207.109375 * k, 261.847656 * k)
    ..cubicTo(207.128906 * k, 262.066406 * k, 207.113281 * k, 262.281250 * k, 207.066406 * k, 262.496094 * k)
    ..cubicTo(206.914062 * k, 263.367188 * k, 206.230469 * k, 264.046875 * k, 205.363281 * k, 264.199219 * k)
    ..cubicTo(205.101562 * k, 264.238281 * k, 204.835938 * k, 264.253906 * k, 204.574219 * k, 264.250000 * k)
    ..close();
}
