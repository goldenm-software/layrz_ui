import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'layo_emotion.dart';
import 'layo_painter.dart';

/// The "MrLayo" brand mascot, rendered entirely with [CustomPainter] — no
/// bundled image or SVG asset.
///
/// This is deliberately named `Layo`, without the `Layrz` prefix used by the
/// rest of this design system's components: it is a brand asset rather than
/// a themeable UI primitive (see decision D11 in `engineering/decisions.md`).
///
/// [Layo] draws the static face for its configured [emotion], traced from the
/// reference artwork, and — when [animate] is `true` and the platform is not
/// asking for reduced motion — layers small idle animations on top of it so
/// the mascot reads as alive rather than a still image. Which animations play
/// depends on [emotion] (see [LayoPainter] for the full per-emotion
/// breakdown):
///
/// * A gentle antenna-tip pulse/glow, for every [emotion] except
///   [LayoEmotion.dead].
/// * A periodic eye blink, for [LayoEmotion.mrLayo] alone.
/// * A gentle "?" wiggle, for [LayoEmotion.question] alone (replacing the
///   blink, since its "eyes" are the question marks themselves).
/// * A staggered "zzz" opacity fade, for [LayoEmotion.sleep] alone.
/// * A recurring "failed twitch" of the antenna, for [LayoEmotion.dead]
///   alone: the antenna rests drooped at all times (that pose is simply
///   where a dead antenna sits, not an animation that plays to reach it),
///   and on a jittered per-instance schedule — the same shape as the blink
///   above, not a continuous loop — it briefly rises part-way toward
///   upright and falls back, as if trying and failing to power back on. No
///   opacity change accompanies this; the antenna stays its normal color
///   throughout.
///
/// Nothing else moves; the silhouette is identical to the static artwork at
/// every frame outside of these specific animated parts, which matters
/// because [Layo] is also used small (~32px) and repeated, e.g. one per
/// message in a chat list.
///
/// Every idle animation is surfaced to a single [AnimatedBuilder] wrapping
/// only the [CustomPaint], so an animating [Layo] repaints just its own paint
/// layer every frame — no ancestor widget rebuilds, and no `setState` is
/// ever called for animation ticks. The looping animations pause (and the
/// blink/twitch timers are cancelled) whenever [TickerMode.valuesOf] reports
/// `enabled: false` for this context, e.g. this [Layo] has scrolled out of
/// view in a list — see [_LayoState._syncAnimating].
///
/// [Layo] is size-automatic: it fills whatever width its parent provides and
/// derives its height from the mascot's fixed [_aspectRatio], so it drops
/// into an [Expanded], a grid cell, or any other bounded box and keeps the
/// original artwork's proportions. When the parent imposes no width bound
/// (for example inside a scrolling [Column]), pass an explicit [width].
class Layo extends StatefulWidget {
  /// Creates a new [Layo] mascot graphic.
  ///
  /// The [width] parameter is optional. When null, [Layo] expands to fill
  /// the width its parent provides and derives its height from the fixed
  /// 500:833 aspect ratio of the original artwork — this requires the parent
  /// to impose a bounded width (e.g. a [SizedBox], an [Expanded] inside a
  /// [Row], or a sized grid cell). When the parent provides no width bound
  /// (for example inside a scrolling [Column] or [Row] with no constraint on
  /// the relevant axis), [AspectRatio] throws, so supply an explicit [width]
  /// in that context instead. Height is always derived from the aspect ratio
  /// and can never be set independently.
  ///
  /// The [animate] parameter is optional and defaults to `true`. When
  /// `true`, [Layo] plays its [emotion]-appropriate idle animations (see the
  /// class doc comment for the full breakdown), automatically pausing while
  /// off-screen (via [TickerMode]) and falling back to the static look when
  /// the platform requests reduced motion (`MediaQuery.disableAnimations`) —
  /// in that case [LayoEmotion.dead] still renders its resting drooped
  /// antenna (that pose is static, not an animation to skip), just with no
  /// twitch ever firing. Pass `false` to force the fully static look
  /// regardless of platform settings — useful for a caller that wants a
  /// still mascot (e.g. a printed/exported view); [LayoEmotion.dead] still
  /// renders drooped in this case too, for the same reason.
  ///
  /// The [emotion] parameter is optional and defaults to
  /// [LayoEmotion.mrLayo], the original default face.
  const Layo({this.width, this.animate = true, this.emotion = LayoEmotion.mrLayo, super.key});

