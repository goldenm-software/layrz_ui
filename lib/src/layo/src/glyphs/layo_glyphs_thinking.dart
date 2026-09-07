/// [LayoEmotion.thinking]-only glyph: a thought-bubble cloud plus its
/// trailing connector circles, standing in for this emotion's whole face. No
/// separate mouth/eyes are drawn for [LayoEmotion.thinking] — the bubble is
/// the whole glyph.
///
/// [LayoEmotion.thinking] is a from-scratch invention with no `.ai`/SVG
/// source to trace, so every shape here is drawn as plain primitives (circles
/// composited into a cloud silhouette, plus small standalone circles for the
/// connectors) in the same `396.15`-wide coordinate space every other
/// emotion's glyphs share.
library;

import 'package:flutter/widgets.dart';

/// The cloud's own center and overall size, in source units — comfortably
/// inside the dark screen window (`x 78.45-317.04, y 123.02-308.80`).
const Offset _kCloudCenter = Offset(206, 190);

/// Each lobe making up the cloud silhouette: relative offset from
/// [_kCloudCenter] and radius, in source units — a cluster of overlapping
/// circles is the classic, simplest way to build a puffy cloud/thought-bubble
/// outline without a bespoke Bézier path.
const List<(Offset, double)> _kCloudLobes = [
  (Offset(-32, 10), 22),
  (Offset(-8, -8), 26),
  (Offset(20, 0), 24),
  (Offset(42, 14), 18),
  (Offset(8, 20), 20),
];

/// Each trailing connector circle's own resting offset (relative to
/// [_kCloudCenter]) and radius, smallest/closest-to-the-head first — the
/// classic thought-bubble "leading dots" trail.
const List<(Offset, double)> _kConnectors = [
  (Offset(-52, 62), 6),
  (Offset(-38, 46), 9),
  (Offset(-22, 30), 13),
];

/// How much of the `0..1` [thoughtT] cycle each connector's own pulse
/// occupies before the next one begins — smaller than `1 / connectors.length`
/// so there is a brief pause with nothing pulsing between full sweeps, which
/// reads more clearly as "a thought forming" than an unbroken chain.
const double _kConnectorWindow = 0.22;

/// Derives one connector's own `0..1` bump from the shared [thoughtT] phase
/// and its [index] among [_kConnectors]: `0` outside its own window
/// (rendering at its resting scale/alpha) and a triangular `0->1->0` rise and
/// fall peaking at the window's midpoint while inside it.
double _connectorEnvelope(double thoughtT, int index) {
  final windowStart = index * _kConnectorWindow;
  final local = (thoughtT - windowStart) / _kConnectorWindow;
  if (local < 0.0 || local > 1.0) return 0.0;
  return 1.0 - (2 * local - 1.0).abs();
}

/// Paints [LayoEmotion.thinking]'s thought-bubble cloud (static) plus its
/// three trailing connector circles, which pulse/appear in ascending
/// sequence (smallest and closest to the head first) as [thoughtT] sweeps
/// `0..1`, looping.
///
/// [canvas] is the target being painted onto. [k] is the uniform scale
/// factor mapping the shared `396.15`-wide coordinate space onto the painted
/// [Size]. [accentColor] fills the cloud and every connector — `LayoPainter`
/// passes its own white [LayoEmotion.thinking]-only glyph color here, kept
/// deliberately decoupled from the antenna-tip dot and tie color (which stay
/// blue): the cloud reads cleanly as white against the dark screen window
/// behind it, while a white dot would vanish against the light head shell.
/// [thoughtT] is the idle connector-sequence phase in `0..1`, looping; at any
/// value the cloud itself renders identically (only the connectors animate).
/// [paintSmoothed] is `LayoPainter`'s shared fill+stroke antialiasing helper,
/// threaded through so this free function does not need a `LayoPainter`
/// instance of its own.
void paintThinkingGlyph(
  Canvas canvas,
  double k, {
  required Color accentColor,
  required double thoughtT,
  required void Function(Canvas canvas, Color color, double k, void Function(Paint paint) shapeOnto) paintSmoothed,
}) {
  for (final (offset, radius) in _kCloudLobes) {
    final center = Offset((_kCloudCenter.dx + offset.dx) * k, (_kCloudCenter.dy + offset.dy) * k);
    paintSmoothed(canvas, accentColor, k, (paint) => canvas.drawCircle(center, radius * k, paint));
  }

  final t = thoughtT.clamp(0.0, 1.0);
  for (var i = 0; i < _kConnectors.length; i++) {
    final (offset, radius) = _kConnectors[i];
    final bump = _connectorEnvelope(t, i).clamp(0.0, 1.0);
    // Resting scale/alpha is a modest, always-visible dot; the bump grows
    // and brightens it briefly as "its turn" comes up in the sequence.
    final scale = 0.7 + 0.3 * bump;
    final alpha = 0.45 + 0.55 * bump;

    final center = Offset((_kCloudCenter.dx + offset.dx) * k, (_kCloudCenter.dy + offset.dy) * k);
    paintSmoothed(
      canvas,
      accentColor.withValues(alpha: alpha),
      k,
      (paint) => canvas.drawCircle(center, radius * scale * k, paint),
    );
  }
}
