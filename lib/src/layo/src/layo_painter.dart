import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'glyphs/layo_glyphs_404.dart';
import 'glyphs/layo_glyphs_alert.dart';
import 'glyphs/layo_glyphs_angry.dart';
import 'glyphs/layo_glyphs_dead.dart';
import 'glyphs/layo_glyphs_idea.dart';
import 'glyphs/layo_glyphs_love.dart';
import 'glyphs/layo_glyphs_mr_layo.dart';
import 'glyphs/layo_glyphs_question.dart';
import 'glyphs/layo_glyphs_sleep.dart';
import 'layo_emotion.dart';

/// Paints the Layo brand mascot's face onto a canvas of an arbitrary [Size],
/// for whichever [LayoEmotion] it is configured with.
///
/// Every shape is a verbatim port of the artist's own vector paths, recovered
/// from the source `.ai` files (converted to SVG, `viewBox 0 0 396.15
/// 659.76`, one file per emotion). Each SVG path command carries the exact
/// coordinates from its source file; nothing here is re-derived as an
/// ellipse, rounded rect, or polygon approximation where the source is a
/// freeform Bézier path — most notably the body and the bow-tie, which are
/// single continuous curved shapes in the original artwork. See DESIGN-67
/// Phase 1 (the original [LayoEmotion.mrLayo]-only painter) and the
/// subsequent emotion-driven refactor that produced this file.
///
/// All coordinates are scaled uniformly by [_kOf], mapping the SVG's
/// `396.15`-wide coordinate space onto the painted [Size] (aspect ratio
/// 500:833 ≈ 396.15:659.76 — the same ratio, since the PNG export and the
/// vector source describe the same artwork at different nominal sizes).
///
/// # Shared base vs. per-emotion glyphs
///
/// Every [LayoEmotion] shares one base drawn identically regardless of
/// [emotion] — body (outer, inner) → face shadow (a translucent black
/// rounded rect cast by the head onto the body) → **bow-tie** → dark screen
/// → antenna stalk → ears → light head shell (drawn after the ears, screen,
/// and shadow so it clips their inner halves, leaving only the ears'
/// outward-facing halves, the screen's own window, and a thin sliver of the
/// shadow visible) → antenna tip. [paint] draws that shared base first, then
/// dispatches to the current [emotion]'s own glyph-paint functions (see
/// [_paintEmotionGlyphs]) for whatever varies:
///
/// * The **bow-tie** is worn by every [LayoEmotion] — "Layo is a gentleman,
///   he keeps his tie whatever his mood" — drawn between the shared shadow
///   and the shared screen, matching the original [LayoEmotion.mrLayo]-only
///   painter's draw order, since the source artwork's tie sits on top of the
///   shadow and behind the screen/head-shell. It is part of the shared base
///   ([paint] calls it unconditionally), not an emotion-gated glyph. Its base
///   color is [_antennaTipColor] — the same per-emotion accent as the
///   antenna dot, not the raw [accentColor] field — so a grey-antenna
///   emotion also wears a grey tie, with [paintMrLayoTie]'s own
///   [tieFoldColor] deriving the crease-fold shade from whichever accent
///   that resolves to.
/// * The **screen glyph(s)** (mouth and/or eyes, or their emotion-specific
///   stand-ins) are drawn after the shared head shell, on top of the dark
///   screen window it exposes.
/// * The **antenna-tip color** is blue for [LayoEmotion.mrLayo] and
///   [LayoEmotion.question]; [LayoEmotion.sleep] and [LayoEmotion.dead] use
///   the shared grey glyph color instead (see [_antennaTipColor]).
///
/// Two other elements are deliberately drawn *after* the face shadow so they
/// occlude it, rather than the other way around:
///
/// * The **head shell** covers the shadow's top: the shadow rect (top 280,
///   bottom 339.15) starts well above the shell's own opaque bottom edge
///   (329.55, from [_paintHeadShell]), so only the sliver from 329.55 to
///   339.15 — a thin band right at the head/body join — ever survives to
///   the canvas.
/// * The **tie** (every emotion, see above) covers the shadow's middle: the
///   tie's top cusp reaches up into the shadow's visible band (both occupy
///   the same x-range in the middle of the body), and the reference PNG
///   confirms the tie sits on top there — the band is visible only to its
///   left and right, not underneath it. Painting the tie after the shadow
///   reproduces that; the reverse order let the shadow paint over the tie's
///   shoulders instead, which is wrong.
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
/// # Animation
///
/// Every animated value is driven externally by [Layo]'s state and defaults
/// to its at-rest value, so a default-constructed painter still reproduces
/// each emotion's static look exactly:
///
/// * [pulseT] — the idle antenna-tip pulse/glow. Plays for
///   [LayoEmotion.mrLayo], [LayoEmotion.question], [LayoEmotion.sleep],
///   [LayoEmotion.angry], and [LayoEmotion.layo404]. **Not**
///   [LayoEmotion.dead], [LayoEmotion.love], or [LayoEmotion.idea] (see
///   [_pulses] for why each of those three drives the antenna dot from its
///   own emotion-specific animation instead).
/// * [blinkT] — the eye blink, `0` (open) to `1` (closed). Only makes visual
///   sense for an emotion whose "eyes" are actual open/closed circles —
///   [LayoEmotion.mrLayo] alone — so [_isBlinkable] gates it off for every
///   other emotion, each of which renders static eyes regardless of
///   [blinkT].
/// * [wiggleT] — [LayoEmotion.question] only: a gentle rotational sway
///   applied to each "?" glyph independently, standing in for that emotion's
///   blink (its "eyes" are the question marks themselves, so it wiggles
///   instead of blinking — see [paintQuestionEyes]).
/// * [zzzPhase] — [LayoEmotion.sleep] only: a staggered opacity pulse across
///   the three "zzz" glyphs, so they read as fading in and out in sequence
///   (see [paintSleepZzz]).
/// * [droopT] — [LayoEmotion.dead] only: the antenna's current tilt, in
///   `0..1`, where `1` is this emotion's **resting** pose — drooped, tilted
///   down, no separate animation ever plays to reach it, it is simply where
///   a dead antenna sits — and `0` is fully upright. [droopT] defaults to
///   `1.0` (the resting droop), not `0.0`, since a dead antenna is never
///   upright at rest; a default-constructed [LayoEmotion.dead] painter
///   therefore already shows the drooped pose. [Layo] periodically animates
///   [droopT] briefly *down* from `1` toward (not all the way to) upright and
///   back — a short "failed twitch", as if the antenna tried to rise and
///   lost power — on the same kind of jittered per-instance schedule as
///   [LayoEmotion.mrLayo]'s blink, not a continuous loop (see
///   [_paintAntennaStalk] and [_paintAntennaTip]). Replaces the looping
///   [pulseT] this emotion otherwise never receives, and applies no opacity
///   change of any kind — only the tilt.
/// * [beatT] — [LayoEmotion.love] only: a looping double-thump "heartbeat"
///   phase applied to both heart eyes and, in sync, the antenna dot (see
///   [paintLoveEyes] and [_paintAntennaTip]).
/// * [burstT] — [LayoEmotion.angry] only: a jittered "furrow + tremble"
///   burst phase, `0` at rest, applied to the brows and a whole-glyph shake
///   (see [paintAngryGlyphs]).
/// * [alertPulseT] — [LayoEmotion.alert] only: a snappy top-widening
///   attention-pulse phase applied to both "!" stems (an inverted-triangle
///   funnel silhouette at the beat's peak), leaving the dots in place (see
///   [paintAlertGlyphs]).
/// * [glitchOpacity] and [glitchOffset] — [LayoEmotion.layo404] only: an
///   occasional opacity-drop-plus-jitter "glitch" applied to the whole "404"
///   glyph group (see [paint404Glyphs]).
/// * [glowT] and [flashT] — [LayoEmotion.idea] only: a continuous glow
///   breath plus an occasional stronger "insight" flash applied to the bulb
///   and, in sync, the antenna dot (see [paintIdeaGlyphs] and
///   [_paintAntennaTip]).
///
/// Every animation parameter defaults so a default-constructed painter is
/// unchanged, and [shouldRepaint] ignores each parameter's diff for the
/// emotions it does not apply to — see that method's own doc comment.
class LayoPainter extends CustomPainter {
  /// Creates a new [LayoPainter].
  ///
  /// All colors default to the artist's exact fills; they are exposed as
  /// fields (rather than hardcoded constants) so a caller can vary them
  /// without touching the drawing logic itself.
  const LayoPainter({
    this.emotion = LayoEmotion.mrLayo,
    this.bodyOuterColor = const Color(0xFFEAE9EA),
    this.bodyInnerColor = const Color(0xFFD4D2D3),
    this.screenColor = const Color(0xFF302F44),
    this.accentColor,
    this.glyphColor = const Color(0xFF848484),
    this.faceShadowColor = const Color(0x54000000),
    this.pulseT = 0.0,
    this.blinkT = 0.0,
    this.wiggleT = 0.0,
    this.zzzPhase = 0.0,
    this.droopT = 1.0,
    this.beatT = 0.0,
    this.burstT = 0.0,
    this.alertPulseT = 0.0,
    this.glitchOpacity = 1.0,
    this.glitchOffset = 0.0,
    this.glowT = 0.0,
    this.flashT = 0.0,
  });

