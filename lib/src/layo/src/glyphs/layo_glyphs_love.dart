/// [LayoEmotion.love]-only glyphs: two heart shapes standing in for this
/// emotion's eyes. No mouth is drawn for [LayoEmotion.love].
///
/// Every shape here is a verbatim port of the artist's own vector paths from
/// `emo-love.svg` (same `396.15`-wide source space as the mascot's other
/// emotions), scaled uniformly by the same `k` factor `LayoPainter` derives
/// from the painted [Size]. The source artwork's own heart red is overridden
/// by the caller's `accentColor` (this emotion's bright red accent), rather
/// than hardcoding the source fill.
library;

import 'package:flutter/widgets.dart';

/// The peak scale each heart (and, in sync, the antenna dot) reaches at the
/// main beat of the idle "heartbeat" pulse -- a ~12% grow, subtle enough to
/// read as a pulse rather than a distracting jump.
const double _kBeatPeakScale = 0.12;

/// The peak scale of the heartbeat's smaller second "thump", following the
/// main beat -- roughly half the main beat's amplitude, so the rhythm reads
/// as two distinct beats (lub-dub) rather than one pulse repeated twice.
const double _kBeatSecondaryScale = 0.06;

/// Where in the `0..1` heartbeat cycle the main beat peaks.
const double _kBeatPrimaryPeak = 0.18;

/// Where in the `0..1` heartbeat cycle the smaller secondary thump peaks.
const double _kBeatSecondaryPeak = 0.42;

/// The half-width (in phase units) of each beat's gaussian-like bump, tuned
/// so both thumps read as short, sharp pulses with quiet rest in between --
/// matching a real heartbeat's rhythm rather than a smooth continuous sine.
const double _kBeatWidth = 0.09;

/// Derives the current heartbeat scale multiplier from [beatT] (`0..1`,
/// looping): a double-thump envelope built from two raised, narrow bumps (see
/// [_kBeatPrimaryPeak] and [_kBeatSecondaryPeak]) rather than a single smooth
/// sine, so the motion reads as "lub-dub" rather than one simple pulse.
/// Returns `1.0` (no scale change) between beats.
double _heartbeatScale(double beatT) {
  final t = beatT.clamp(0.0, 1.0);
  double bump(double peak, double amplitude) {
    final d = (t - peak).abs();
    if (d >= _kBeatWidth) return 0.0;
    final x = d / _kBeatWidth;
    return amplitude * (1.0 - x * x) * (1.0 - x * x);
  }

  final envelope = bump(_kBeatPrimaryPeak, _kBeatPeakScale) + bump(_kBeatSecondaryPeak, _kBeatSecondaryScale);
  return 1.0 + envelope;
}

/// Public helper so [Layo]/`LayoPainter` can derive the antenna dot's own
/// scale from the same heartbeat envelope the hearts use, keeping the dot
/// perfectly in sync with the eyes rather than approximating it separately.
double heartbeatScaleFor(double beatT) => _heartbeatScale(beatT);

/// Paints the two red heart-shaped eyes for [LayoEmotion.love], each scaling
/// in place (pivoting around its own center) with the shared heartbeat
/// envelope derived from [beatT].
///
/// Left heart spans roughly `x 126-190`, right heart spans `x 203-268`, both
/// around `y 163-250` in the source SVG. Ported verbatim from `emo-love.svg`
/// -- geometry only; the source's own red fill is replaced by [accentColor]
/// so this emotion's accent color governs both glyphs.
///
/// [canvas] is the target being painted onto. [k] is the uniform scale
/// factor mapping the SVG source's `396.15`-wide coordinate space onto the
/// painted [Size]. [accentColor] fills both hearts. [beatT] is the idle
/// heartbeat phase in `0..1`, looping; `1.0` (no bump) renders each heart at
/// its exact original, unscaled geometry. [paintSmoothed] is `LayoPainter`'s
/// shared fill+stroke antialiasing helper, threaded through so this free
/// function does not need a `LayoPainter` instance of its own.
void paintLoveEyes(
  Canvas canvas,
  double k, {
  required Color accentColor,
  required double beatT,
  required void Function(Canvas canvas, Color color, double k, void Function(Paint paint) shapeOnto) paintSmoothed,
}) {
  final scale = _heartbeatScale(beatT);

  final leftCenter = Offset(158 * k, 206.5 * k);
  canvas.save();
  canvas.translate(leftCenter.dx, leftCenter.dy);
  canvas.scale(scale, scale);
  canvas.translate(-leftCenter.dx, -leftCenter.dy);
  _paintLeftHeart(canvas, k, accentColor: accentColor, paintSmoothed: paintSmoothed);
  canvas.restore();

  final rightCenter = Offset(235.5 * k, 206.5 * k);
  canvas.save();
  canvas.translate(rightCenter.dx, rightCenter.dy);
  canvas.scale(scale, scale);
  canvas.translate(-rightCenter.dx, -rightCenter.dy);
  _paintRightHeart(canvas, k, accentColor: accentColor, paintSmoothed: paintSmoothed);
  canvas.restore();
}

