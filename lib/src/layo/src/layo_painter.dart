import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Paints the "MrLayo" brand mascot face onto a canvas of an
/// arbitrary [Size].
///
/// Every shape is a verbatim port of the artist's own vector paths, recovered
/// from the source `Mr Layo.ai` file (converted to SVG, `viewBox 0 0 396.15
/// 659.76`). Each SVG path command below carries the exact coordinates from
/// that file; nothing here is re-derived as an ellipse, rounded rect, or
/// polygon approximation where the source is a freeform Bézier path — most
/// notably the body and the bow-tie, which are single continuous curved
/// shapes in the original artwork. See DESIGN-67 Phase 1.
///
/// All coordinates are scaled uniformly by [_kOf], mapping the SVG's
/// `396.15`-wide coordinate space onto the painted [Size] (aspect ratio
/// 500:833 ≈ 396.15:659.76 — the same ratio, since the PNG export and the
/// vector source describe the same artwork at different nominal sizes).
///
/// Painting proceeds back-to-front in the artist's own layer order: body
/// (outer, inner) → face shadow (a translucent black rounded rect cast by
/// the head onto the body) → tie (dark outline, then blue fill with its
/// crease details) → dark screen → antenna stalk → ears → light head shell
/// (drawn after the ears, screen, and shadow so it clips their inner
/// halves, leaving only the ears' outward-facing halves, the screen's own
/// window, and a thin sliver of the shadow visible) → mouth → eyes →
/// antenna tip dot.
///
/// Two other elements are deliberately drawn *after* the face shadow so
/// they occlude it, rather than the other way around:
///
/// * The **head shell** covers the shadow's top: the shadow rect (top 280,
///   bottom 339.15) starts well above the shell's own opaque bottom edge
///   (329.55, from [_paintHeadShell]), so only the sliver from 329.55 to
///   339.15 — a thin band right at the head/body join — ever survives to
///   the canvas.
/// * The **tie** covers the shadow's middle: the tie's top cusp reaches up
///   into the shadow's visible band (both occupy the same x-range in the
///   middle of the body), and the reference PNG confirms the tie sits on
///   top there — the band is visible only to its left and right, not
///   underneath it. Painting the tie after the shadow reproduces that; the
///   reverse order let the shadow paint over the tie's shoulders instead,
///   which is wrong.
///
/// An earlier pass of this file got this backwards more than once: first
/// porting the shadow as an opaque, full-height, light-grey rect drawn on
/// top of the screen (read as a hard "chin-strap" bar), then — misreading
/// the fix as "shrink the rect" rather than "fix the draw order" —
/// replacing it with an opaque flat-color sliver sized to the visible band
/// alone (which happened to match the reference at rest, but was never
/// actually a shadow, and painted over the tie rather than under it). The
/// shape that actually reproduces the reference is the original
/// full-height, translucent rect, drawn where the head shell and the tie
/// can both occlude it — not a shape hand-fitted to whatever gap they
/// happen to leave.
///
/// This started as a Phase 1, static-only painter and still draws the single
/// awake face this vector source describes with every shape geometrically
/// identical to that phase — no emotion variants, no dormant-body
/// silhouette. The only animated behavior is a subtle idle antenna pulse
/// ([pulseT]) and eye blink ([blinkT]), both driven externally by [Layo]'s
/// state and defaulting to their at-rest values so a default-constructed
/// painter still reproduces the original static look exactly.
class LayoPainter extends CustomPainter {
  /// Creates a new [LayoPainter].
  ///
  /// All colors default to the artist's exact fills; they are exposed as
  /// fields (rather than hardcoded constants) so a future phase can vary them
  /// per emotion without touching the drawing logic itself.
  const LayoPainter({
    this.bodyOuterColor = const Color(0xFFEAE9EA),
    this.bodyInnerColor = const Color(0xFFD4D2D3),
    this.screenColor = const Color(0xFF302F44),
    this.accentColor = const Color(0xFF60ABDE),
    this.faceShadowColor = const Color(0x54000000),
    this.pulseT = 0.0,
    this.blinkT = 0.0,
  });