  /// Optional explicit width in logical pixels.
  ///
  /// When null, [Layo] fills the width its parent provides and derives
  /// height from the fixed 500:833 aspect ratio; provide it when [Layo] sits
  /// in an unbounded context (e.g. inside a scrolling [Column]) where the
  /// parent imposes no width.
  final double? width;

  /// Which face [Layo] renders.
  ///
  /// Defaults to [LayoEmotion.mrLayo]. Every [LayoEmotion] shares the same
  /// base artwork (body, face shadow, screen, ears, head shell, bow-tie) and
  /// differs only in the screen glyph(s), the antenna-tip color, and which
  /// idle animations play — see [LayoPainter] for the full breakdown.
  final LayoEmotion emotion;

  /// Whether [Layo] plays its [emotion]-appropriate idle animations.
  ///
  /// Defaults to `true`. Even when `true`, the animations are further gated
  /// by [TickerMode] (paused while an ancestor marks this subtree as not
  /// visible, e.g. scrolled out of view in a list) and by the platform's
  /// reduced-motion preference (`MediaQuery.disableAnimations`), either of
  /// which forces the static look without the caller needing to do
  /// anything. Pass `false` to force the static look unconditionally. In
  /// both cases, [LayoEmotion.dead] still renders its resting drooped
  /// antenna (a static pose, not an animation frame to skip) — only its
  /// recurring "failed twitch" is suppressed.
  final bool animate;

  /// The mascot artwork's fixed width:height aspect ratio, traced from the
  /// original 500×833 reference resource (`mr-layo.png`).
  static const double _aspectRatio = 500 / 833;

  @override
  State<Layo> createState() => _LayoState();
}

/// State for [Layo]: owns every idle-animation controller and rebuilds only
/// the [CustomPaint] beneath an [AnimatedBuilder] each frame, deriving each
/// of [LayoPainter]'s animation parameters from the controller (or fixed
/// value) appropriate to [Layo.emotion].
class _LayoState extends State<Layo> with TickerProviderStateMixin {
  /// Looping controller driving the antenna-tip pulse. Runs a fixed
  /// ~2-second cycle for as long as animation is active via
  /// [AnimationController.repeat]; never restarted or seeked mid-cycle.
  /// Started only for emotions where [_pulses] is true (every emotion but
  /// [LayoEmotion.dead]) — see [_syncAnimating].
  late final AnimationController _pulseController;

  /// Short, non-looping controller driving a single blink's close+open. It
  /// is idle (not animating) between blinks — [_scheduleNextBlink] is what
  /// fires it — so it costs nothing at 60fps outside the ~140ms it is
  /// actually playing.
  late final AnimationController _blinkController;

  /// The blink's own eased value, `0` (open) to `1` (fully closed), derived
  /// from [_blinkController] so the close/reopen each feel like a snap
  /// rather than a linear wipe.
  late final Animation<double> _blinkAnimation;

  /// Looping controller driving [LayoEmotion.question]'s "?" wiggle. Runs a
  /// fixed ~1.8-second cycle via [AnimationController.repeat] for as long as
  /// this instance is animating and its emotion is [LayoEmotion.question].
  late final AnimationController _wiggleController;

  /// Looping controller driving [LayoEmotion.sleep]'s "zzz" fade. Runs a
  /// fixed ~2.8-second cycle via [AnimationController.repeat] for as long as
  /// this instance is animating and its emotion is [LayoEmotion.sleep].
  late final AnimationController _zzzController;

