/// [LayoEmotion.party]-only glyphs: the party hat **overlay** (a plain
/// triangular cone with a couple of festive stripes and a small pom-pom
/// tuft at its tip) and the looping multicolor confetti **background layer**.
///
/// Like [LayoEmotion.money], [LayoEmotion.cool], and [LayoEmotion.christmas],
/// this is a from-scratch invention with no `.ai`/SVG source to trace — every
/// shape here is a plain primitive (a triangle path, small rects, a circle)
/// drawn directly in the same `396.15`-wide coordinate space every other
/// emotion's glyphs share, so it drops into `LayoPainter` unchanged.
/// Deliberately much simpler than [LayoEmotion.christmas]'s own folded Santa
/// hat — a party hat is a plain cone, not a tucked/folded shape — reusing the
/// exact same overlay (`_paintEmotionOverlay`) and backdrop
/// (`_paintEmotionBackdrop`) mechanisms that hat and its snowfall introduced.
library;

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// The party hat's own festive magenta/pink — this emotion's accent color,
/// used for the cone's main body, one of its two stripes, and the confetti's
/// own pink pieces.
const Color kPartyPink = Color(0xFFE91E8C);

/// The party hat's secondary stripe color — a bright festive yellow-gold,
/// alternating with [kPartyPink] on the cone so the hat reads as a simple
/// striped cone rather than a single flat triangle.
const Color kPartyYellow = Color(0xFFFFC400);

/// A near-black outline color, matching [LayoEmotion.christmas]'s own bold
/// cartoon-sticker edge convention — traced around the party hat's cone and
/// pom-pom so both read with the same crisp outline every other overlay in
/// this design system uses.
const Color _kPartyOutline = Color(0xFF1A1A1A);

/// The bold near-black outline stroke traced around the hat's cone and
/// pom-pom, so the whole hat reads with a cartoon-sticker edge — the same
/// technique and stroke width as [LayoEmotion.christmas]'s own hat outline.
Paint _boldOutlinePaint(double k) => Paint()
  ..color = _kPartyOutline
  ..style = PaintingStyle.stroke
  ..strokeWidth = 3.2 * k
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round
  ..isAntiAlias = true;

/// The cone base's own vertical position, in native units — matches
/// [LayoEmotion.christmas]'s own hat brim's own *bottom* edge
/// (`_kHatBrimCenterY + _kHatBrimHalfHeight` = `112.0 + 26.0` in
/// `layo_glyphs_christmas.dart`), not merely its center. A plain triangle's
/// slanted sides only touch the head at its own base row, unlike a full
/// horizontal brim band that fills the whole zone between the head shell's
/// top edge and the screen with color — so this cone needs to sink as deep
/// as the brim's own *lowest* edge to read as equally "seated", leaving the
/// same small sliver of head visible above the screen that
/// [LayoEmotion.christmas]'s own brim leaves. Still well clear of the
/// shared eye-row (`y 195.73`) so the base never paints over the open eyes
/// it sits above.
const double _kHatBaseY = 138.0;

/// The cone base's left/right edges (native units) — spans a wide portion
/// of the head's own flat-top width (the head shell's rounded corners begin
/// at roughly `x 98`/`298`, see `LayoPainter._paintHeadShell`), so the cone
/// reads as a proper wide-based pyramid sitting across the head rather than
/// a narrow spike, closer to how wide [LayoEmotion.christmas]'s own brimmed
/// hat sits (though still short of that brim's own full-width span, since a
/// party hat's base is its own triangle edge, not a separate brim band).
const double _kHatBaseLeftX = 90.0;
const double _kHatBaseRightX = 306.0;

/// The cone's own apex, in native units (up is negative y) — tall enough to
/// read clearly as a party hat, well above the head shell's own top edge.
const Offset _kHatApex = Offset(197.66, -60.0);

/// The pom-pom's own center, sitting right at the cone's apex.
const Offset _kHatPomPomCenter = _kHatApex;

/// The pom-pom's own base radius, in native units, before [pomPomBobT]'s bob
/// is applied.
const double _kPomPomRadius = 15.0;