  /// Which face this painter draws: the shared base (including the bow-tie,
  /// worn by every emotion) is always the same, but the antenna-tip color
  /// and the screen glyph(s) vary by [emotion]. See the class doc comment for
  /// the full per-emotion breakdown.
  final LayoEmotion emotion;

  /// Fill color for the outer body shell and the light head shell (the
  /// mascot's light plastic casing).
  final Color bodyOuterColor;

  /// Fill color for the inner body panel, the ears, and the antenna stalk
  /// (the mid-grey recessed plastic).
  final Color bodyInnerColor;

  /// Fill color for the dark face screen and the bow-tie's outline (worn by
  /// every [emotion]).
  final Color screenColor;

  /// The accent color used for the antenna tip and every colored screen
  /// glyph, for whichever [emotion] does not use [glyphColor]'s neutral grey
  /// instead (see [_antennaTipColor]).
  ///
  /// Optional: when left `null` (the default), [_resolvedAccentColor]
  /// derives the correct accent from [emotion] itself — blue
  /// (`0xFF60ABDE`) for [LayoEmotion.mrLayo] and [LayoEmotion.question], red
  /// (`0xFFCC2222`) for [LayoEmotion.love], crimson (`0xFFC62828`) for
  /// [LayoEmotion.angry], orange (`0xFFFF9800`) for [LayoEmotion.alert], and
  /// yellow (`0xFFF5CC24`) for [LayoEmotion.idea] — so every caller gets each
  /// emotion's correct accent without needing to know its exact value.
  /// Passing an explicit color here overrides that per-emotion default
  /// uniformly, for every one of those emotions at once.
  ///
  /// [LayoEmotion.sleep] and [LayoEmotion.dead] use [glyphColor] instead for
  /// their own glyphs and antenna tip, and, correspondingly, for the
  /// bow-tie's own base color too: the tie (worn by every [emotion]) is
  /// colored from [_antennaTipColor], not from this field directly, so it
  /// always matches whichever accent the current emotion's antenna dot is
  /// using.
  final Color? accentColor;