  /// Short, non-looping controller driving a single antenna "failed twitch"
  /// rise+fall, for [LayoEmotion.dead]. Idle (not animating) between
  /// twitches — [_scheduleNextTwitch] is what fires it — exactly mirroring
  /// how [_blinkController] behaves for the blink, so it costs nothing at
  /// 60fps outside the brief window a twitch is actually playing.
  late final AnimationController _twitchController;

  /// The twitch's own eased progress, `0` (fully drooped, at rest) to `1`
  /// (the twitch's momentary peak lift), derived from [_twitchController] so
  /// the rise and fall each feel like an attempt losing power rather than a
  /// linear wipe. [_droopTFor] maps this progress to [LayoPainter.droopT].
  late final Animation<double> _twitchAnimation;

  /// A single [Listenable] merging every controller/animation above, passed
  /// to [AnimatedBuilder.animation] so one listener covers all idle
  /// animations regardless of which ones are actually active for the
  /// current [Layo.emotion].
  late final Listenable _repaint;

  /// Source of the per-blink and per-twitch randomized interval (3-6s), so
  /// this instance's blinks/twitches jitter against every other [Layo] on
  /// screen instead of firing in unison.
  final math.Random _random = math.Random();

  /// Self-scheduling timer for the next blink; recreated after every blink
  /// fires (or when animation resumes after being paused) and cancelled
  /// whenever animation is inactive so nothing fires unseen.
  Timer? _blinkTimer;

  /// Self-scheduling timer for the next antenna twitch; recreated after
  /// every twitch fires (or when animation resumes after being paused) and
  /// cancelled whenever animation is inactive so nothing fires unseen.
  /// Mirrors [_blinkTimer] exactly, for [LayoEmotion.dead] instead of
  /// [LayoEmotion.mrLayo].
  Timer? _twitchTimer;

  /// Whether this instance currently considers itself "animating" — the
  /// combination of [Layo.animate], [TickerMode.valuesOf], and the platform's
  /// reduced-motion preference. Tracked so [didChangeDependencies] and
  /// [didUpdateWidget] only start/stop the tickers and blink/twitch
  /// schedulers on an actual transition, rather than re-deriving and acting
  /// on it unconditionally on every rebuild (which would restart the looping
  /// controllers and re-arm the timers needlessly).
  bool _isAnimating = false;

  /// Whether [Layo.emotion]'s eyes are blinkable — mirrors
  /// [LayoPainter._isBlinkable]. Gates the blink scheduler entirely: for a
  /// non-blinkable emotion (currently every emotion but [LayoEmotion.mrLayo])
  /// no blink timer is ever armed and [_blinkAnimation]'s value stays
  /// structurally at `0`, rather than merely being ignored downstream.
  bool get _isBlinkable => widget.emotion == LayoEmotion.mrLayo;

  /// Whether [Layo.emotion] plays the looping antenna pulse — mirrors
  /// [LayoPainter._pulses]. `false` only for [LayoEmotion.dead], which rests
  /// permanently drooped and twitches instead (see [_isDead]).
  bool get _pulses => widget.emotion != LayoEmotion.dead;