/// Paints the left heart shape. Geometry ported verbatim from
/// `emo-love.svg`.
void _paintLeftHeart(
  Canvas canvas,
  double k, {
  required Color accentColor,
  required void Function(Canvas canvas, Color color, double k, void Function(Paint paint) shapeOnto) paintSmoothed,
}) {
  final path = Path()
    ..moveTo(143.074219 * k, 186.851562 * k)
    ..cubicTo(144.000000 * k, 186.804688 * k, 144.925781 * k, 186.886719 * k, 145.828125 * k, 187.089844 * k)
    ..cubicTo(147.199219 * k, 187.351562 * k, 148.539062 * k, 187.765625 * k, 149.820312 * k, 188.320312 * k)
    ..cubicTo(150.832031 * k, 188.800781 * k, 151.808594 * k, 189.355469 * k, 152.742188 * k, 189.976562 * k)
    ..cubicTo(153.234375 * k, 190.308594 * k, 153.695312 * k, 190.687500 * k, 154.121094 * k, 191.101562 * k)
    ..cubicTo(154.460938 * k, 191.421875 * k, 154.847656 * k, 191.679688 * k, 155.117188 * k, 192.031250 * k)
    ..cubicTo(156.089844 * k, 193.039062 * k, 156.941406 * k, 194.152344 * k, 157.664062 * k, 195.355469 * k)
    ..cubicTo(157.851562 * k, 195.691406 * k, 158.031250 * k, 195.683594 * k, 158.242188 * k, 195.355469 * k)
    ..cubicTo(158.500000 * k, 194.875000 * k, 158.785156 * k, 194.417969 * k, 159.097656 * k, 193.976562 * k)
    ..cubicTo(159.449219 * k, 193.507812 * k, 159.828125 * k, 193.070312 * k, 160.207031 * k, 192.640625 * k)
    ..cubicTo(160.968750 * k, 191.761719 * k, 161.828125 * k, 190.968750 * k, 162.761719 * k, 190.273438 * k)
    ..cubicTo(163.191406 * k, 189.964844 * k, 163.640625 * k, 189.679688 * k, 164.109375 * k, 189.425781 * k)
    ..cubicTo(164.449219 * k, 189.238281 * k, 164.789062 * k, 188.957031 * k, 165.105469 * k, 188.789062 * k)
    ..cubicTo(165.925781 * k, 188.406250 * k, 166.765625 * k, 188.074219 * k, 167.621094 * k, 187.789062 * k)
    ..cubicTo(168.386719 * k, 187.539062 * k, 169.167969 * k, 187.332031 * k, 169.957031 * k, 187.160156 * k)
    ..cubicTo(170.277344 * k, 187.089844 * k, 170.605469 * k, 187.050781 * k, 170.953125 * k, 187.011719 * k)
    ..cubicTo(172.308594 * k, 186.867188 * k, 173.679688 * k, 186.867188 * k, 175.035156 * k, 187.011719 * k)
    ..cubicTo(175.796875 * k, 187.113281 * k, 176.550781 * k, 187.269531 * k, 177.289062 * k, 187.468750 * k)
    ..cubicTo(179.226562 * k, 187.949219 * k, 181.054688 * k, 188.777344 * k, 182.687500 * k, 189.914062 * k)
    ..cubicTo(184.148438 * k, 190.917969 * k, 185.449219 * k, 192.132812 * k, 186.550781 * k, 193.515625 * k)
    ..cubicTo(187.148438 * k, 194.277344 * k, 187.683594 * k, 195.085938 * k, 188.148438 * k, 195.933594 * k)
    ..cubicTo(188.496094 * k, 196.578125 * k, 188.804688 * k, 197.246094 * k, 189.074219 * k, 197.929688 * k)
    ..cubicTo(189.472656 * k, 198.937500 * k, 189.769531 * k, 199.984375 * k, 189.953125 * k, 201.050781 * k)
    ..cubicTo(190.269531 * k, 202.695312 * k, 190.335938 * k, 204.375000 * k, 190.152344 * k, 206.039062 * k)
    ..cubicTo(190.019531 * k, 207.492188 * k, 189.742188 * k, 208.925781 * k, 189.324219 * k, 210.320312 * k)
    ..cubicTo(188.980469 * k, 211.421875 * k, 188.562500 * k, 212.500000 * k, 188.078125 * k, 213.542969 * k)
    ..cubicTo(187.570312 * k, 214.648438 * k, 186.992188 * k, 215.718750 * k, 186.351562 * k, 216.746094 * k)
    ..cubicTo(185.671875 * k, 217.843750 * k, 184.933594 * k, 218.902344 * k, 184.156250 * k, 219.941406 * k)
    ..cubicTo(182.828125 * k, 221.718750 * k, 181.402344 * k, 223.402344 * k, 179.906250 * k, 225.039062 * k)
    ..cubicTo(179.148438 * k, 225.859375 * k, 178.359375 * k, 226.656250 * k, 177.578125 * k, 227.464844 * k)
    ..cubicTo(177.152344 * k, 227.914062 * k, 176.710938 * k, 228.351562 * k, 176.273438 * k, 228.792969 * k)
    ..cubicTo(175.832031 * k, 229.230469 * k, 175.464844 * k, 229.609375 * k, 175.046875 * k, 230.000000 * k)
    ..cubicTo(173.609375 * k, 231.347656 * k, 172.179688 * k, 232.703125 * k, 170.722656 * k, 233.992188 * k)
    ..cubicTo(169.945312 * k, 234.699219 * k, 169.117188 * k, 235.359375 * k, 168.320312 * k, 236.046875 * k)
    ..cubicTo(167.320312 * k, 236.894531 * k, 166.324219 * k, 237.722656 * k, 165.394531 * k, 238.582031 * k)
    ..cubicTo(164.597656 * k, 239.289062 * k, 163.750000 * k, 239.937500 * k, 162.960938 * k, 240.656250 * k)
    ..cubicTo(162.421875 * k, 241.144531 * k, 161.855469 * k, 241.593750 * k, 161.304688 * k, 242.062500 * k)
    ..lineTo(158.089844 * k, 244.796875 * k)
    ..cubicTo(157.921875 * k, 244.937500 * k, 157.773438 * k, 244.796875 * k, 157.664062 * k, 244.746094 * k)
    ..cubicTo(156.984375 * k, 244.199219 * k, 156.324219 * k, 243.628906 * k, 155.667969 * k, 243.062500 * k)
    ..cubicTo(155.007812 * k, 242.492188 * k, 154.121094 * k, 241.773438 * k, 153.363281 * k, 241.066406 * k)
    ..cubicTo(152.851562 * k, 240.617188 * k, 152.363281 * k, 240.199219 * k, 151.816406 * k, 239.738281 * k)
    ..cubicTo(151.097656 * k, 239.101562 * k, 150.339844 * k, 238.492188 * k, 149.609375 * k, 237.863281 * k)
    ..cubicTo(148.351562 * k, 236.792969 * k, 147.117188 * k, 235.707031 * k, 145.878906 * k, 234.628906 * k)
    ..cubicTo(144.640625 * k, 233.550781 * k, 143.683594 * k, 232.632812 * k, 142.605469 * k, 231.636719 * k)
    ..cubicTo(140.886719 * k, 230.050781 * k, 139.230469 * k, 228.414062 * k, 137.617188 * k, 226.746094 * k)
    ..cubicTo(136.765625 * k, 225.878906 * k, 135.988281 * k, 224.949219 * k, 135.152344 * k, 224.070312 * k)
    ..cubicTo(134.257812 * k, 223.070312 * k, 133.417969 * k, 222.027344 * k, 132.636719 * k, 220.937500 * k)
    ..cubicTo(131.937500 * k, 220.031250 * k, 131.250000 * k, 219.113281 * k, 130.640625 * k, 218.164062 * k)
    ..cubicTo(129.796875 * k, 216.957031 * k, 129.035156 * k, 215.699219 * k, 128.355469 * k, 214.394531 * k)
    ..cubicTo(127.652344 * k, 213.027344 * k, 127.070312 * k, 211.601562 * k, 126.621094 * k, 210.132812 * k)
    ..cubicTo(126.132812 * k, 208.605469 * k, 125.859375 * k, 207.023438 * k, 125.800781 * k, 205.421875 * k)
    ..cubicTo(125.800781 * k, 204.921875 * k, 125.671875 * k, 204.425781 * k, 125.703125 * k, 203.933594 * k)
    ..cubicTo(125.738281 * k, 202.855469 * k, 125.855469 * k, 201.781250 * k, 126.050781 * k, 200.722656 * k)
    ..cubicTo(126.230469 * k, 199.882812 * k, 126.468750 * k, 199.054688 * k, 126.757812 * k, 198.246094 * k)
    ..cubicTo(127.203125 * k, 196.957031 * k, 127.812500 * k, 195.726562 * k, 128.566406 * k, 194.585938 * k)
    ..cubicTo(129.347656 * k, 193.398438 * k, 130.277344 * k, 192.316406 * k, 131.328125 * k, 191.363281 * k)
    ..cubicTo(132.113281 * k, 190.636719 * k, 132.964844 * k, 189.992188 * k, 133.875000 * k, 189.437500 * k)
    ..cubicTo(134.785156 * k, 188.886719 * k, 135.738281 * k, 188.410156 * k, 136.726562 * k, 188.007812 * k)
    ..cubicTo(137.621094 * k, 187.675781 * k, 138.539062 * k, 187.414062 * k, 139.472656 * k, 187.230469 * k)
    ..cubicTo(140.652344 * k, 186.964844 * k, 141.863281 * k, 186.835938 * k, 143.074219 * k, 186.851562 * k)
    ..close();
  paintSmoothed(canvas, accentColor, k, (paint) => canvas.drawPath(path, paint));
}