  /// Fill color for the outer body shell and the light head shell (the
  /// mascot's light plastic casing).
  final Color bodyOuterColor;

  /// Fill color for the inner body panel, the ears, and the antenna stalk
  /// (the mid-grey recessed plastic).
  final Color bodyInnerColor;

  /// Fill color for the dark face screen and the bow-tie's outline.
  final Color screenColor;

  /// Fill color for the antenna tip, the eyes, the mouth, and the bow-tie's
  /// main fill — the mascot's single accent blue.
  final Color accentColor;

  /// Fill color for the face shadow: the dark rounded rect the head casts
  /// onto the body. Drawn translucent, not blurred — the shadow's edges are
  /// as crisp as everything else in this painter; its "soft" look comes
  /// entirely from most of it being covered by the head shell and the tie
  /// (see the class doc comment), leaving only a thin, evenly-toned band.
  ///
  /// The source `.ai` file builds this via a luminance mask over a dark
  /// (`rgb(26.7%, 27.1%, 27.1%)`) fill at 36% opacity. This default
  /// (`0x54` ≈ 33% alpha, plain black) was tuned directly against the
  /// reference PNG rather than trusting the mask's nominal alpha: sampling
  /// the visible band gives a flat `rgb(160, 156, 157)` over a measured
  /// body color of `rgb(236, 235, 238)`, and `0x54` is the alpha that
  /// reproduces that composite.
  final Color faceShadowColor;

  /// The idle antenna-pulse phase, in `0..1`, looping.
  ///
  /// Interpreted as a sine-eased "breath": `0` and `1` are both the tip at
  /// rest, with the peak of the pulse at `0.5`. [_paintAntennaTip] uses it to
  /// modulate the tip's radius by a few percent and to draw a soft, low-alpha
  /// glow ring behind it whose size and opacity track the same phase.
  /// Defaults to `0.0` (at rest), so a default-constructed [LayoPainter]
  /// reproduces the original static tip exactly — no glow, no radius change.
  final double pulseT;

  /// The eye-blink phase, in `0..1`, where `0` is fully open and `1` is fully
  /// closed.
  ///
  /// [_paintEyes] uses it to squash the eye circles vertically toward a thin
  /// ellipse and back, rather than switching between two discrete shapes.
  /// Defaults to `0.0` (open), so a default-constructed [LayoPainter]
  /// reproduces the original static circular eyes exactly.
  final double blinkT;

  /// The uniform scale factor mapping the SVG source's `396.15`-wide
  /// coordinate space onto a painted [Size] of the given [width].
  double _kOf(double width) => width / 396.15;