  /// Whether [Layo.emotion] is [LayoEmotion.dead] — gates the twitch
  /// scheduler entirely, exactly as [_isBlinkable] gates the blink scheduler
  /// for [LayoEmotion.mrLayo].
  bool get _isDead => widget.emotion == LayoEmotion.dead;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000));
    _blinkController = AnimationController(vsync: this, duration: const Duration(milliseconds: 140));
    _blinkAnimation = CurvedAnimation(parent: _blinkController, curve: Curves.easeInOut);
    _wiggleController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));
    _zzzController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2800));
    _twitchController = AnimationController(vsync: this, duration: const Duration(milliseconds: 260));
    _twitchAnimation = CurvedAnimation(parent: _twitchController, curve: Curves.easeOut);
    _repaint = Listenable.merge([
      _pulseController,
      _blinkAnimation,
      _wiggleController,
      _zzzController,
      _twitchAnimation,
    ]);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimating();
  }

  @override
  void didUpdateWidget(covariant Layo oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncAnimating();
  }

  /// Recomputes whether this instance should be animating right now and, on
  /// a change, starts or stops every looping controller and the blink/twitch
  /// schedulers.
  ///
  /// This is the single place that reads [Layo.animate], [TickerMode.valuesOf],
  /// and `MediaQuery.disableAnimations` — called from both
  /// [didChangeDependencies] (covers [TickerMode] and [MediaQuery] changes,
  /// e.g. scrolling this widget off/on screen) and [didUpdateWidget] (covers
  /// the caller flipping [Layo.animate] or [Layo.emotion]). The antenna
  /// pulse starts only when animating and [_pulses] is true for the current
  /// emotion; the wiggle and zzz controllers likewise start only when
  /// animating and their own emotion currently applies; the blink scheduler
  /// is armed only when [_isBlinkable] is also true, and the twitch
  /// scheduler only when [_isDead] is true, for the current emotion.
  void _syncAnimating() {
    final reducedMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final shouldAnimate = widget.animate && !reducedMotion && TickerMode.valuesOf(context).enabled;
    final shouldBlink = shouldAnimate && _isBlinkable;
    final wasBlinking = _blinkTimer != null;
    final shouldTwitch = shouldAnimate && _isDead;
    final wasTwitching = _twitchTimer != null;

    if (shouldAnimate != _isAnimating) {
      _isAnimating = shouldAnimate;

      if (shouldAnimate && _pulses) {
        _pulseController.repeat();
      } else {
        _pulseController.stop();
      }

      if (shouldAnimate && widget.emotion == LayoEmotion.question) {
        _wiggleController.repeat();
      } else {
        _wiggleController.stop();
      }

      if (shouldAnimate && widget.emotion == LayoEmotion.sleep) {
        _zzzController.repeat();
      } else {
        _zzzController.stop();
      }
    }

    if (shouldBlink && !wasBlinking) {
      _scheduleNextBlink();
    } else if (!shouldBlink && wasBlinking) {
      _blinkController.stop();
      _blinkController.value = 0;
      _blinkTimer?.cancel();
      _blinkTimer = null;
    }

    if (shouldTwitch && !wasTwitching) {
      _scheduleNextTwitch();
    } else if (!shouldTwitch && wasTwitching) {
      _twitchController.stop();
      _twitchController.value = 0;
      _twitchTimer?.cancel();
      _twitchTimer = null;
    }
  }

  /// Arms a one-shot timer for the next blink, at a randomized 3-6 second
  /// interval so this instance's blinks are jittered against every other
  /// [Layo] on screen instead of firing in unison.
  ///
  /// Every continuation re-checks `mounted`, [_isAnimating], and
  /// [_isBlinkable] before acting, so a timer or an in-flight blink left
  /// over from just before animation was paused (or the emotion switched to
  /// a non-blinkable one, or the widget was disposed) cannot fire a blink,
  /// leave [_blinkController] running, or re-arm the next timer.
  void _scheduleNextBlink() {
    _blinkTimer?.cancel();
    final seconds = 3.0 + _random.nextDouble() * 3.0;
    _blinkTimer = Timer(Duration(milliseconds: (seconds * 1000).round()), () => unawaited(_playBlink()));
  }

  /// Plays one full blink (close then reopen) on [_blinkController] and, if
  /// still animating and blinkable afterward, arms the next
  /// [_scheduleNextBlink].
  ///
  /// Re-checks `mounted`/[_isAnimating]/[_isBlinkable] after each await so a
  /// blink in flight when animation is paused (or the emotion switched away
  /// from a blinkable one, or the widget disposed) neither leaves
  /// [_blinkController] mid-close nor re-arms a further blink.
  Future<void> _playBlink() async {
    await _blinkController.forward(from: 0);
    if (!mounted || !_isAnimating || !_isBlinkable) {
      return;
    }
    await _blinkController.reverse();
    if (!mounted || !_isAnimating || !_isBlinkable) {
      return;
    }
    _scheduleNextBlink();
  }

  /// Arms a one-shot timer for the next antenna twitch, at a randomized 3-6
  /// second interval so this instance's twitches are jittered against every
  /// other [Layo] on screen instead of firing in unison — the same schedule
  /// shape as [_scheduleNextBlink], for [LayoEmotion.dead] instead of
  /// [LayoEmotion.mrLayo].
  ///
  /// Every continuation re-checks `mounted`, [_isAnimating], and [_isDead]
  /// before acting, so a timer or an in-flight twitch left over from just
  /// before animation was paused (or the emotion switched away from dead, or
  /// the widget was disposed) cannot fire a twitch, leave
  /// [_twitchController] running, or re-arm the next timer.
  void _scheduleNextTwitch() {
    _twitchTimer?.cancel();
    final seconds = 3.0 + _random.nextDouble() * 3.0;
    _twitchTimer = Timer(Duration(milliseconds: (seconds * 1000).round()), () => unawaited(_playTwitch()));
  }

  /// Plays one full "failed twitch" (rise then fall) on [_twitchController]
  /// and, if still animating and dead afterward, arms the next
  /// [_scheduleNextTwitch].
  ///
  /// Re-checks `mounted`/[_isAnimating]/[_isDead] after each await so a
  /// twitch in flight when animation is paused (or the emotion switched away
  /// from dead, or the widget disposed) neither leaves [_twitchController]
  /// mid-rise nor re-arms a further twitch.
  Future<void> _playTwitch() async {
    await _twitchController.forward(from: 0);
    if (!mounted || !_isAnimating || !_isDead) {
      return;
    }
    await _twitchController.reverse();
    if (!mounted || !_isAnimating || !_isDead) {
      return;
    }
    _scheduleNextTwitch();
  }

  /// Maps [_twitchAnimation]'s `0..1` rise progress to
  /// [LayoPainter.droopT]'s `0..1` tilt scale: `1.0` at rest (the twitch
  /// idle, fully drooped) easing down toward (not to) [_kTwitchLiftFraction]
  /// below `1.0` at the twitch's peak, then back to `1.0` as it falls.
  /// Applies only conceptually to [LayoEmotion.dead] -- for every other
  /// emotion [_twitchAnimation] simply never leaves `0`, so this always
  /// evaluates to `1.0` and [LayoPainter.droopT] is ignored downstream
  /// regardless.
  double get _droopT => 1.0 - _kTwitchLiftFraction * _twitchAnimation.value;

  @override
  void dispose() {
    _blinkTimer?.cancel();
    _twitchTimer?.cancel();
    _pulseController.dispose();
    _blinkController.dispose();
    _wiggleController.dispose();
    _zzzController.dispose();
    _twitchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final aspect = AspectRatio(
      aspectRatio: Layo._aspectRatio,
      child: AnimatedBuilder(
        animation: _repaint,
        builder: (context, _) {
          return CustomPaint(
            painter: LayoPainter(
              emotion: widget.emotion,
              pulseT: _pulseController.value,
              blinkT: _blinkAnimation.value,
              wiggleT: _wiggleController.value,
              zzzPhase: _zzzController.value,
              droopT: _droopT,
            ),
            size: Size.infinite,
          );
        },
      ),
    );

    final explicitWidth = widget.width;
    if (explicitWidth != null) {
      return SizedBox(width: explicitWidth, child: aspect);
    }
    return aspect;
  }
}

/// How far [LayoEmotion.dead]'s antenna lifts back toward upright at the
/// peak of its periodic "failed twitch", as a fraction of the full
/// droop-to-upright range -- roughly a third of the way, so the twitch reads
/// as a genuine (if brief) attempt to rise rather than either a flat vibrate
/// (too little movement) or a full recovery to upright (which would look
/// like the antenna un-drooping rather than trying and failing).
const double _kTwitchLiftFraction = 0.35;