  /// Resolves [accentColor] to a concrete color: the explicit value when the
  /// caller supplied one, otherwise [emotion]'s own canonical accent. See
  /// [accentColor]'s doc comment for the full per-emotion default table.
  Color get _resolvedAccentColor {
    final explicit = accentColor;
    if (explicit != null) return explicit;

    switch (emotion) {
      case LayoEmotion.mrLayo:
      case LayoEmotion.question:
        return const Color(0xFF60ABDE);
      case LayoEmotion.love:
        return const Color(0xFFCC2222);
      case LayoEmotion.angry:
        return const Color(0xFFC62828);
      case LayoEmotion.alert:
        return const Color(0xFFFF9800);
      case LayoEmotion.idea:
        return const Color(0xFFF5CC24);
      case LayoEmotion.sleep:
      case LayoEmotion.dead:
      case LayoEmotion.layo404:
        return glyphColor;
    }
  }

  /// Fill color for every screen glyph (and the antenna tip) on
  /// [LayoEmotion.sleep] and [LayoEmotion.dead] — the mascot's neutral grey,
  /// used for [LayoEmotion.sleep]'s closed eyes/mouth/zzz and
  /// [LayoEmotion.dead]'s "X" eyes.
  final Color glyphColor;

  /// Fill color for the face shadow: the dark rounded rect the head casts
  /// onto the body. Drawn translucent, not blurred — the shadow's edges are
  /// as crisp as everything else in this painter; its "soft" look comes
  /// entirely from most of it being covered by the head shell and the tie
  /// (worn by every [emotion]), leaving only a thin, evenly-toned band.
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
  /// glow ring behind it whose size and opacity track the same phase. Plays
  /// for [LayoEmotion.mrLayo], [LayoEmotion.question], and
  /// [LayoEmotion.sleep] — **not** [LayoEmotion.dead], which ignores this
  /// value entirely and animates [droopT] instead (see [_paintAntennaTip]).
  /// Defaults to `0.0` (at rest), so a default-constructed [LayoPainter]
  /// reproduces each emotion's original static tip exactly — no glow, no
  /// radius change.
  final double pulseT;

  /// The eye-blink phase, in `0..1`, where `0` is fully open and `1` is fully
  /// closed.
  ///
  /// Only applied when [_isBlinkable] is `true` for [emotion] — currently
  /// [LayoEmotion.mrLayo] alone — where it squashes the eye shapes vertically
  /// toward a thin ellipse and back rather than switching between two
  /// discrete shapes. Ignored for [LayoEmotion.question] (which animates
  /// [wiggleT] instead), [LayoEmotion.sleep], and [LayoEmotion.dead], whose
  /// eyes render static regardless of this value. Defaults to `0.0` (open),
  /// so a default-constructed [LayoPainter] reproduces [LayoEmotion.mrLayo]'s
  /// original circular eyes exactly.
  final double blinkT;