/// Builds the party hat's own plain triangular cone: a single closed
/// silhouette, base flat across [_kHatBaseY], rising straight to [_kHatApex].
/// Kept as one plain triangle -- deliberately the simplest possible cone
/// shape, unlike [LayoEmotion.christmas]'s own folded/tucked Santa hat.
Path _partyHatConePath(double k) {
  return Path()
    ..moveTo(_kHatBaseLeftX * k, _kHatBaseY * k)
    ..lineTo(_kHatApex.dx * k, _kHatApex.dy * k)
    ..lineTo(_kHatBaseRightX * k, _kHatBaseY * k)
    ..close();
}

/// Paints [LayoEmotion.party]'s party hat **overlay**: a plain wide-based
/// triangular cone/pyramid in [kPartyPink], capped by two horizontal
/// [kPartyYellow] stripes for a festive zigzag-free striped look, with a
/// small pom-pom tuft — gently bobbing on [pomPomBobT] — at its apex. Every
/// shape carries the same bold near-black outline [LayoEmotion.christmas]'s
/// own hat uses.
///
/// Drawn on top of the head shell exactly like [LayoEmotion.comandante]'s
/// beret, `paintCoolSunglasses`, and `paintChristmasHat` (see
/// `LayoPainter`'s "Overlays" section) — this emotion has **no antenna at
/// all** (see `LayoPainter._hasAntenna`), the same reasoning
/// [LayoEmotion.comandante]'s beret and [LayoEmotion.christmas]'s Santa hat
/// both use: the cone's own base sits low enough on the head (see
/// [_kHatBaseY]) that the antenna stalk, which rises from the head's own
/// vertical center, would otherwise poke out through the cone's own body
/// rather than sitting cleanly behind or in front of it.
///
/// [canvas] is the target being painted onto. [k] is the uniform scale
/// factor mapping the shared `396.15`-wide coordinate space onto the painted
/// [Size]. [pomPomBobT] is the pom-pom's own idle bob phase in `0..1`,
/// looping; `0` renders it at its exact resting position. [paintSmoothed] is
/// `LayoPainter`'s shared fill+stroke antialiasing helper, threaded through
/// so this free function does not need a `LayoPainter` instance of its own.
void paintPartyHat(
  Canvas canvas,
  double k, {
  required double pomPomBobT,
  required void Function(Canvas canvas, Color color, double k, void Function(Paint paint) shapeOnto) paintSmoothed,
}) {
  final cone = _partyHatConePath(k);

  paintSmoothed(canvas, kPartyPink, k, (paint) => canvas.drawPath(cone, paint));
  canvas.drawPath(cone, _boldOutlinePaint(k));

  // Two horizontal yellow stripes, clipped to the cone's own silhouette, so
  // the hat reads as festively striped without needing a separate zigzag
  // path -- kept deliberately simple, per this emotion's own "plain cone"
  // brief.
  canvas.save();
  canvas.clipPath(cone);
  for (final stripeCenterY in [_kHatBaseY - 14, _kHatBaseY - 40]) {
    final stripe = Rect.fromLTRB(
      (_kHatBaseLeftX - 4) * k,
      (stripeCenterY - 6) * k,
      (_kHatBaseRightX + 4) * k,
      (stripeCenterY + 6) * k,
    );
    canvas.drawRect(
      stripe,
      Paint()
        ..color = kPartyYellow
        ..isAntiAlias = true,
    );
  }
  canvas.restore();

  // The pom-pom tuft at the apex, gently bobbing on pomPomBobT -- a vertical
  // bob (rather than christmas's own circular sway) since a party hat's tip
  // is a single point, not a drooping fold to drift side to side.
  final bob = math.sin(pomPomBobT.clamp(0.0, 1.0) * math.pi * 2);
  const bobAmplitude = 4.0;
  final pomPomCenter = Offset(
    _kHatPomPomCenter.dx * k,
    (_kHatPomPomCenter.dy - bob * bobAmplitude) * k,
  );
  paintSmoothed(canvas, kPartyYellow, k, (paint) => canvas.drawCircle(pomPomCenter, _kPomPomRadius * k, paint));
  canvas.drawCircle(pomPomCenter, _kPomPomRadius * k, _boldOutlinePaint(k));
}