  /// Fills [shapeOnto] with [color], then re-traces the same shape with a
  /// thin same-color stroke on top.
  ///
  /// This is an anti-aliasing mitigation for Impeller's Linux backend, which
  /// (unlike Skia) has been observed to leave visibly stair-stepped edges on
  /// curved fills even with [Paint.isAntiAlias] set. A hairline stroke in the
  /// exact same color re-covers that jagged edge with its own antialiased
  /// coverage, softening it — while being effectively invisible on a
  /// renderer whose fill edge was already smooth, since a same-color stroke
  /// only ever repaints pixels the fill already colored (or a sub-pixel
  /// sliver just outside it, blended toward the same color). [strokeWidth]
  /// defaults to `0.6 * k` (`k` = `paintWidth / 396.15`), a fraction of a
  /// logical pixel at the artwork's native size, scaling with the requested
  /// paint size like every other stroke in this file.
  ///
  /// [shapeOnto] receives a [Paint] already configured with the requested
  /// style (fill first, then stroke) and must apply it to the shape (e.g.
  /// via `canvas.drawPath`, `canvas.drawRRect`, `canvas.drawCircle`) — this
  /// indirection lets one helper cover every shape type this painter draws.
  void _paintSmoothed(
    Canvas canvas,
    Color color,
    double k,
    void Function(Paint paint) shapeOnto,
  ) {
    shapeOnto(
      Paint()
        ..color = color
        ..style = PaintingStyle.fill
        ..isAntiAlias = true,
    );
    shapeOnto(
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.6 * k
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final k = _kOf(size.width);

    _paintBody(canvas, k);
    _paintFaceShadow(canvas, k);
    _paintTie(canvas, k);
    _paintScreen(canvas, k);
    _paintAntennaStalk(canvas, k);
    _paintEars(canvas, k);
    _paintHeadShell(canvas, k);
    _paintMouth(canvas, k);
    _paintEyes(canvas, k);
    _paintAntennaTip(canvas, k);
  }

  /// Paints the outer body dome and the inner recessed body panel.
  ///
  /// Both are single closed cubic-Bézier paths ported verbatim from the
  /// source SVG (`fill="rgb(91.8%, 91.4%, 91.8%)"` and
  /// `rgb(83.1%, 82.4%, 82.7%)` respectively).
  void _paintBody(Canvas canvas, double k) {
    final outer = Path()
      ..moveTo(395.30 * k, 553.49 * k)
      ..cubicTo(395.30 * k, 412.90 * k, 306.81 * k, 298.94 * k, 197.66 * k, 298.94 * k)
      ..cubicTo(88.50 * k, 298.94 * k, 0 * k, 412.90 * k, 0 * k, 553.49 * k)
      ..cubicTo(0 * k, 694.08 * k, 395.30 * k, 694.10 * k, 395.30 * k, 553.49 * k)
      ..close();
    _paintSmoothed(canvas, bodyOuterColor, k, (paint) => canvas.drawPath(outer, paint));

    final inner = Path()
      ..moveTo(344.16 * k, 550.26 * k)
      ..cubicTo(346.09 * k, 410.56 * k, 286.93 * k, 323.56 * k, 196.83 * k, 323.64 * k)
      ..cubicTo(106.56 * k, 323.72 * k, 45.04 * k, 422.35 * k, 49.50 * k, 550.26 * k)
      ..cubicTo(53.89 * k, 675.35 * k, 342.43 * k, 675.41 * k, 344.16 * k, 550.26 * k)
      ..close();
    _paintSmoothed(canvas, bodyInnerColor, k, (paint) => canvas.drawPath(inner, paint));
  }

  /// Paints the bow-tie: the dark outline shape first, then the blue fill
  /// (itself a single organic path with small internal crease cusps) on top.
  ///
  /// Both paths are ported verbatim from the source SVG. The outline path is
  /// filled solid (not stroked) — in the source artwork it is itself a
  /// closed region very slightly larger than the blue fill on top of it, so
  /// only a thin sliver of it remains visible as an outline once the fill is
  /// painted over it, exactly reproducing the reference's thin dark edge.
  void _paintTie(Canvas canvas, double k) {
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
    _paintSmoothed(canvas, screenColor, k, (paint) => canvas.drawPath(outline, paint));

    final fill = Path()
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
      ..close()
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
    _paintSmoothed(canvas, accentColor, k, (paint) => canvas.drawPath(fill, paint));
  }

  /// Paints the face shadow: a translucent rounded rect the head casts onto
  /// the body, most of which is occluded by the head shell and the tie —
  /// both drawn later in [paint] — leaving only a thin band visible to
  /// either side of the tie, right at the head/body join. See the class
  /// doc comment for why this draws *before* both of them rather than
  /// after.
  ///
  /// The rect's top (280) sits comfortably above the head shell's own
  /// bottom edge (329.55, from [_paintHeadShell]) so the shell's opaque fill
  /// fully covers it there; its bottom (339.15) and its left/right span
  /// (102.69–293.45) are chosen to match the visible band measured directly
  /// off the reference PNG, and its middle is covered by the tie painted
  /// immediately after it. No fill+stroke smoothing here (unlike this
  /// file's other curved shapes): a translucent shadow must not carry a
  /// crisp same-color edge, which would show through as a hard outline
  /// right where the low alpha is meant to read as flat and quiet.
  void _paintFaceShadow(Canvas canvas, double k) {
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTRB(102.69 * k, 280 * k, 293.45 * k, 339.15 * k),
      Radius.circular(5.73 * k),
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = faceShadowColor
        ..isAntiAlias = true,
    );
  }

