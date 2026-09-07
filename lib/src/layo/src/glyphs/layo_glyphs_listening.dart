/// [LayoEmotion.listening]-only glyph: a small vertical-bar audio equalizer,
/// standing in for this emotion's whole face. No separate mouth/eyes are
/// drawn for [LayoEmotion.listening] — the EQ bars are the whole glyph.
///
/// [LayoEmotion.listening] is a from-scratch invention with no `.ai`/SVG
/// source to trace, so every shape here is a plain rounded rect, in the same
/// `396.15`-wide coordinate space every other emotion's glyphs share.
library;

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// How many bars the equalizer draws, and each bar's own resting/oscillation
/// tuning: a per-bar phase offset (in `0..1` cycle fractions) and a relative
/// speed multiplier, both hand-picked (rather than derived from a live
/// [math.Random]) so the animation is fully deterministic given [eqT] alone
/// and each bar reads as bouncing independently rather than in lockstep.
///
/// The offsets are chosen symmetrically around the group's own middle bar
/// (index 2) — bars 0/4 and 1/3 are mirror-image pairs, each pair sharing the
/// same phase offset and speed magnitude — so at `eqT == 0` (and at every
/// other instant, since the pairing holds throughout the loop) the group's
/// own visual weight (taller bars read as "heavier") balances left-to-right
/// around the middle bar instead of clustering toward one side. An earlier,
/// asymmetric set of offsets left the *bounding span* geometrically centered
/// on the screen but put the group's tallest bar at index 1 and its shortest
/// at index 4, which visually reads as the whole cluster leaning left even
/// though [_kBarSpanLeft]/[_kBarSpanRight] were already centered.
const List<(double phaseOffset, double speed)> _kBars = [
  (0.00, 1.05),
  (0.35, 1.20),
  (0.70, 0.90),
  (0.35, 1.20),
  (0.00, 1.05),
];

/// Each bar's fixed horizontal center (in source units), evenly spread across
/// the screen window's own width (`x 78.45-317.04`, see
/// `LayoPainter._screenRect`) and centered on its horizontal midpoint
/// (`(78.45 + 317.04) / 2 = 197.745`) rather than merely the full
/// `396.15`-wide artwork space every other glyph uses — the screen window is
/// this glyph's actual visible canvas, and the two centers are close but not
/// identical.
const double _kBarSpanLeft = 148.745;
const double _kBarSpanRight = 246.745;
const double _kBarWidth = 14.0;

/// The minimum/maximum bar height, in source units.
const double _kBarMinHeight = 14.0;
const double _kBarMaxHeight = 78.0;

/// The equalizer's own vertical baseline (bars grow upward from here), in
/// source units — chosen so the bars' own full possible vertical range (from
/// the baseline itself, where the shortest/`_kBarMinHeight` bars still leave
/// a gap below, up to `_kBarBaselineY - _kBarMaxHeight` at a bar's own
/// tallest) centers on the screen window's own vertical center (`y
/// (123.02 + 308.80) / 2 = 215.91`, see `LayoPainter._screenRect`):
/// `_kBarBaselineY = screenCenterY + _kBarMaxHeight / 2`. An earlier, lower
/// baseline (`235.0`, chosen only to keep the group comfortably inside the
/// screen window) left the group's own vertical range centered well above
/// the screen's own middle instead.
const double _kBarBaselineY = 254.91;

/// Paints [LayoEmotion.listening]'s equalizer: [_kBars.length] vertical
/// rounded bars, evenly spaced and centered on the screen window's own
/// horizontal center, with their own full height range centered on the
/// screen's own vertical center too, each bouncing independently between
/// [_kBarMinHeight] and [_kBarMaxHeight] as [eqT] sweeps `0..1`, looping.
///
/// Each bar's own height is `_kBarMinHeight` plus a sine breath derived from
/// [eqT], its own [_kBars] phase offset, and its own relative speed, so the
/// five bars read as an independently bouncing level meter rather than a
/// single uniform pulse. All bars grow upward from the shared
/// [_kBarBaselineY].
///
/// [canvas] is the target being painted onto. [k] is the uniform scale
/// factor mapping the shared `396.15`-wide coordinate space onto the painted
/// [Size]. [accentColor] fills every bar. [eqT] is the idle bounce phase in
/// `0..1`, looping. [paintSmoothed] is `LayoPainter`'s shared fill+stroke
/// antialiasing helper, threaded through so this free function does not need
/// a `LayoPainter` instance of its own.
void paintListeningGlyph(
  Canvas canvas,
  double k, {
  required Color accentColor,
  required double eqT,
  required void Function(Canvas canvas, Color color, double k, void Function(Paint paint) shapeOnto) paintSmoothed,
}) {
  final t = eqT.clamp(0.0, 1.0);
  final span = _kBarSpanRight - _kBarSpanLeft;
  final gap = _kBars.length > 1 ? span / (_kBars.length - 1) : 0.0;

  for (var i = 0; i < _kBars.length; i++) {
    final (phaseOffset, speed) = _kBars[i];
    final phase = (t * speed + phaseOffset) % 1.0;
    final breath = (math.sin(phase * 2 * math.pi) + 1.0) / 2.0;
    final height = _kBarMinHeight + (_kBarMaxHeight - _kBarMinHeight) * breath;

    final centerX = _kBarSpanLeft + gap * i;
    final rect = Rect.fromLTRB(
      (centerX - _kBarWidth / 2) * k,
      (_kBarBaselineY - height) * k,
      (centerX + _kBarWidth / 2) * k,
      _kBarBaselineY * k,
    );
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(_kBarWidth / 2 * k));
    paintSmoothed(canvas, accentColor, k, (paint) => canvas.drawRRect(rrect, paint));
  }
}