  /// [LayoEmotion.question]'s idle "?" wiggle phase, in `0..1`, looping.
  ///
  /// Interpreted the same way as a sine-eased sway: [paintQuestionEyes] maps
  /// it to a small rotation (a few degrees) applied around each glyph's own
  /// approximate center, with the two glyphs offset slightly out of phase so
  /// they do not swing in lockstep. This replaces the eye-blink for
  /// [LayoEmotion.question] — its "eyes" are the question marks themselves,
  /// so [_isBlinkable] excludes it and this field animates instead. Ignored
  /// by every other [emotion]. Defaults to `0.0` (no rotation), so a
  /// default-constructed [LayoPainter] reproduces [LayoEmotion.question]'s
  /// original static glyphs exactly.
  final double wiggleT;

  /// [LayoEmotion.sleep]'s idle "zzz" fade phase, in `0..1`, looping.
  ///
  /// [paintSleepZzz] derives a staggered opacity for each of the three "zzz"
  /// glyphs from this single phase (offsetting each glyph's own phase
  /// slightly), so they read as fading in and out in sequence rather than
  /// all three pulsing in unison. Purely an opacity effect — no motion or
  /// scale is applied. Ignored by every other [emotion]. Defaults to `0.0`,
  /// so a default-constructed [LayoPainter] reproduces [LayoEmotion.sleep]'s
  /// original static, fully-opaque "zzz" glyphs exactly.
  final double zzzPhase;

  /// [LayoEmotion.dead]'s antenna tilt, in `0..1`, where `1` is this
  /// emotion's **resting** pose (fully drooped) and `0` is fully upright.
  ///
  /// Unlike every other animated field on this painter, [droopT]'s default
  /// is not the "unanimated" extreme — it defaults to `1.0`, since
  /// [LayoEmotion.dead]'s antenna is drooped at rest, with no separate
  /// animation ever required to reach that pose. [Layo] periodically drives
  /// this value briefly *down* from `1` toward (not all the way to) `0` and
  /// back — a short "failed twitch", as if the antenna tried to rise and
  /// lost power — on a jittered per-instance schedule, the same shape as
  /// [LayoEmotion.mrLayo]'s blink, rather than a continuous loop.
  /// [_paintAntennaStalk] and [_paintAntennaTip] use it to tilt the antenna
  /// stalk/tip only — no opacity change of any kind is applied — replacing
  /// the looping [pulseT] this emotion otherwise never receives. Ignored by
  /// every other [emotion]. A default-constructed [LayoPainter] with
  /// `emotion: LayoEmotion.dead` therefore already renders the resting
  /// drooped antenna, with no twitch in progress.
  final double droopT;

  /// [LayoEmotion.love]'s idle "heartbeat" phase, in `0..1`, looping.
  ///
  /// [paintLoveEyes] derives a double-thump scale envelope from this phase
  /// (see `heartbeatScaleFor`), applied to each heart eye independently
  /// around its own center, and [_paintAntennaTip] applies the same envelope
  /// to the antenna tip's radius so the dot beats in sync with the eyes
  /// instead of playing the generic [pulseT] breath. Ignored by every other
  /// [emotion]. Defaults to `0.0` (no bump), so a default-constructed
  /// [LayoPainter] reproduces [LayoEmotion.love]'s original static hearts
  /// exactly.
  final double beatT;

  /// [LayoEmotion.angry]'s idle "furrow + tremble" burst phase, in `0..1`,
  /// `0` at rest between bursts.
  ///
  /// [paintAngryGlyphs] derives both the brow furrow (translate + rotate
  /// inward) and a high-frequency horizontal tremble of the whole glyph
  /// group from this single phase, both easing in and back out across one
  /// burst's `0..1` sweep. Ignored by every other [emotion]. Defaults to
  /// `0.0` (relaxed, no shake), so a default-constructed [LayoPainter]
  /// reproduces [LayoEmotion.angry]'s original static brows and mouth
  /// exactly.
  final double burstT;

  /// [LayoEmotion.alert]'s idle top-widening attention-pulse phase, in
  /// `0..1`, `0` at rest.
  ///
  /// [paintAlertGlyphs] derives a sharp, snappy (easeOutBack-style) envelope
  /// from this phase and widens each "!" glyph's stem *only at its top
  /// edge*, tapering back to the stem's normal narrow width at the bottom —
  /// an inverted-triangle/funnel silhouette at the beat's peak — rather than
  /// scaling the whole glyph uniformly; the dot stays at its resting
  /// geometry throughout. Deliberately different from
  /// [LayoEmotion.question]'s gentle sine wiggle. Ignored by every other
  /// [emotion]. Defaults to `0.0` (at rest), so a default-constructed
  /// [LayoPainter] reproduces [LayoEmotion.alert]'s original static "!!"
  /// glyphs exactly.
  final double alertPulseT;