/// One falling confetti piece's own position, phase, color, and tilt, used
/// by [paintPartyConfetti] to derive a whole confetti fall from a small
/// fixed set of per-piece seeds rather than a live [math.Random] (which would
/// make the backdrop non-deterministic frame to frame and impossible to
/// test) — the same technique [LayoEmotion.money]'s own `_BillSeed` and
/// [LayoEmotion.christmas]'s own `_SnowflakeSeed` use.
class _ConfettiSeed {
  const _ConfettiSeed({
    required this.xFraction,
    required this.phaseOffset,
    required this.speed,
    required this.driftAmplitude,
    required this.tilt,
    required this.spinSpeed,
    required this.color,
    required this.size,
  });

  /// This piece's horizontal position, as a fraction (`0..1`) of the painted
  /// width, before drift is applied.
  final double xFraction;

  /// This piece's own phase offset within the loop, in `0..1`, so pieces do
  /// not all fall in lockstep.
  final double phaseOffset;

  /// This piece's relative fall speed multiplier.
  final double speed;

  /// How far this piece drifts side to side, in logical pixels, as it falls.
  final double driftAmplitude;

  /// This piece's own starting rotation, in radians.
  final double tilt;

  /// This piece's own continuous spin speed, in radians per full loop cycle,
  /// so each rectangle visibly tumbles rather than merely translating.
  final double spinSpeed;

  /// This piece's own fill color — one of a small festive palette (blue,
  /// pink, yellow, green).
  final Color color;

  /// This piece's own rectangle size (width, height), in logical pixels.
  final Size size;
}

/// The festive confetti palette: blue, pink, yellow, and green, cycled across
/// [_kConfettiSeeds] so the fall reads as multicolor rather than a single
/// tint.
const Color _kConfettiBlue = Color(0xFF2979FF);
const Color _kConfettiPink = Color(0xFFE91E8C);
const Color _kConfettiYellow = Color(0xFFFFC400);
const Color _kConfettiGreen = Color(0xFF43A047);

/// A small, fixed set of per-piece seeds driving [paintPartyConfetti] — see
/// [_ConfettiSeed]. Deliberately hand-picked (not generated from a live
/// [math.Random]) so the backdrop is fully deterministic given [confettiT]
/// alone, mirroring [LayoEmotion.christmas]'s own `_kSnowflakeSeeds`.
const List<_ConfettiSeed> _kConfettiSeeds = [
  _ConfettiSeed(
    xFraction: 0.05,
    phaseOffset: 0.00,
    speed: 1.00,
    driftAmplitude: 12,
    tilt: 0.20,
    spinSpeed: 2.4,
    color: _kConfettiBlue,
    size: Size(9, 6),
  ),
  _ConfettiSeed(
    xFraction: 0.15,
    phaseOffset: 0.30,
    speed: 0.85,
    driftAmplitude: 16,
    tilt: -0.40,
    spinSpeed: -1.8,
    color: _kConfettiPink,
    size: Size(7, 7),
  ),
  _ConfettiSeed(
    xFraction: 0.28,
    phaseOffset: 0.55,
    speed: 1.15,
    driftAmplitude: 9,
    tilt: 0.60,
    spinSpeed: 3.1,
    color: _kConfettiYellow,
    size: Size(8, 5),
  ),
  _ConfettiSeed(
    xFraction: 0.40,
    phaseOffset: 0.10,
    speed: 0.90,
    driftAmplitude: 14,
    tilt: -0.25,
    spinSpeed: -2.6,
    color: _kConfettiGreen,
    size: Size(10, 6),
  ),
  _ConfettiSeed(
    xFraction: 0.55,
    phaseOffset: 0.70,
    speed: 1.05,
    driftAmplitude: 18,
    tilt: 0.35,
    spinSpeed: 2.0,
    color: _kConfettiBlue,
    size: Size(6, 6),
  ),
  _ConfettiSeed(
    xFraction: 0.68,
    phaseOffset: 0.20,
    speed: 0.80,
    driftAmplitude: 10,
    tilt: -0.55,
    spinSpeed: -3.4,
    color: _kConfettiYellow,
    size: Size(9, 6),
  ),
  _ConfettiSeed(
    xFraction: 0.80,
    phaseOffset: 0.45,
    speed: 1.10,
    driftAmplitude: 13,
    tilt: 0.15,
    spinSpeed: 2.7,
    color: _kConfettiPink,
    size: Size(8, 7),
  ),
  _ConfettiSeed(
    xFraction: 0.90,
    phaseOffset: 0.85,
    speed: 0.95,
    driftAmplitude: 11,
    tilt: -0.30,
    spinSpeed: -2.1,
    color: _kConfettiGreen,
    size: Size(7, 5),
  ),
  _ConfettiSeed(
    xFraction: 0.02,
    phaseOffset: 0.60,
    speed: 1.20,
    driftAmplitude: 8,
    tilt: 0.45,
    spinSpeed: 3.6,
    color: _kConfettiBlue,
    size: Size(6, 6),
  ),
  _ConfettiSeed(
    xFraction: 0.95,
    phaseOffset: 0.05,
    speed: 0.75,
    driftAmplitude: 15,
    tilt: -0.20,
    spinSpeed: -2.3,
    color: _kConfettiPink,
    size: Size(9, 6),
  ),
  _ConfettiSeed(
    xFraction: 0.35,
    phaseOffset: 0.90,
    speed: 1.00,
    driftAmplitude: 10,
    tilt: 0.50,
    spinSpeed: 2.9,
    color: _kConfettiYellow,
    size: Size(7, 6),
  ),
  _ConfettiSeed(
    xFraction: 0.60,
    phaseOffset: 0.15,
    speed: 0.88,
    driftAmplitude: 12,
    tilt: -0.45,
    spinSpeed: -2.9,
    color: _kConfettiGreen,
    size: Size(8, 6),
  ),
];