/// Paints the right heart shape (mirroring the left). Geometry ported
/// verbatim from `emo-love.svg`.
void _paintRightHeart(
  Canvas canvas,
  double k, {
  required Color accentColor,
  required void Function(Canvas canvas, Color color, double k, void Function(Paint paint) shapeOnto) paintSmoothed,
}) {
  final path = Path()
    ..moveTo(220.609375 * k, 186.851562 * k)
    ..cubicTo(221.531250 * k, 186.804688 * k, 222.457031 * k, 186.886719 * k, 223.363281 * k, 187.089844 * k)
    ..cubicTo(224.734375 * k, 187.351562 * k, 226.070312 * k, 187.765625 * k, 227.351562 * k, 188.320312 * k)
    ..cubicTo(228.363281 * k, 188.800781 * k, 229.343750 * k, 189.355469 * k, 230.277344 * k, 189.976562 * k)
    ..cubicTo(230.769531 * k, 190.308594 * k, 231.230469 * k, 190.687500 * k, 231.652344 * k, 191.101562 * k)
    ..cubicTo(231.992188 * k, 191.421875 * k, 232.382812 * k, 191.679688 * k, 232.652344 * k, 192.031250 * k)
    ..cubicTo(233.621094 * k, 193.039062 * k, 234.476562 * k, 194.152344 * k, 235.195312 * k, 195.355469 * k)
    ..cubicTo(235.386719 * k, 195.691406 * k, 235.566406 * k, 195.683594 * k, 235.765625 * k, 195.355469 * k)
    ..cubicTo(236.031250 * k, 194.878906 * k, 236.320312 * k, 194.417969 * k, 236.632812 * k, 193.976562 * k)
    ..cubicTo(236.984375 * k, 193.507812 * k, 237.351562 * k, 193.070312 * k, 237.742188 * k, 192.640625 * k)
    ..cubicTo(238.500000 * k, 191.757812 * k, 239.359375 * k, 190.964844 * k, 240.292969 * k, 190.273438 * k)
    ..cubicTo(240.726562 * k, 189.964844 * k, 241.175781 * k, 189.679688 * k, 241.644531 * k, 189.425781 * k)
    ..cubicTo(241.980469 * k, 189.238281 * k, 242.320312 * k, 188.957031 * k, 242.640625 * k, 188.789062 * k)
    ..cubicTo(243.457031 * k, 188.406250 * k, 244.296875 * k, 188.074219 * k, 245.156250 * k, 187.789062 * k)
    ..cubicTo(245.921875 * k, 187.539062 * k, 246.699219 * k, 187.332031 * k, 247.488281 * k, 187.160156 * k)
    ..cubicTo(247.808594 * k, 187.089844 * k, 248.140625 * k, 187.050781 * k, 248.488281 * k, 187.011719 * k)
    ..cubicTo(249.843750 * k, 186.867188 * k, 251.210938 * k, 186.867188 * k, 252.570312 * k, 187.011719 * k)
    ..cubicTo(253.328125 * k, 187.113281 * k, 254.082031 * k, 187.269531 * k, 254.824219 * k, 187.468750 * k)
    ..cubicTo(256.757812 * k, 187.949219 * k, 258.589844 * k, 188.777344 * k, 260.222656 * k, 189.914062 * k)
    ..cubicTo(261.679688 * k, 190.917969 * k, 262.984375 * k, 192.132812 * k, 264.085938 * k, 193.515625 * k)
    ..cubicTo(264.683594 * k, 194.277344 * k, 265.214844 * k, 195.085938 * k, 265.679688 * k, 195.933594 * k)
    ..cubicTo(266.023438 * k, 196.582031 * k, 266.332031 * k, 197.246094 * k, 266.609375 * k, 197.929688 * k)
    ..cubicTo(267.007812 * k, 198.937500 * k, 267.300781 * k, 199.984375 * k, 267.484375 * k, 201.050781 * k)
    ..cubicTo(267.800781 * k, 202.695312 * k, 267.867188 * k, 204.375000 * k, 267.687500 * k, 206.039062 * k)
    ..cubicTo(267.546875 * k, 207.492188 * k, 267.269531 * k, 208.925781 * k, 266.859375 * k, 210.320312 * k)
    ..cubicTo(266.507812 * k, 211.421875 * k, 266.093750 * k, 212.496094 * k, 265.609375 * k, 213.542969 * k)
    ..cubicTo(265.101562 * k, 214.648438 * k, 264.527344 * k, 215.718750 * k, 263.886719 * k, 216.746094 * k)
    ..cubicTo(263.207031 * k, 217.843750 * k, 262.468750 * k, 218.902344 * k, 261.691406 * k, 219.941406 * k)
    ..cubicTo(260.363281 * k, 221.718750 * k, 258.933594 * k, 223.402344 * k, 257.437500 * k, 225.039062 * k)
    ..cubicTo(256.679688 * k, 225.859375 * k, 255.890625 * k, 226.656250 * k, 255.113281 * k, 227.464844 * k)
    ..cubicTo(254.683594 * k, 227.914062 * k, 254.246094 * k, 228.351562 * k, 253.804688 * k, 228.792969 * k)
    ..cubicTo(253.367188 * k, 229.230469 * k, 252.988281 * k, 229.609375 * k, 252.570312 * k, 230.000000 * k)
    ..cubicTo(251.140625 * k, 231.347656 * k, 249.714844 * k, 232.703125 * k, 248.257812 * k, 233.992188 * k)
    ..cubicTo(247.480469 * k, 234.699219 * k, 246.652344 * k, 235.359375 * k, 245.855469 * k, 236.046875 * k)
    ..cubicTo(244.855469 * k, 236.894531 * k, 243.859375 * k, 237.722656 * k, 242.929688 * k, 238.582031 * k)
    ..cubicTo(242.128906 * k, 239.289062 * k, 241.285156 * k, 239.937500 * k, 240.496094 * k, 240.656250 * k)
    ..cubicTo(239.957031 * k, 241.144531 * k, 239.386719 * k, 241.593750 * k, 238.839844 * k, 242.062500 * k)
    ..lineTo(235.625000 * k, 244.796875 * k)
    ..cubicTo(235.457031 * k, 244.937500 * k, 235.304688 * k, 244.796875 * k, 235.195312 * k, 244.746094 * k)
    ..cubicTo(234.515625 * k, 244.199219 * k, 233.859375 * k, 243.628906 * k, 233.199219 * k, 243.062500 * k)
    ..cubicTo(232.542969 * k, 242.492188 * k, 231.652344 * k, 241.773438 * k, 230.894531 * k, 241.066406 * k)
    ..cubicTo(230.386719 * k, 240.617188 * k, 229.898438 * k, 240.199219 * k, 229.347656 * k, 239.738281 * k)
    ..cubicTo(228.628906 * k, 239.101562 * k, 227.871094 * k, 238.492188 * k, 227.144531 * k, 237.863281 * k)
    ..cubicTo(225.886719 * k, 236.792969 * k, 224.648438 * k, 235.707031 * k, 223.410156 * k, 234.628906 * k)
    ..cubicTo(222.171875 * k, 233.550781 * k, 221.214844 * k, 232.632812 * k, 220.140625 * k, 231.636719 * k)
    ..cubicTo(218.421875 * k, 230.050781 * k, 216.765625 * k, 228.414062 * k, 215.148438 * k, 226.746094 * k)
    ..cubicTo(214.300781 * k, 225.878906 * k, 213.523438 * k, 224.949219 * k, 212.683594 * k, 224.070312 * k)
    ..cubicTo(211.765625 * k, 223.089844 * k, 210.898438 * k, 222.054688 * k, 210.089844 * k, 220.980469 * k)
    ..cubicTo(209.390625 * k, 220.070312 * k, 208.691406 * k, 219.152344 * k, 208.093750 * k, 218.203125 * k)
    ..cubicTo(207.257812 * k, 216.996094 * k, 206.496094 * k, 215.734375 * k, 205.820312 * k, 214.433594 * k)
    ..cubicTo(205.117188 * k, 213.066406 * k, 204.535156 * k, 211.640625 * k, 204.082031 * k, 210.171875 * k)
    ..cubicTo(203.597656 * k, 208.644531 * k, 203.320312 * k, 207.062500 * k, 203.265625 * k, 205.460938 * k)
    ..cubicTo(203.265625 * k, 204.964844 * k, 203.136719 * k, 204.464844 * k, 203.164062 * k, 203.976562 * k)
    ..cubicTo(203.199219 * k, 202.894531 * k, 203.316406 * k, 201.824219 * k, 203.515625 * k, 200.761719 * k)
    ..cubicTo(203.695312 * k, 199.921875 * k, 203.929688 * k, 199.097656 * k, 204.210938 * k, 198.289062 * k)
    ..cubicTo(204.664062 * k, 196.996094 * k, 205.277344 * k, 195.765625 * k, 206.027344 * k, 194.625000 * k)
    ..cubicTo(206.812500 * k, 193.441406 * k, 207.742188 * k, 192.355469 * k, 208.792969 * k, 191.402344 * k)
    ..cubicTo(209.574219 * k, 190.675781 * k, 210.425781 * k, 190.031250 * k, 211.335938 * k, 189.476562 * k)
    ..cubicTo(212.269531 * k, 188.910156 * k, 213.250000 * k, 188.417969 * k, 214.261719 * k, 188.007812 * k)
    ..cubicTo(215.152344 * k, 187.671875 * k, 216.070312 * k, 187.414062 * k, 217.003906 * k, 187.230469 * k)
    ..cubicTo(218.187500 * k, 186.964844 * k, 219.394531 * k, 186.835938 * k, 220.609375 * k, 186.851562 * k)
    ..close();
  paintSmoothed(canvas, accentColor, k, (paint) => canvas.drawPath(path, paint));
}