  /// Paints the dark face screen.
  ///
  /// This is a plain axis-aligned rect (its rounded appearance comes from the
  /// head shell's cutout drawn over it) with no curved edges of its own, so
  /// it only needs antialiasing enabled, not the fill+stroke smoothing this
  /// file applies to curved shapes.
  void _paintScreen(Canvas canvas, double k) {
    final rect = Rect.fromLTRB(78.45 * k, 123.02 * k, 317.04 * k, 308.80 * k);
    canvas.drawRect(
      rect,
      Paint()
        ..color = screenColor
        ..isAntiAlias = true,
    );
  }

  /// Paints the mid-grey antenna stalk, a thin spike from the head to the
  /// antenna tip.
  void _paintAntennaStalk(Canvas canvas, double k) {
    final path = Path()
      ..moveTo(197.93 * k, 0.59 * k)
      ..lineTo(197.79 * k, 1.88 * k)
      ..lineTo(197.66 * k, 0.59 * k)
      ..lineTo(197.66 * k, 3.15 * k)
      ..lineTo(186.51 * k, 108.84 * k)
      ..lineTo(209.06 * k, 108.84 * k)
      ..lineTo(197.93 * k, 3.15 * k)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..color = bodyInnerColor
        ..isAntiAlias = true,
    );
  }

  /// Paints the two mid-grey ear half-lozenges, drawn before the light head
  /// shell so only their outward-facing halves remain visible once the
  /// shell paints over their flat inner sides.
  void _paintEars(Canvas canvas, double k) {
    final left = Path()
      ..moveTo(66.12 * k, 244.95 * k)
      ..cubicTo(49.68 * k, 244.95 * k, 36.35 * k, 228.23 * k, 36.35 * k, 207.60 * k)
      ..cubicTo(36.35 * k, 186.98 * k, 49.68 * k, 170.22 * k, 66.12 * k, 170.22 * k)
      ..cubicTo(82.55 * k, 170.22 * k, 82.56 * k, 244.95 * k, 66.12 * k, 244.95 * k)
      ..close();
    _paintSmoothed(canvas, bodyInnerColor, k, (paint) => canvas.drawPath(left, paint));

    final right = Path()
      ..moveTo(329.38 * k, 244.95 * k)
      ..cubicTo(345.82 * k, 244.95 * k, 359.15 * k, 228.23 * k, 359.15 * k, 207.60 * k)
      ..cubicTo(359.15 * k, 186.98 * k, 345.82 * k, 170.22 * k, 329.38 * k, 170.22 * k)
      ..cubicTo(312.93 * k, 170.22 * k, 312.93 * k, 244.95 * k, 329.38 * k, 244.95 * k)
      ..close();
    _paintSmoothed(canvas, bodyInnerColor, k, (paint) => canvas.drawPath(right, paint));
  }

  /// Paints the light head shell: an outer rounded-rect ring whose inner
  /// edge is cut out by the screen window, using the even-odd fill rule so
  /// the two nested rounded rects combine into a single ring shape rather
  /// than one rect painting over the other.
  ///
  /// Painted after the ears and the screen, its opaque ring covers the
  /// ears' inner halves and the screen's outer margin, leaving only the
  /// ears' outward-facing halves and the screen's own window visible —
  /// matching the artist's own draw order.
  void _paintHeadShell(Canvas canvas, double k) {
    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(61.43 * k, 98.89 * k, 334.07 * k, 329.55 * k),
          Radius.circular(36.5 * k),
        ),
      )
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(86.52 * k, 129.52 * k, 308.98 * k, 298.95 * k),
          Radius.circular(23.7 * k),
        ),
      );
    _paintSmoothed(canvas, bodyOuterColor, k, (paint) => canvas.drawPath(path, paint));
  }

  /// Paints the blue smile: a single cubic-Bézier path with a straight-ish
  /// top edge and a bulging bottom edge, ported verbatim rather than
  /// approximated as a rounded rect or ellipse.
  void _paintMouth(Canvas canvas, double k) {
    final path = Path()
      ..moveTo(252.58 * k, 237.40 * k)
      ..cubicTo(252.58 * k, 250.54 * k, 228.11 * k, 261.20 * k, 197.93 * k, 261.20 * k)
      ..cubicTo(167.74 * k, 261.20 * k, 143.27 * k, 250.54 * k, 143.27 * k, 237.40 * k)
      ..cubicTo(143.27 * k, 224.26 * k, 252.58 * k, 224.26 * k, 252.58 * k, 237.40 * k)
      ..close();
    _paintSmoothed(canvas, accentColor, k, (paint) => canvas.drawPath(path, paint));
  }

  /// Paints the two blue eyes, at their exact source radius and centers,
  /// vertically squashed by [blinkT].
  ///
  /// At rest (`blinkT == 0`) each eye is drawn as the original circle via
  /// [Canvas.drawCircle]. Mid-blink, the eye becomes a vertically-scaled
  /// ellipse — `scaleY` runs from `1.0` (open) down toward `0.1` (all but
  /// closed) and back as [blinkT] sweeps `0 -> 1 -> 0` over the blink's
  /// short lifetime — drawn by scaling the canvas around the eye's own
  /// center rather than by constructing a new shape, so the same
  /// [_paintSmoothed] fill+stroke smoothing still applies unchanged.
  void _paintEyes(Canvas canvas, double k) {
    final leftCenter = Offset(134.67 * k, 195.73 * k);
    final rightCenter = Offset(261.17 * k, 195.73 * k);
    const radiusFraction = 15.57;

    if (blinkT <= 0.0) {
      _paintSmoothed(canvas, accentColor, k, (paint) => canvas.drawCircle(leftCenter, radiusFraction * k, paint));
      _paintSmoothed(canvas, accentColor, k, (paint) => canvas.drawCircle(rightCenter, radiusFraction * k, paint));
      return;
    }

    const minScaleY = 0.1;
    final scaleY = 1.0 - (1.0 - minScaleY) * blinkT.clamp(0.0, 1.0);

    for (final center in [leftCenter, rightCenter]) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.scale(1.0, scaleY);
      canvas.translate(-center.dx, -center.dy);
      _paintSmoothed(canvas, accentColor, k, (paint) => canvas.drawCircle(center, radiusFraction * k, paint));
      canvas.restore();
    }
  }

  /// Paints the blue antenna tip dot, breathing gently with [pulseT].
  ///
  /// A soft, low-alpha glow ring is drawn first, behind the tip: its radius
  /// and opacity both track a sine easing of [pulseT] (peaking at
  /// `pulseT == 0.5`) so it swells and fades with the same breath. The tip
  /// itself is then drawn on top at its base radius scaled by a small ±5%,
  /// following the same sine curve. At `pulseT == 0` both terms are at rest
  /// — zero-radius (invisible) glow and exactly the original base radius —
  /// so a default-constructed painter reproduces the original static dot.
  void _paintAntennaTip(Canvas canvas, double k) {
    final center = Offset(197.66 * k, 17.30 * k);
    const baseRadius = 16.71;

    final breath = math.sin(pulseT.clamp(0.0, 1.0) * math.pi);

    final glowRadius = baseRadius * (1.0 + 0.9 * breath) * k;
    if (glowRadius > baseRadius * k) {
      canvas.drawCircle(
        center,
        glowRadius,
        Paint()
          ..color = accentColor.withValues(alpha: 0.28 * breath)
          ..style = PaintingStyle.fill
          ..isAntiAlias = true,
      );
    }

    final tipRadius = baseRadius * (1.0 + 0.05 * breath) * k;
    _paintSmoothed(canvas, accentColor, k, (paint) => canvas.drawCircle(center, tipRadius, paint));
  }

  @override
  bool shouldRepaint(LayoPainter oldDelegate) {
    return bodyOuterColor != oldDelegate.bodyOuterColor ||
        bodyInnerColor != oldDelegate.bodyInnerColor ||
        screenColor != oldDelegate.screenColor ||
        accentColor != oldDelegate.accentColor ||
        faceShadowColor != oldDelegate.faceShadowColor ||
        pulseT != oldDelegate.pulseT ||
        blinkT != oldDelegate.blinkT;
  }
}