/// Paints [LayoEmotion.party]'s idle "confetti" **background layer**: a small
/// fixed set of falling, tumbling, multicolor confetti rectangles, looping
/// and drifting down behind everything else this painter draws.
///
/// Called first, before the body, so nothing here can ever occlude the
/// mascot's own artwork — see `LayoPainter.paint`'s "Background layers"
/// section and [LayoEmotion.christmas]'s own `paintChristmasSnowfall`, which
/// this mirrors closely (down to reusing the same deterministic-seed
/// technique). [LayoPainter] clips this call to its own paint [size] before
/// invoking it, so the confetti never spills past this widget's own box even
/// though conceptually it sits "behind the whole figure".
///
/// Each piece's vertical position loops smoothly from just above the top edge
/// to just below the bottom edge as [confettiT] sweeps `0..1` (its own speed,
/// horizontal position, and drift amplitude fixed per-piece by
/// [_kConfettiSeeds]), with a gentle side-to-side sine drift and a continuous
/// spin layered on top so the fall reads as tumbling confetti rather than
/// uniformly falling rectangles. At `confettiT == 0` every piece still
/// renders at its own phase-appropriate position — there is no "at rest,
/// invisible" pose for a continuous loop, the same way
/// [LayoEmotion.christmas]'s own snowfall has none.
///
/// [canvas] is the target being painted onto. [size] is the full painted box
/// this backdrop fills (not scaled by the shared artwork's own `k`, since the
/// confetti is meant to fill this widget's own bounds regardless of the
/// mascot artwork's aspect ratio within it). [confettiT] is the idle confetti
/// phase in `0..1`, looping.
void paintPartyConfetti(Canvas canvas, Size size, {required double confettiT}) {
  final t = confettiT.clamp(0.0, 1.0);
  final maxPieceExtent = _kConfettiSeeds.map((s) => math.max(s.size.width, s.size.height)).reduce(math.max);
  final travel = size.height + maxPieceExtent * 4;

  for (final seed in _kConfettiSeeds) {
    final phase = (t * seed.speed + seed.phaseOffset) % 1.0;
    final y = -maxPieceExtent * 2 + phase * travel;
    final drift = math.sin(phase * math.pi * 2) * seed.driftAmplitude;
    final x = seed.xFraction * size.width + drift;
    final rotation = seed.tilt + phase * seed.spinSpeed;

    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(rotation);
    final rect = Rect.fromCenter(center: Offset.zero, width: seed.size.width, height: seed.size.height);
    canvas.drawRect(
      rect,
      Paint()
        ..color = seed.color
        ..isAntiAlias = true,
    );
    canvas.restore();
  }
}