  /// [LayoEmotion.layo404]'s idle glitch/flicker opacity, in `0..1`, `1.0` at
  /// rest (fully opaque, static).
  ///
  /// [paint404Glyphs] applies this directly as the "404" glyph group's
  /// alpha; a brief flicker burst drops it toward a low value for a few
  /// frames before returning to `1.0`. Ignored by every other [emotion].
  /// Defaults to `1.0` (fully visible), so a default-constructed
  /// [LayoPainter] reproduces [LayoEmotion.layo404]'s original static digits
  /// exactly.
  final double glitchOpacity;

  /// [LayoEmotion.layo404]'s idle glitch horizontal jitter, in source units
  /// (pre-[_kOf] scale), `0.0` at rest.
  ///
  /// [paint404Glyphs] applies this as a small horizontal translation of the
  /// whole "404" glyph group, in sync with [glitchOpacity]'s flicker, so the
  /// digits read as a broken/no-signal display rather than merely dimming.
  /// Ignored by every other [emotion]. Defaults to `0.0` (no jitter).
  final double glitchOffset;

  /// [LayoEmotion.idea]'s idle continuous glow-pulse phase, in `0..1`,
  /// looping.
  ///
  /// [paintIdeaGlyphs] derives a sine-eased "breath" from this phase (the
  /// same shape as the antenna's own [pulseT] breath) driving a soft,
  /// low-alpha glow ring behind the bulb and a gentle brightness lift on the
  /// bulb's fill. Ignored by every other [emotion]. Defaults to `0.0` (no
  /// glow, base brightness), so a default-constructed [LayoPainter]
  /// reproduces [LayoEmotion.idea]'s original static bulb exactly.
  final double glowT;

  /// [LayoEmotion.idea]'s occasional stronger "insight" flash phase, in
  /// `0..1`, `0` between flashes.
  ///
  /// [paintIdeaGlyphs] layers a brighter spike (both the glow ring and the
  /// bulb fill's own brightness) on top of whatever [glowT] is doing, and
  /// [_paintAntennaTip] syncs the antenna dot to the same flash rather than
  /// the generic [pulseT] breath. Ignored by every other [emotion]. Defaults
  /// to `0.0` (no flash in progress).
  final double flashT;

  /// The uniform scale factor mapping the SVG source's `396.15`-wide
  /// coordinate space onto a painted [Size] of the given [width].
  double _kOf(double width) => width / 396.15;

  /// Whether [emotion]'s eyes are "blinkable" — i.e. drawn as open/closed
  /// shapes that make sense to animate through [blinkT].
  ///
  /// `true` for [LayoEmotion.mrLayo] alone (circular eyes). `false` for every
  /// other [emotion]: [LayoEmotion.question] (its question-mark glyphs
  /// animate via [wiggleT] instead — an eye-blink does not make sense for a
  /// glyph shaped like a "?"), [LayoEmotion.sleep] (already-closed lines —
  /// blinking closed eyes reads as wrong), [LayoEmotion.dead]
  /// (already-crossed "X" marks, same reasoning), and [LayoEmotion.love],
  /// [LayoEmotion.angry], [LayoEmotion.alert], [LayoEmotion.layo404], and
  /// [LayoEmotion.idea] (none of whose "eyes" are open/closed shapes at all —
  /// hearts, brows, "!!", digits, and a bulb respectively — each plays its
  /// own listed idle animation instead of a blink).
  bool get _isBlinkable => emotion == LayoEmotion.mrLayo;

  /// Whether [emotion] plays the looping idle antenna pulse ([pulseT]).
  ///
  /// `true` for [LayoEmotion.mrLayo], [LayoEmotion.question],
  /// [LayoEmotion.sleep], [LayoEmotion.angry], and [LayoEmotion.layo404].
  /// `false` for [LayoEmotion.dead] (a dead robot still pulsing its antenna
  /// reads as "still sending a signal", which contradicts the emotion, so it
  /// renders its resting drooped antenna via [droopT] instead — see
  /// [_paintAntennaTip]), [LayoEmotion.love] (its dot follows the heartbeat,
  /// [beatT], instead), and [LayoEmotion.idea] (its dot follows the bulb
  /// flash, [flashT], instead) — each of those three drives the antenna dot
  /// from its own emotion-specific animation rather than the generic pulse.
  bool get _pulses => emotion != LayoEmotion.dead && emotion != LayoEmotion.love && emotion != LayoEmotion.idea;

  /// The antenna-tip dot's fill color for the current [emotion], before any
  /// [droopT] dimming is applied: [_resolvedAccentColor] for
  /// [LayoEmotion.mrLayo], [LayoEmotion.question], [LayoEmotion.love],
  /// [LayoEmotion.angry], [LayoEmotion.alert], and [LayoEmotion.idea] (each
  /// of these carries its own colored accent — blue, blue, red, crimson,
  /// orange, and yellow respectively); [glyphColor] (grey) for
  /// [LayoEmotion.sleep], [LayoEmotion.dead], and [LayoEmotion.layo404] —
  /// verified directly against the per-emotion source SVGs.
  ///
  /// [_resolvedAccentColor] already falls back to [glyphColor] for the grey
  /// emotions, so this getter simply delegates to it.
  Color get _antennaTipColor => _resolvedAccentColor;

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
  /// indirection lets one helper cover every shape type this painter (and
  /// the per-emotion glyph functions it delegates to) draws.
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
    paintMrLayoTie(canvas, k, outlineColor: screenColor, accentColor: _antennaTipColor, paintSmoothed: _paintSmoothed);
    _paintScreen(canvas, k);
    _paintAntennaStalk(canvas, k);
    _paintEars(canvas, k);
    _paintHeadShell(canvas, k);
    _paintEmotionGlyphs(canvas, k);
    _paintAntennaTip(canvas, k);
  }

  /// Dispatches to the current [emotion]'s screen glyph-paint functions
  /// (mouth and/or eyes, or their emotion-specific stand-ins), applying
  /// [blinkT] only where [_isBlinkable] allows it, [wiggleT] for
  /// [LayoEmotion.question], and [zzzPhase] for [LayoEmotion.sleep]'s "zzz".
  void _paintEmotionGlyphs(Canvas canvas, double k) {
    switch (emotion) {
      case LayoEmotion.mrLayo:
        paintMrLayoMouth(canvas, k, accentColor: _resolvedAccentColor, paintSmoothed: _paintSmoothed);
        paintMrLayoEyes(canvas, k, accentColor: _resolvedAccentColor, blinkT: blinkT, paintSmoothed: _paintSmoothed);
      case LayoEmotion.question:
        paintQuestionEyes(
          canvas,
          k,
          accentColor: _resolvedAccentColor,
          wiggleT: wiggleT,
          paintSmoothed: _paintSmoothed,
        );
      case LayoEmotion.sleep:
        paintSleepEyes(canvas, k, glyphColor: glyphColor, paintSmoothed: _paintSmoothed);
        paintSleepMouth(canvas, k, glyphColor: glyphColor, paintSmoothed: _paintSmoothed);
        paintSleepZzz(canvas, k, glyphColor: glyphColor, zzzPhase: zzzPhase, paintSmoothed: _paintSmoothed);
      case LayoEmotion.dead:
        paintDeadEyes(canvas, k, glyphColor: glyphColor, paintSmoothed: _paintSmoothed);
      case LayoEmotion.love:
        paintLoveEyes(canvas, k, accentColor: _resolvedAccentColor, beatT: beatT, paintSmoothed: _paintSmoothed);
      case LayoEmotion.angry:
        paintAngryGlyphs(
          canvas,
          k,
          accentColor: _resolvedAccentColor,
          burstT: burstT,
          paintSmoothed: _paintSmoothed,
        );
      case LayoEmotion.alert:
        paintAlertGlyphs(
          canvas,
          k,
          accentColor: _resolvedAccentColor,
          pulseT: alertPulseT,
          paintSmoothed: _paintSmoothed,
        );
      case LayoEmotion.layo404:
        paint404Glyphs(
          canvas,
          k,
          glyphColor: glyphColor,
          glitchOpacity: glitchOpacity,
          glitchOffset: glitchOffset,
          paintSmoothed: _paintSmoothed,
        );
      case LayoEmotion.idea:
        // Clipped to the dark screen's own rect so the bulb's glow ring
        // (which grows well beyond the bulb's own geometry at a strong
        // "insight" flash) can never spill onto the head shell or body --
        // the light stays enclosed behind the screen glass, like every
        // other emotion's glyphs.
        canvas.save();
        canvas.clipRect(_screenRect(k));
        paintIdeaGlyphs(
          canvas,
          k,
          accentColor: _resolvedAccentColor,
          glowT: glowT,
          flashT: flashT,
          paintSmoothed: _paintSmoothed,
        );
        canvas.restore();
    }
  }

  /// Paints the outer body dome and the inner recessed body panel.
  ///
  /// Both are single closed cubic-Bézier paths ported verbatim from the
  /// source SVG (`fill="rgb(91.8%, 91.4%, 91.8%)"` and
  /// `rgb(83.1%, 82.4%, 82.7%)` respectively). Shared unchanged across every
  /// [emotion].
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

  /// Paints the face shadow: a translucent rounded rect the head casts onto
  /// the body, most of which is occluded by the head shell and (for
  /// [LayoEmotion.mrLayo]) the tie — both drawn later in [paint] — leaving
  /// only a thin band visible to either side of where the tie would sit,
  /// right at the head/body join. See the class doc comment for why this
  /// draws *before* both of them rather than after.
  ///
  /// The rect's top (280) sits comfortably above the head shell's own
  /// bottom edge (329.55, from [_paintHeadShell]) so the shell's opaque fill
  /// fully covers it there; its bottom (339.15) and its left/right span
  /// (102.69–293.45) are chosen to match the visible band measured directly
  /// off the reference PNG. No fill+stroke smoothing here (unlike this
  /// file's other curved shapes): a translucent shadow must not carry a
  /// crisp same-color edge, which would show through as a hard outline
  /// right where the low alpha is meant to read as flat and quiet. Shared
  /// unchanged across every [emotion].
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

  /// The dark face screen's own rect, in the painted [Size]'s coordinate
  /// space, at the given scale [k].
  ///
  /// Shared between [_paintScreen] (which fills it) and
  /// [_paintEmotionGlyphs] (which clips [LayoEmotion.idea]'s glow/flash to
  /// it, so the bulb's light never spills onto the head or body outside the
  /// screen window) -- a single source of the screen's exact bounds so the
  /// two can never drift apart.
  Rect _screenRect(double k) => Rect.fromLTRB(78.45 * k, 123.02 * k, 317.04 * k, 308.80 * k);

  /// Paints the dark face screen.
  ///
  /// This is a plain axis-aligned rect (its rounded appearance comes from the
  /// head shell's cutout drawn over it) with no curved edges of its own, so
  /// it only needs antialiasing enabled, not the fill+stroke smoothing this
  /// file applies to curved shapes. Shared unchanged across every [emotion].
  void _paintScreen(Canvas canvas, double k) {
    final rect = _screenRect(k);
    canvas.drawRect(
      rect,
      Paint()
        ..color = screenColor
        ..isAntiAlias = true,
    );
  }

  /// Paints the mid-grey antenna stalk, a thin spike from the head to the
  /// antenna tip. Shared across every [emotion], except that
  /// [LayoEmotion.dead] tilts it by [droopT] (see [_paintAntennaTip] for the
  /// matching tip tilt) around the stalk's base pivot at the head, where it
  /// is anchored — `(197.66 * k, 108.84 * k)`, the shared endpoint of both
  /// diagonal edges in the path below. At [droopT]'s default of `1.0` this
  /// renders the resting drooped tilt; a twitch briefly lowers [droopT]
  /// toward (not to) `0` and back, easing the stalk part-way toward upright
  /// and letting it fall again.
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

    final paint = Paint()
      ..color = bodyInnerColor
      ..isAntiAlias = true;

    if (emotion != LayoEmotion.dead || droopT <= 0.0) {
      canvas.drawPath(path, paint);
      return;
    }

    final pivot = Offset(197.66 * k, 108.84 * k);
    canvas.save();
    canvas.translate(pivot.dx, pivot.dy);
    canvas.rotate(_kDroopAngle * droopT.clamp(0.0, 1.0));
    canvas.translate(-pivot.dx, -pivot.dy);
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  /// Paints the two mid-grey ear half-lozenges, drawn before the light head
  /// shell so only their outward-facing halves remain visible once the
  /// shell paints over their flat inner sides. Shared unchanged across every
  /// [emotion].
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
  /// matching the artist's own draw order. Shared unchanged across every
  /// [emotion].
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

  /// Paints the antenna tip dot, in [_antennaTipColor] for the current
  /// [emotion], animated one of two mutually-exclusive ways:
  ///
  /// * Every [emotion] but [LayoEmotion.dead] ([_pulses] is `true`) breathes
  ///   gently with [pulseT]: a soft, low-alpha glow ring is drawn first,
  ///   behind the tip, its radius and opacity tracking a sine easing of
  ///   [pulseT] (peaking at `pulseT == 0.5`); the tip itself is then drawn on
  ///   top at its base radius scaled by a small ±5%, following the same sine
  ///   curve. At `pulseT == 0` both terms are at rest — zero-radius
  ///   (invisible) glow and exactly the original base radius — so a
  ///   default-constructed painter reproduces the original static dot.
  /// * [LayoEmotion.dead] instead ignores [pulseT] entirely (no glow, ever,
  ///   and no opacity change of any kind) and tilts the tip by [droopT]
  ///   around the same pivot and by the same rotation as the antenna stalk
  ///   in [_paintAntennaStalk], so the two move as one rigid piece. At
  ///   [droopT]'s default of `1.0` this renders the resting drooped tilt;
  ///   [Layo]'s periodic "failed twitch" briefly lowers [droopT] toward (not
  ///   to) `0` and back.
  /// * [LayoEmotion.love] ignores [pulseT] and instead scales the tip by the
  ///   same double-thump heartbeat envelope as its heart eyes (derived from
  ///   [beatT]), so the dot beats in sync with the eyes rather than
  ///   following the generic breath.
  /// * [LayoEmotion.idea] ignores [pulseT] and instead syncs to its bulb's
  ///   own glow ([glowT]) and flash ([flashT]): a soft glow ring plus a
  ///   gentle radius lift from [glowT], with [flashT] layering a brighter,
  ///   larger spike on top at an "insight" flash's peak.
  void _paintAntennaTip(Canvas canvas, double k) {
    final center = Offset(197.66 * k, 17.30 * k);
    const baseRadius = 16.71;
    final color = _antennaTipColor;

    if (emotion == LayoEmotion.dead) {
      final pivot = Offset(197.66 * k, 108.84 * k);
      final t = droopT.clamp(0.0, 1.0);

      canvas.save();
      canvas.translate(pivot.dx, pivot.dy);
      canvas.rotate(_kDroopAngle * t);
      canvas.translate(-pivot.dx, -pivot.dy);
      _paintSmoothed(canvas, color, k, (paint) => canvas.drawCircle(center, baseRadius * k, paint));
      canvas.restore();
      return;
    }

    if (emotion == LayoEmotion.love) {
      final scale = heartbeatScaleFor(beatT);
      _paintSmoothed(canvas, color, k, (paint) => canvas.drawCircle(center, baseRadius * scale * k, paint));
      return;
    }

    if (emotion == LayoEmotion.idea) {
      final breath = math.sin(glowT.clamp(0.0, 1.0) * math.pi);
      final flash = flashT.clamp(0.0, 1.0);

      final glowAlpha = 0.22 * breath + 0.35 * flash;
      if (glowAlpha > 0.0) {
        final glowRadius = baseRadius * (1.0 + 0.9 * breath + 1.4 * flash) * k;
        canvas.drawCircle(
          center,
          glowRadius,
          Paint()
            ..color = color.withValues(alpha: glowAlpha.clamp(0.0, 1.0))
            ..style = PaintingStyle.fill
            ..isAntiAlias = true,
        );
      }

      final tipRadius = baseRadius * (1.0 + 0.05 * breath + 0.15 * flash) * k;
      _paintSmoothed(canvas, color, k, (paint) => canvas.drawCircle(center, tipRadius, paint));
      return;
    }

    final breath = math.sin(pulseT.clamp(0.0, 1.0) * math.pi);

    final glowRadius = baseRadius * (1.0 + 0.9 * breath) * k;
    if (glowRadius > baseRadius * k) {
      canvas.drawCircle(
        center,
        glowRadius,
        Paint()
          ..color = color.withValues(alpha: 0.28 * breath)
          ..style = PaintingStyle.fill
          ..isAntiAlias = true,
      );
    }

    final tipRadius = baseRadius * (1.0 + 0.05 * breath) * k;
    _paintSmoothed(canvas, color, k, (paint) => canvas.drawCircle(center, tipRadius, paint));
  }

  @override
  bool shouldRepaint(LayoPainter oldDelegate) {
    return emotion != oldDelegate.emotion ||
        bodyOuterColor != oldDelegate.bodyOuterColor ||
        bodyInnerColor != oldDelegate.bodyInnerColor ||
        screenColor != oldDelegate.screenColor ||
        accentColor != oldDelegate.accentColor ||
        glyphColor != oldDelegate.glyphColor ||
        faceShadowColor != oldDelegate.faceShadowColor ||
        (pulseT != oldDelegate.pulseT && _pulses) ||
        (blinkT != oldDelegate.blinkT && _isBlinkable) ||
        (wiggleT != oldDelegate.wiggleT && emotion == LayoEmotion.question) ||
        (zzzPhase != oldDelegate.zzzPhase && emotion == LayoEmotion.sleep) ||
        (droopT != oldDelegate.droopT && emotion == LayoEmotion.dead) ||
        (beatT != oldDelegate.beatT && emotion == LayoEmotion.love) ||
        (burstT != oldDelegate.burstT && emotion == LayoEmotion.angry) ||
        (alertPulseT != oldDelegate.alertPulseT && emotion == LayoEmotion.alert) ||
        (glitchOpacity != oldDelegate.glitchOpacity && emotion == LayoEmotion.layo404) ||
        (glitchOffset != oldDelegate.glitchOffset && emotion == LayoEmotion.layo404) ||
        (glowT != oldDelegate.glowT && emotion == LayoEmotion.idea) ||
        (flashT != oldDelegate.flashT && emotion == LayoEmotion.idea);
  }
}

/// The tilt [LayoEmotion.dead]'s antenna droops through at [droopT]'s
/// resting value of `1.0`, in radians -- roughly 22 degrees, enough to read
/// clearly as "drooping" without the tip swinging implausibly far from the
/// head. Scaled linearly by [LayoPainter.droopT] as [Layo]'s periodic twitch
/// briefly eases it toward (not to) upright and back.
const double _kDroopAngle = 0.38;
