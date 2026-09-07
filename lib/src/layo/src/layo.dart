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
/// * A gentle antenna-tip pulse/glow, for [LayoEmotion.mrLayo],
///   [LayoEmotion.question], [LayoEmotion.sleep], [LayoEmotion.angry], and
///   [LayoEmotion.layo404]. [LayoEmotion.comandante] has no antenna at all
///   (its beret overlay sits exactly where one would be) and so plays no
///   antenna pulse either.
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
/// * A double-thump "heartbeat" scale pulse on both heart eyes and the
///   antenna dot in sync, for [LayoEmotion.love] alone, looping.
/// * A jittered "furrow + tremble" burst — the brows lower and the whole
///   face briefly shakes, then relaxes — for [LayoEmotion.angry] alone, on
///   the same kind of per-instance schedule as the blink.
/// * A snappy top-widening attention pulse on both "!" stems (each briefly
///   funnels into an inverted-triangle silhouette, wide at the top), for
///   [LayoEmotion.alert] alone, looping.
/// * An occasional glitch/flicker (opacity drop plus a tiny horizontal
///   jitter) on the "404" glyph group, for [LayoEmotion.layo404] alone, on a
///   jittered per-instance schedule.
/// * A soft continuous glow-pulse on the bulb, plus an occasional stronger
///   "insight" flash the antenna dot syncs to, for [LayoEmotion.idea] alone.
/// * A periodic, brief wink of the **right eye alone** (the left eye stays
///   open throughout) — a Chávez-style signature wink — for
///   [LayoEmotion.comandante] alone, on the same kind of jittered
///   per-instance schedule as [LayoEmotion.mrLayo]'s own two-eye blink.
/// * A subtle scale-pulse "shimmer" on both `$` eyes, plus a separate,
///   independently-looping "rain of bills" background layer behind the
///   whole mascot figure, for [LayoEmotion.money] alone.
/// * A looping sequence of pulsing/appearing connector circles (the cloud
///   itself stays static), for [LayoEmotion.thinking] alone.
/// * A looping, independently-bouncing equalizer bar chart, for
///   [LayoEmotion.listening] alone.
/// * A single tear welling up and sliding down from one eye, on a jittered
///   per-instance schedule shaped like [LayoEmotion.mrLayo]'s own blink but
///   noticeably more frequent (a 1.5-2.5s interval rather than 3-6s), for
///   [LayoEmotion.sad] alone.
/// * A check mark drawing its own stroke on, then settling with a quick
///   pop/bounce, on appearance and on the same kind of jittered per-instance
///   replay schedule, for [LayoEmotion.success] alone.
/// * A continuous twinkle (scale-pulse plus rotation) on both star eyes,
///   paired with a small looping energetic bounce of the whole glyph group,
///   for [LayoEmotion.excited] alone.
/// * A looping side-to-side (and slight up-down) scan of the magnifier
///   glyph, for [LayoEmotion.searching] alone.
/// * A looping rotation of both gears (the smaller one counter-rotating
///   against the larger one), for [LayoEmotion.working] alone.
/// * A periodic, brief wink of the **right eye alone** (the left eye and the
///   smile stay static throughout), on a jittered per-instance schedule
///   identical in shape to [LayoEmotion.mrLayo]'s own blink and
///   [LayoEmotion.comandante]'s own wink, for [LayoEmotion.wink] alone.
/// * A continuous spin of both spiral eyes, plus a jittered "pop" burst (a
///   quick scale/shake on the whole glyph group) on a per-instance schedule,
///   for [LayoEmotion.mindBlown] alone.
/// * A subtle, understated jittered lid/smirk raise, for [LayoEmotion.smug]
///   alone, on the same kind of per-instance schedule as the blink above,
///   but a small pulse rather than any large motion.
/// * A subtle, jittered gleam sweeping across one sunglasses lens, for
///   [LayoEmotion.cool] alone, on a per-instance schedule noticeably more
///   frequent than the blink above (a 1.5-3s interval rather than 3-6s).
/// * A looping "snowfall" background layer behind the whole mascot figure,
///   plus a gentle circular sway on the Santa hat's own pom-pom, for
///   [LayoEmotion.christmas] alone — which also plays the ordinary two-eye
///   blink above, unmodified, since its eyes are [LayoEmotion.mrLayo]'s own
///   circles, never covered by the hat.
/// * A looping multicolor "confetti" background layer behind the whole
///   mascot figure, plus a gentle vertical bob on the party hat's own
///   pom-pom tip, for [LayoEmotion.party] alone — which also plays the
///   ordinary two-eye blink above, unmodified, since its eyes are
///   [LayoEmotion.mrLayo]'s own circles, never covered by the hat.
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
  /// [LayoEmotion.dead], [LayoEmotion.love], and [LayoEmotion.idea]) — see
  /// [_syncAnimating].
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

  /// Looping controller driving [LayoEmotion.love]'s "heartbeat" scale
  /// pulse. Runs a fixed ~1.2-second cycle via [AnimationController.repeat]
  /// for as long as this instance is animating and its emotion is
  /// [LayoEmotion.love].
  late final AnimationController _beatController;

  /// Short, non-looping controller driving a single "furrow + tremble"
  /// burst, for [LayoEmotion.angry]. Idle (not animating) between bursts —
  /// [_scheduleNextBurst] is what fires it — mirroring how [_blinkController]
  /// behaves for the blink.
  late final AnimationController _burstController;

  /// The burst's own eased progress, `0` (relaxed, at rest) to `1` (the
  /// burst's peak furrow/tremble) and back, derived from [_burstController].
  late final Animation<double> _burstAnimation;

  /// Looping controller driving [LayoEmotion.alert]'s top-widening
  /// attention pulse. Runs a fixed ~900ms cycle via
  /// [AnimationController.repeat] for as long as this instance is animating
  /// and its emotion is [LayoEmotion.alert]; [LayoPainter]'s own
  /// `paintAlertGlyphs` derives the sharp easeOutBack-style envelope from
  /// this controller's raw linear value.
  late final AnimationController _alertPulseController;

  /// Short, non-looping controller driving a single glitch/flicker burst,
  /// for [LayoEmotion.layo404]. Idle (not animating) between flickers —
  /// [_scheduleNextGlitch] is what fires it — mirroring how
  /// [_blinkController] behaves for the blink.
  late final AnimationController _glitchController;

  /// Looping controller driving [LayoEmotion.idea]'s continuous glow-pulse
  /// breath. Runs a fixed ~2.4-second cycle via
  /// [AnimationController.repeat] for as long as this instance is animating
  /// and its emotion is [LayoEmotion.idea].
  late final AnimationController _glowController;

  /// Short, non-looping controller driving a single "insight" flash burst,
  /// for [LayoEmotion.idea]. Idle (not animating) between flashes —
  /// [_scheduleNextFlash] is what fires it — mirroring how
  /// [_blinkController] behaves for the blink.
  late final AnimationController _flashController;

  /// The flash's own eased progress, `0` (no flash) to `1` (the flash's
  /// peak brightness) and back, derived from [_flashController].
  late final Animation<double> _flashAnimation;

  /// Short, non-looping controller driving a single wink's close+open, for
  /// [LayoEmotion.comandante]. Idle (not animating) between winks —
  /// [_scheduleNextWink] is what fires it — exactly mirroring how
  /// [_blinkController] behaves for [LayoEmotion.mrLayo]'s blink, so it
  /// costs nothing at 60fps outside the brief window a wink is actually
  /// playing.
  late final AnimationController _winkController;

  /// The wink's own eased value, `0` (open) to `1` (fully closed), derived
  /// from [_winkController] so the close/reopen each feel like a snap
  /// rather than a linear wipe — the same shape [_blinkAnimation] uses for
  /// [LayoEmotion.mrLayo]'s blink, applied here to [LayoEmotion.comandante]'s
  /// right eye alone (see [LayoPainter.winkT]).
  late final Animation<double> _winkAnimation;

  /// Looping controller driving [LayoEmotion.money]'s `$`-eye shimmer. Runs a
  /// fixed ~1.6-second cycle via [AnimationController.repeat] for as long as
  /// this instance is animating and its emotion is [LayoEmotion.money].
  late final AnimationController _moneyShimmerController;

  /// Looping controller driving [LayoEmotion.money]'s "rain of bills"
  /// background layer. Runs a fixed ~6-second cycle via
  /// [AnimationController.repeat], independent of [_moneyShimmerController]'s
  /// own (much shorter) cycle, for as long as this instance is animating and
  /// its emotion is [LayoEmotion.money].
  late final AnimationController _billRainController;

  /// Looping controller driving [LayoEmotion.thinking]'s trailing-connector
  /// sequence. Runs a fixed ~2.2-second cycle via
  /// [AnimationController.repeat] for as long as this instance is animating
  /// and its emotion is [LayoEmotion.thinking].
  late final AnimationController _thoughtController;

  /// Looping controller driving [LayoEmotion.listening]'s equalizer bounce.
  /// Runs a fixed ~1.4-second cycle via [AnimationController.repeat] for as
  /// long as this instance is animating and its emotion is
  /// [LayoEmotion.listening].
  late final AnimationController _eqController;

  /// Short, non-looping controller driving a single tear-drip's rise and
  /// fall, for [LayoEmotion.sad]. Idle (not animating) between drips —
  /// [_scheduleNextTear] is what fires it — exactly mirroring how
  /// [_blinkController] behaves for [LayoEmotion.mrLayo]'s blink.
  late final AnimationController _tearController;

  /// Short, non-looping controller driving [LayoEmotion.success]'s check-mark
  /// stroke draw-in, from `0.0` (nothing drawn) to `1.0` (fully drawn). Fires
  /// once on appearance and again on each periodic replay —
  /// [_scheduleNextCheckReplay] is what arms each replay — then hands off to
  /// [_checkPopController] for the settle bounce.
  late final AnimationController _checkDrawController;

  /// Short, non-looping controller driving [LayoEmotion.success]'s
  /// pop/bounce settle, played immediately after [_checkDrawController]
  /// finishes drawing.
  late final AnimationController _checkPopController;

  /// Looping controller driving [LayoEmotion.excited]'s star-eye twinkle.
  /// Runs a fixed ~1.5-second cycle via [AnimationController.repeat] for as
  /// long as this instance is animating and its emotion is
  /// [LayoEmotion.excited].
  late final AnimationController _sparkleController;

  /// Looping controller driving [LayoEmotion.excited]'s energetic bounce, in
  /// sync with [_sparkleController]'s own cycle (same duration, restarted
  /// together in [_syncAnimating]).
  late final AnimationController _excitedBounceController;

  /// Looping controller driving [LayoEmotion.searching]'s magnifier scan.
  /// Runs a fixed ~2.6-second cycle via [AnimationController.repeat] for as
  /// long as this instance is animating and its emotion is
  /// [LayoEmotion.searching].
  late final AnimationController _scanController;

  /// Looping controller driving [LayoEmotion.working]'s gear rotation. Runs
  /// a fixed ~3-second cycle via [AnimationController.repeat] for as long as
  /// this instance is animating and its emotion is [LayoEmotion.working].
  late final AnimationController _gearController;

  /// Short, non-looping controller driving a single wink's close+open, for
  /// [LayoEmotion.wink]. Idle (not animating) between winks —
  /// [_scheduleNextWearWink] is what fires it — exactly mirroring how
  /// [_winkController] behaves for [LayoEmotion.comandante], but kept as its
  /// own controller so the two emotions' winks are fully independent.
  late final AnimationController _wearWinkController;

  /// The wear-wink's own eased value, `0` (open) to `1` (fully closed),
  /// derived from [_wearWinkController] the same way [_winkAnimation] derives
  /// from [_winkController].
  late final Animation<double> _wearWinkAnimation;

  /// Looping controller driving [LayoEmotion.mindBlown]'s spiral-eye spin.
  /// Runs a fixed ~2-second cycle via [AnimationController.repeat] for as
  /// long as this instance is animating and its emotion is
  /// [LayoEmotion.mindBlown].
  late final AnimationController _spinController;

  /// Short, non-looping controller driving a single "pop" burst (rise then
  /// fall), for [LayoEmotion.mindBlown]. Idle (not animating) between bursts
  /// — [_scheduleNextPop] is what fires it — mirroring how [_burstController]
  /// behaves for [LayoEmotion.angry].
  late final AnimationController _popController;

  /// The pop's own eased progress, `0` (rest) to `1` (the burst's peak) and
  /// back, derived from [_popController].
  late final Animation<double> _popAnimation;

  /// Short, non-looping controller driving a single subtle lid/smirk-raise
  /// pulse (rise then fall), for [LayoEmotion.smug]. Idle (not animating)
  /// between pulses — [_scheduleNextSmugPulse] is what fires it — mirroring
  /// how [_burstController] behaves for [LayoEmotion.angry], but understated.
  late final AnimationController _smugController;

  /// The smug pulse's own eased progress, `0` (rest) to `1` (the pulse's
  /// peak) and back, derived from [_smugController].
  late final Animation<double> _smugAnimation;

  /// Short, non-looping controller driving a single gleam sweep (rise then
  /// fall), for [LayoEmotion.cool]. Idle (not animating) between sweeps —
  /// [_scheduleNextGleam] is what fires it — mirroring how [_flashController]
  /// behaves for [LayoEmotion.idea].
  late final AnimationController _gleamController;

  /// The gleam's own eased progress, `0` (no gleam) to `1` (the sweep's peak)
  /// and back, derived from [_gleamController].
  late final Animation<double> _gleamAnimation;

  /// Looping controller driving [LayoEmotion.christmas]'s "snowfall"
  /// background layer. Runs a fixed ~7-second cycle via
  /// [AnimationController.repeat], mirroring [_billRainController]'s own
  /// role for [LayoEmotion.money], for as long as this instance is animating
  /// and its emotion is [LayoEmotion.christmas].
  late final AnimationController _snowController;

  /// Looping controller driving [LayoEmotion.christmas]'s Santa-hat pom-pom
  /// sway. Runs a fixed ~3-second cycle via [AnimationController.repeat] for
  /// as long as this instance is animating and its emotion is
  /// [LayoEmotion.christmas].
  late final AnimationController _pomPomSwayController;

  /// Looping controller driving [LayoEmotion.party]'s "confetti" background
  /// layer. Runs a fixed ~6-second cycle via [AnimationController.repeat],
  /// mirroring [_snowController]'s own role for [LayoEmotion.christmas], for
  /// as long as this instance is animating and its emotion is
  /// [LayoEmotion.party].
  late final AnimationController _confettiController;

  /// Looping controller driving [LayoEmotion.party]'s party-hat pom-pom bob.
  /// Runs a fixed ~2-second cycle via [AnimationController.repeat] for as
  /// long as this instance is animating and its emotion is
  /// [LayoEmotion.party].
  late final AnimationController _pomPomBobController;

  /// A single [Listenable] merging every controller/animation above, passed
  /// to [AnimatedBuilder.animation] so one listener covers all idle
  /// animations regardless of which ones are actually active for the
  /// current [Layo.emotion].
  late final Listenable _repaint;

  /// Source of every per-instance randomized interval (3-6s, for the blink,
  /// twitch, angry burst, 404 glitch, and idea flash schedulers alike), so
  /// this instance's bursts jitter against every other [Layo] on screen
  /// instead of firing in unison.
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

  /// Self-scheduling timer for the next "furrow + tremble" burst; mirrors
  /// [_blinkTimer] exactly, for [LayoEmotion.angry].
  Timer? _burstTimer;

  /// Self-scheduling timer for the next glitch/flicker burst; mirrors
  /// [_blinkTimer] exactly, for [LayoEmotion.layo404].
  Timer? _glitchTimer;

  /// Self-scheduling timer for the next "insight" flash burst; mirrors
  /// [_blinkTimer] exactly, for [LayoEmotion.idea].
  Timer? _flashTimer;

  /// Self-scheduling timer for the next wink; mirrors [_blinkTimer] exactly,
  /// for [LayoEmotion.comandante]'s right-eye wink instead of
  /// [LayoEmotion.mrLayo]'s two-eye blink.
  Timer? _winkTimer;

  /// Self-scheduling timer for the next tear-drip; mirrors [_blinkTimer]
  /// exactly, for [LayoEmotion.sad].
  Timer? _tearTimer;

  /// Self-scheduling timer for the next check-mark draw-in replay; mirrors
  /// [_blinkTimer] exactly, for [LayoEmotion.success]. Not armed for the
  /// very first draw-in (which plays immediately on animation start, see
  /// [_syncAnimating]) — only for every replay after that.
  Timer? _checkReplayTimer;

  /// Self-scheduling timer for the next [LayoEmotion.wink] wear-wink; mirrors
  /// [_winkTimer] exactly, for [LayoEmotion.wink] instead of
  /// [LayoEmotion.comandante].
  Timer? _wearWinkTimer;

  /// Self-scheduling timer for the next [LayoEmotion.mindBlown] "pop" burst;
  /// mirrors [_burstTimer] exactly, for [LayoEmotion.mindBlown].
  Timer? _popTimer;

  /// Self-scheduling timer for the next [LayoEmotion.smug] lid/smirk pulse;
  /// mirrors [_burstTimer] exactly, for [LayoEmotion.smug].
  Timer? _smugTimer;

  /// Self-scheduling timer for the next [LayoEmotion.cool] gleam sweep;
  /// mirrors [_flashTimer] exactly, for [LayoEmotion.cool].
  Timer? _gleamTimer;

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
  /// non-blinkable emotion no blink timer is ever armed and
  /// [_blinkAnimation]'s value stays structurally at `0`, rather than merely
  /// being ignored downstream. `true` for [LayoEmotion.mrLayo],
  /// [LayoEmotion.christmas], and [LayoEmotion.party] (all three share the
  /// same unmodified circular eyes). [LayoEmotion.comandante] plays its own
  /// separate one-eye [_isWinkable] animation instead of this shared
  /// two-eye blink.
  bool get _isBlinkable =>
      widget.emotion == LayoEmotion.mrLayo ||
      widget.emotion == LayoEmotion.christmas ||
      widget.emotion == LayoEmotion.party;

  /// Whether [Layo.emotion] is [LayoEmotion.comandante] — gates the wink
  /// scheduler entirely, exactly as [_isBlinkable] gates the blink scheduler
  /// for [LayoEmotion.mrLayo].
  bool get _isWinkable => widget.emotion == LayoEmotion.comandante;

  /// Whether [Layo.emotion] plays the looping antenna pulse — mirrors
  /// [LayoPainter._pulses]. `false` for [LayoEmotion.dead] (rests
  /// permanently drooped and twitches instead, see [_isDead]),
  /// [LayoEmotion.love] (its dot follows the heartbeat instead, see
  /// [_isLove]), [LayoEmotion.idea] (its dot follows the bulb flash instead,
  /// see [_isIdea]), and [LayoEmotion.comandante] (this emotion has no
  /// antenna at all — its beret overlay sits exactly where one would be —
  /// so there is no tip left to pulse; see `LayoPainter._hasAntenna`).
  bool get _pulses =>
      widget.emotion != LayoEmotion.dead &&
      widget.emotion != LayoEmotion.love &&
      widget.emotion != LayoEmotion.idea &&
      widget.emotion != LayoEmotion.comandante;

  /// Whether [Layo.emotion] is [LayoEmotion.dead] — gates the twitch
  /// scheduler entirely, exactly as [_isBlinkable] gates the blink scheduler
  /// for [LayoEmotion.mrLayo].
  bool get _isDead => widget.emotion == LayoEmotion.dead;

  /// Whether [Layo.emotion] is [LayoEmotion.love] — gates the looping
  /// heartbeat controller.
  bool get _isLove => widget.emotion == LayoEmotion.love;

  /// Whether [Layo.emotion] is [LayoEmotion.angry] — gates the "furrow +
  /// tremble" burst scheduler entirely, exactly as [_isBlinkable] gates the
  /// blink scheduler for [LayoEmotion.mrLayo].
  bool get _isAngry => widget.emotion == LayoEmotion.angry;

  /// Whether [Layo.emotion] is [LayoEmotion.alert] — gates the looping
  /// top-widening pulse controller.
  bool get _isAlert => widget.emotion == LayoEmotion.alert;

  /// Whether [Layo.emotion] is [LayoEmotion.layo404] — gates the
  /// glitch/flicker burst scheduler entirely, exactly as [_isBlinkable]
  /// gates the blink scheduler for [LayoEmotion.mrLayo].
  bool get _is404 => widget.emotion == LayoEmotion.layo404;

  /// Whether [Layo.emotion] is [LayoEmotion.idea] — gates the looping glow
  /// controller and the "insight" flash burst scheduler.
  bool get _isIdea => widget.emotion == LayoEmotion.idea;

  /// Whether [Layo.emotion] is [LayoEmotion.money] — gates the looping
  /// `$`-eye shimmer and "rain of bills" controllers.
  bool get _isMoney => widget.emotion == LayoEmotion.money;

  /// Whether [Layo.emotion] is [LayoEmotion.thinking] — gates the looping
  /// thought-connector-sequence controller.
  bool get _isThinking => widget.emotion == LayoEmotion.thinking;

  /// Whether [Layo.emotion] is [LayoEmotion.listening] — gates the looping
  /// equalizer-bounce controller.
  bool get _isListening => widget.emotion == LayoEmotion.listening;

  /// Whether [Layo.emotion] is [LayoEmotion.sad] — gates the tear-drip burst
  /// scheduler entirely, exactly as [_isBlinkable] gates the blink scheduler
  /// for [LayoEmotion.mrLayo].
  bool get _isSad => widget.emotion == LayoEmotion.sad;

  /// Whether [Layo.emotion] is [LayoEmotion.success] — gates the check-mark
  /// draw-in/pop scheduler entirely, exactly as [_isBlinkable] gates the
  /// blink scheduler for [LayoEmotion.mrLayo].
  bool get _isSuccess => widget.emotion == LayoEmotion.success;

  /// Whether [Layo.emotion] is [LayoEmotion.excited] — gates the looping
  /// star-twinkle and energetic-bounce controllers.
  bool get _isExcited => widget.emotion == LayoEmotion.excited;

  /// Whether [Layo.emotion] is [LayoEmotion.searching] — gates the looping
  /// magnifier-scan controller.
  bool get _isSearching => widget.emotion == LayoEmotion.searching;

  /// Whether [Layo.emotion] is [LayoEmotion.working] — gates the looping
  /// gear-rotation controller.
  bool get _isWorking => widget.emotion == LayoEmotion.working;

  /// Whether [Layo.emotion] is [LayoEmotion.wink] — gates the wear-wink
  /// scheduler entirely, exactly as [_isWinkable] gates the wink scheduler
  /// for [LayoEmotion.comandante].
  bool get _isWearWinkable => widget.emotion == LayoEmotion.wink;

  /// Whether [Layo.emotion] is [LayoEmotion.mindBlown] — gates the looping
  /// spiral-spin controller and the "pop" burst scheduler.
  bool get _isMindBlown => widget.emotion == LayoEmotion.mindBlown;

  /// Whether [Layo.emotion] is [LayoEmotion.smug] — gates the lid/smirk
  /// pulse scheduler entirely, exactly as [_isBlinkable] gates the blink
  /// scheduler for [LayoEmotion.mrLayo].
  bool get _isSmug => widget.emotion == LayoEmotion.smug;

  /// Whether [Layo.emotion] is [LayoEmotion.cool] — gates the gleam-sweep
  /// scheduler entirely, exactly as [_isBlinkable] gates the blink scheduler
  /// for [LayoEmotion.mrLayo].
  bool get _isCool => widget.emotion == LayoEmotion.cool;

  /// Whether [Layo.emotion] is [LayoEmotion.christmas] — gates the looping
  /// snowfall and pom-pom-sway controllers. This emotion also plays the
  /// ordinary two-eye [_isBlinkable] blink (its eyes are [LayoEmotion.mrLayo]'s
  /// own unmodified circles, never covered by the Santa hat overlay).
  bool get _isChristmas => widget.emotion == LayoEmotion.christmas;

  /// Whether [Layo.emotion] is [LayoEmotion.party] — gates the looping
  /// confetti and pom-pom-bob controllers, exactly as [_isChristmas] gates
  /// its own pair of looping controllers. This emotion also plays the
  /// ordinary two-eye [_isBlinkable] blink (its eyes are
  /// [LayoEmotion.mrLayo]'s own unmodified circles, never covered by the
  /// party hat overlay).
  bool get _isParty => widget.emotion == LayoEmotion.party;

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
    _beatController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _burstController = AnimationController(vsync: this, duration: const Duration(milliseconds: 550));
    _burstAnimation = CurvedAnimation(parent: _burstController, curve: Curves.easeInOut);
    _alertPulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _glitchController = AnimationController(vsync: this, duration: const Duration(milliseconds: 320));
    _glowController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400));
    _flashController = AnimationController(vsync: this, duration: const Duration(milliseconds: 380));
    _flashAnimation = CurvedAnimation(parent: _flashController, curve: Curves.easeOut);
    _winkController = AnimationController(vsync: this, duration: const Duration(milliseconds: 180));
    _winkAnimation = CurvedAnimation(parent: _winkController, curve: Curves.easeInOut);
    _moneyShimmerController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));
    _billRainController = AnimationController(vsync: this, duration: const Duration(milliseconds: 6000));
    _thoughtController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200));
    _eqController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    _tearController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));
    // Starts at 1.0 (fully drawn), not the AnimationController default lower
    // bound of 0.0 -- LayoEmotion.success's resting pose is a complete check
    // mark (see LayoPainter.checkDrawT's own doc comment), so a static
    // (animate: false) instance must render fully drawn from the very first
    // frame, with no draw-in ever needing to play to reach it.
    _checkDrawController = AnimationController(
      vsync: this,
      value: 1.0,
      duration: const Duration(milliseconds: 600),
    );
    _checkPopController = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
    _sparkleController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _excitedBounceController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _scanController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600));
    _gearController = AnimationController(vsync: this, duration: const Duration(milliseconds: 3000));
    _wearWinkController = AnimationController(vsync: this, duration: const Duration(milliseconds: 180));
    _wearWinkAnimation = CurvedAnimation(parent: _wearWinkController, curve: Curves.easeInOut);
    _spinController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000));
    _popController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _popAnimation = CurvedAnimation(parent: _popController, curve: Curves.easeInOut);
    _smugController = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _smugAnimation = CurvedAnimation(parent: _smugController, curve: Curves.easeInOut);
    _gleamController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _gleamAnimation = CurvedAnimation(parent: _gleamController, curve: Curves.easeInOut);
    _snowController = AnimationController(vsync: this, duration: const Duration(milliseconds: 7000));
    _pomPomSwayController = AnimationController(vsync: this, duration: const Duration(milliseconds: 3000));
    _confettiController = AnimationController(vsync: this, duration: const Duration(milliseconds: 6000));
    _pomPomBobController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000));
    _repaint = Listenable.merge([
      _pulseController,
      _blinkAnimation,
      _wiggleController,
      _zzzController,
      _twitchAnimation,
      _beatController,
      _burstAnimation,
      _alertPulseController,
      _glitchController,
      _glowController,
      _flashAnimation,
      _winkAnimation,
      _moneyShimmerController,
      _billRainController,
      _thoughtController,
      _eqController,
      _tearController,
      _checkDrawController,
      _checkPopController,
      _sparkleController,
      _excitedBounceController,
      _scanController,
      _gearController,
      _wearWinkAnimation,
      _spinController,
      _popAnimation,
      _smugAnimation,
      _gleamAnimation,
      _snowController,
      _pomPomSwayController,
      _confettiController,
      _pomPomBobController,
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
    final shouldBurst = shouldAnimate && _isAngry;
    final wasBursting = _burstTimer != null;
    final shouldGlitch = shouldAnimate && _is404;
    final wasGlitching = _glitchTimer != null;
    final shouldFlash = shouldAnimate && _isIdea;
    final wasFlashing = _flashTimer != null;
    final shouldWink = shouldAnimate && _isWinkable;
    final wasWinking = _winkTimer != null;
    final shouldTear = shouldAnimate && _isSad;
    final wasTearing = _tearTimer != null;
    final shouldCheck = shouldAnimate && _isSuccess;
    final wasChecking = _checkReplayTimer != null || _checkDrawController.isAnimating;
    final shouldWearWink = shouldAnimate && _isWearWinkable;
    final wasWearWinking = _wearWinkTimer != null;
    final shouldPop = shouldAnimate && _isMindBlown;
    final wasPopping = _popTimer != null;
    final shouldSmugPulse = shouldAnimate && _isSmug;
    final wasSmugPulsing = _smugTimer != null;
    final shouldGleam = shouldAnimate && _isCool;
    final wasGleaming = _gleamTimer != null;

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

      if (shouldAnimate && _isLove) {
        _beatController.repeat();
      } else {
        _beatController.stop();
      }

      if (shouldAnimate && _isAlert) {
        _alertPulseController.repeat();
      } else {
        _alertPulseController.stop();
      }

      if (shouldAnimate && _isIdea) {
        _glowController.repeat();
      } else {
        _glowController.stop();
      }

      if (shouldAnimate && _isMoney) {
        _moneyShimmerController.repeat();
        _billRainController.repeat();
      } else {
        _moneyShimmerController.stop();
        _billRainController.stop();
      }

      if (shouldAnimate && _isThinking) {
        _thoughtController.repeat();
      } else {
        _thoughtController.stop();
      }

      if (shouldAnimate && _isListening) {
        _eqController.repeat();
      } else {
        _eqController.stop();
      }

      if (shouldAnimate && _isExcited) {
        _sparkleController.repeat();
        _excitedBounceController.repeat();
      } else {
        _sparkleController.stop();
        _excitedBounceController.stop();
      }

      if (shouldAnimate && _isSearching) {
        _scanController.repeat();
      } else {
        _scanController.stop();
      }

      if (shouldAnimate && _isWorking) {
        _gearController.repeat();
      } else {
        _gearController.stop();
      }

      if (shouldAnimate && _isMindBlown) {
        _spinController.repeat();
      } else {
        _spinController.stop();
      }

      if (shouldAnimate && _isChristmas) {
        _snowController.repeat();
        _pomPomSwayController.repeat();
      } else {
        _snowController.stop();
        _pomPomSwayController.stop();
      }

      if (shouldAnimate && _isParty) {
        _confettiController.repeat();
        _pomPomBobController.repeat();
      } else {
        _confettiController.stop();
        _pomPomBobController.stop();
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

    if (shouldBurst && !wasBursting) {
      _scheduleNextBurst();
    } else if (!shouldBurst && wasBursting) {
      _burstController.stop();
      _burstController.value = 0;
      _burstTimer?.cancel();
      _burstTimer = null;
    }

    if (shouldGlitch && !wasGlitching) {
      _scheduleNextGlitch();
    } else if (!shouldGlitch && wasGlitching) {
      _glitchController.stop();
      _glitchController.value = 0;
      _glitchTimer?.cancel();
      _glitchTimer = null;
    }

    if (shouldFlash && !wasFlashing) {
      _scheduleNextFlash();
    } else if (!shouldFlash && wasFlashing) {
      _flashController.stop();
      _flashController.value = 0;
      _flashTimer?.cancel();
      _flashTimer = null;
    }

    if (shouldWink && !wasWinking) {
      _scheduleNextWink();
    } else if (!shouldWink && wasWinking) {
      _winkController.stop();
      _winkController.value = 0;
      _winkTimer?.cancel();
      _winkTimer = null;
    }

    if (shouldTear && !wasTearing) {
      _scheduleNextTear();
    } else if (!shouldTear && wasTearing) {
      _tearController.stop();
      _tearController.value = 0;
      _tearTimer?.cancel();
      _tearTimer = null;
    }

    if (shouldCheck && !wasChecking) {
      unawaited(_playCheck());
    } else if (!shouldCheck && wasChecking) {
      _checkDrawController.stop();
      _checkDrawController.value = 1.0;
      _checkPopController.stop();
      _checkPopController.value = 0;
      _checkReplayTimer?.cancel();
      _checkReplayTimer = null;
    }

    if (shouldWearWink && !wasWearWinking) {
      _scheduleNextWearWink();
    } else if (!shouldWearWink && wasWearWinking) {
      _wearWinkController.stop();
      _wearWinkController.value = 0;
      _wearWinkTimer?.cancel();
      _wearWinkTimer = null;
    }

    if (shouldPop && !wasPopping) {
      _scheduleNextPop();
    } else if (!shouldPop && wasPopping) {
      _popController.stop();
      _popController.value = 0;
      _popTimer?.cancel();
      _popTimer = null;
    }

    if (shouldSmugPulse && !wasSmugPulsing) {
      _scheduleNextSmugPulse();
    } else if (!shouldSmugPulse && wasSmugPulsing) {
      _smugController.stop();
      _smugController.value = 0;
      _smugTimer?.cancel();
      _smugTimer = null;
    }

    if (shouldGleam && !wasGleaming) {
      _scheduleNextGleam();
    } else if (!shouldGleam && wasGleaming) {
      _gleamController.stop();
      _gleamController.value = 0;
      _gleamTimer?.cancel();
      _gleamTimer = null;
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

  /// Arms a one-shot timer for the next wink, at a randomized 3-6 second
  /// interval so this instance's winks are jittered against every other
  /// [Layo] on screen instead of firing in unison — the same schedule shape
  /// as [_scheduleNextBlink], for [LayoEmotion.comandante]'s right-eye wink
  /// instead of [LayoEmotion.mrLayo]'s two-eye blink.
  ///
  /// Every continuation re-checks `mounted`, [_isAnimating], and
  /// [_isWinkable] before acting, so a timer or an in-flight wink left over
  /// from just before animation was paused (or the emotion switched away
  /// from [LayoEmotion.comandante], or the widget was disposed) cannot fire
  /// a wink, leave [_winkController] running, or re-arm the next timer.
  void _scheduleNextWink() {
    _winkTimer?.cancel();
    final seconds = 3.0 + _random.nextDouble() * 3.0;
    _winkTimer = Timer(Duration(milliseconds: (seconds * 1000).round()), () => unawaited(_playWink()));
  }

  /// Plays one full wink (close then reopen) on [_winkController] and, if
  /// still animating and winkable afterward, arms the next
  /// [_scheduleNextWink].
  ///
  /// Re-checks `mounted`/[_isAnimating]/[_isWinkable] after each await so a
  /// wink in flight when animation is paused (or the emotion switched away
  /// from [LayoEmotion.comandante], or the widget disposed) neither leaves
  /// [_winkController] mid-close nor re-arms a further wink.
  Future<void> _playWink() async {
    await _winkController.forward(from: 0);
    if (!mounted || !_isAnimating || !_isWinkable) {
      return;
    }
    await _winkController.reverse();
    if (!mounted || !_isAnimating || !_isWinkable) {
      return;
    }
    _scheduleNextWink();
  }

  /// Arms a one-shot timer for the next [LayoEmotion.wink] wear-wink, at a
  /// randomized 3-6 second interval so this instance's winks are jittered
  /// against every other [Layo] on screen instead of firing in unison — the
  /// same schedule shape as [_scheduleNextWink], for [LayoEmotion.wink]
  /// instead of [LayoEmotion.comandante].
  ///
  /// Every continuation re-checks `mounted`, [_isAnimating], and
  /// [_isWearWinkable] before acting, so a timer or an in-flight wink left
  /// over from just before animation was paused (or the emotion switched
  /// away from [LayoEmotion.wink], or the widget was disposed) cannot fire a
  /// wink, leave [_wearWinkController] running, or re-arm the next timer.
  void _scheduleNextWearWink() {
    _wearWinkTimer?.cancel();
    final seconds = 3.0 + _random.nextDouble() * 3.0;
    _wearWinkTimer = Timer(Duration(milliseconds: (seconds * 1000).round()), () => unawaited(_playWearWink()));
  }

  /// Plays one full wink (close then reopen) on [_wearWinkController] and, if
  /// still animating and wear-winkable afterward, arms the next
  /// [_scheduleNextWearWink].
  ///
  /// Re-checks `mounted`/[_isAnimating]/[_isWearWinkable] after each await so
  /// a wink in flight when animation is paused (or the emotion switched away
  /// from [LayoEmotion.wink], or the widget disposed) neither leaves
  /// [_wearWinkController] mid-close nor re-arms a further wink.
  Future<void> _playWearWink() async {
    await _wearWinkController.forward(from: 0);
    if (!mounted || !_isAnimating || !_isWearWinkable) {
      return;
    }
    await _wearWinkController.reverse();
    if (!mounted || !_isAnimating || !_isWearWinkable) {
      return;
    }
    _scheduleNextWearWink();
  }

  /// Arms a one-shot timer for the next tear-drip, at a randomized 1.5-2.5
  /// second interval — noticeably shorter than every other one-shot
  /// scheduler on this widget (each a 3-6 second interval, see
  /// [_scheduleNextBlink]) — so [LayoEmotion.sad] drips visibly more often,
  /// per the maintainer's tuning request, while still jittering this
  /// instance's drips against every other [Layo] on screen instead of firing
  /// in unison.
  ///
  /// Every continuation re-checks `mounted`, [_isAnimating], and [_isSad]
  /// before acting, so a timer or an in-flight drip left over from just
  /// before animation was paused (or the emotion switched away from sad, or
  /// the widget was disposed) cannot fire a drip, leave [_tearController]
  /// running, or re-arm the next timer.
  void _scheduleNextTear() {
    _tearTimer?.cancel();
    final seconds = 1.5 + _random.nextDouble() * 1.0;
    _tearTimer = Timer(Duration(milliseconds: (seconds * 1000).round()), () => unawaited(_playTear()));
  }

  /// Plays one full tear-drip (rise to `1.0`, then reset to `0.0`) on
  /// [_tearController] and, if still animating and sad afterward, arms the
  /// next [_scheduleNextTear].
  ///
  /// Re-checks `mounted`/[_isAnimating]/[_isSad] after the await so a drip in
  /// flight when animation is paused (or the emotion switched away from sad,
  /// or the widget disposed) neither leaves [_tearController] mid-drip nor
  /// re-arms a further drip.
  Future<void> _playTear() async {
    await _tearController.forward(from: 0);
    _tearController.value = 0;
    if (!mounted || !_isAnimating || !_isSad) {
      return;
    }
    _scheduleNextTear();
  }

  /// Arms a one-shot timer for the next check-mark draw-in replay, at a
  /// randomized 3-6 second interval so this instance's replays are jittered
  /// against every other [Layo] on screen instead of firing in unison — the
  /// same schedule shape as [_scheduleNextBlink], for [LayoEmotion.success]
  /// instead of [LayoEmotion.mrLayo].
  ///
  /// Every continuation re-checks `mounted`, [_isAnimating], and
  /// [_isSuccess] before acting, so a timer or an in-flight replay left over
  /// from just before animation was paused (or the emotion switched away
  /// from success, or the widget was disposed) cannot fire a replay, leave
  /// either controller running, or re-arm the next timer.
  void _scheduleNextCheckReplay() {
    _checkReplayTimer?.cancel();
    final seconds = 3.0 + _random.nextDouble() * 3.0;
    _checkReplayTimer = Timer(
      Duration(milliseconds: (seconds * 1000).round()),
      () => unawaited(_playCheck()),
    );
  }

  /// Plays one full check-mark sequence: [_checkDrawController] draws the
  /// stroke on (`0.0` to `1.0`), then [_checkPopController] plays the
  /// pop/bounce settle (`0.0` to `1.0` and back to `0.0`); if still animating
  /// and [_isSuccess] afterward, arms the next [_scheduleNextCheckReplay].
  ///
  /// Called both on animation start (the initial draw-in, with no prior
  /// replay timer) and by each [_scheduleNextCheckReplay] firing. Re-checks
  /// `mounted`/[_isAnimating]/[_isSuccess] after each await so a sequence in
  /// flight when animation is paused (or the emotion switched away from
  /// success, or the widget disposed) neither leaves either controller
  /// mid-flight nor re-arms a further replay.
  Future<void> _playCheck() async {
    await _checkDrawController.forward(from: 0);
    if (!mounted || !_isAnimating || !_isSuccess) {
      return;
    }
    await _checkPopController.forward(from: 0);
    _checkPopController.value = 0;
    if (!mounted || !_isAnimating || !_isSuccess) {
      return;
    }
    _scheduleNextCheckReplay();
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

  /// Arms a one-shot timer for the next "furrow + tremble" burst, at a
  /// randomized 3-6 second interval so this instance's bursts are jittered
  /// against every other [Layo] on screen instead of firing in unison — the
  /// same schedule shape as [_scheduleNextBlink], for [LayoEmotion.angry]
  /// instead of [LayoEmotion.mrLayo].
  ///
  /// Every continuation re-checks `mounted`, [_isAnimating], and [_isAngry]
  /// before acting, so a timer or an in-flight burst left over from just
  /// before animation was paused (or the emotion switched away from angry,
  /// or the widget was disposed) cannot fire a burst, leave
  /// [_burstController] running, or re-arm the next timer.
  void _scheduleNextBurst() {
    _burstTimer?.cancel();
    final seconds = 3.0 + _random.nextDouble() * 3.0;
    _burstTimer = Timer(Duration(milliseconds: (seconds * 1000).round()), () => unawaited(_playBurst()));
  }

  /// Plays one full "furrow + tremble" burst (rise then fall) on
  /// [_burstController] and, if still animating and angry afterward, arms
  /// the next [_scheduleNextBurst].
  ///
  /// Re-checks `mounted`/[_isAnimating]/[_isAngry] after each await so a
  /// burst in flight when animation is paused (or the emotion switched away
  /// from angry, or the widget disposed) neither leaves [_burstController]
  /// mid-rise nor re-arms a further burst.
  Future<void> _playBurst() async {
    await _burstController.forward(from: 0);
    if (!mounted || !_isAnimating || !_isAngry) {
      return;
    }
    await _burstController.reverse();
    if (!mounted || !_isAnimating || !_isAngry) {
      return;
    }
    _scheduleNextBurst();
  }

  /// Arms a one-shot timer for the next [LayoEmotion.mindBlown] "pop" burst,
  /// at a randomized 3-6 second interval so this instance's bursts are
  /// jittered against every other [Layo] on screen instead of firing in
  /// unison — the same schedule shape as [_scheduleNextBurst], for
  /// [LayoEmotion.mindBlown] instead of [LayoEmotion.angry].
  ///
  /// Every continuation re-checks `mounted`, [_isAnimating], and
  /// [_isMindBlown] before acting, so a timer or an in-flight burst left over
  /// from just before animation was paused (or the emotion switched away
  /// from [LayoEmotion.mindBlown], or the widget was disposed) cannot fire a
  /// burst, leave [_popController] running, or re-arm the next timer.
  void _scheduleNextPop() {
    _popTimer?.cancel();
    final seconds = 3.0 + _random.nextDouble() * 3.0;
    _popTimer = Timer(Duration(milliseconds: (seconds * 1000).round()), () => unawaited(_playPop()));
  }

  /// Plays one full "pop" burst (rise then fall) on [_popController] and, if
  /// still animating and [_isMindBlown] afterward, arms the next
  /// [_scheduleNextPop].
  ///
  /// Re-checks `mounted`/[_isAnimating]/[_isMindBlown] after each await so a
  /// pop in flight when animation is paused (or the emotion switched away, or
  /// the widget disposed) neither leaves [_popController] mid-rise nor
  /// re-arms a further pop.
  Future<void> _playPop() async {
    await _popController.forward(from: 0);
    if (!mounted || !_isAnimating || !_isMindBlown) {
      return;
    }
    await _popController.reverse();
    if (!mounted || !_isAnimating || !_isMindBlown) {
      return;
    }
    _scheduleNextPop();
  }

  /// Arms a one-shot timer for the next [LayoEmotion.smug] lid/smirk pulse,
  /// at a randomized 3-6 second interval so this instance's pulses are
  /// jittered against every other [Layo] on screen instead of firing in
  /// unison — the same schedule shape as [_scheduleNextBurst], for
  /// [LayoEmotion.smug] instead of [LayoEmotion.angry] (though this pulse
  /// itself is deliberately understated, unlike the angry burst).
  ///
  /// Every continuation re-checks `mounted`, [_isAnimating], and [_isSmug]
  /// before acting, so a timer or an in-flight pulse left over from just
  /// before animation was paused (or the emotion switched away from
  /// [LayoEmotion.smug], or the widget was disposed) cannot fire a pulse,
  /// leave [_smugController] running, or re-arm the next timer.
  void _scheduleNextSmugPulse() {
    _smugTimer?.cancel();
    final seconds = 3.0 + _random.nextDouble() * 3.0;
    _smugTimer = Timer(Duration(milliseconds: (seconds * 1000).round()), () => unawaited(_playSmugPulse()));
  }

  /// Plays one full lid/smirk pulse (rise then fall) on [_smugController]
  /// and, if still animating and [_isSmug] afterward, arms the next
  /// [_scheduleNextSmugPulse].
  ///
  /// Re-checks `mounted`/[_isAnimating]/[_isSmug] after each await so a pulse
  /// in flight when animation is paused (or the emotion switched away, or the
  /// widget disposed) neither leaves [_smugController] mid-rise nor re-arms a
  /// further pulse.
  Future<void> _playSmugPulse() async {
    await _smugController.forward(from: 0);
    if (!mounted || !_isAnimating || !_isSmug) {
      return;
    }
    await _smugController.reverse();
    if (!mounted || !_isAnimating || !_isSmug) {
      return;
    }
    _scheduleNextSmugPulse();
  }

  /// Arms a one-shot timer for the next glitch/flicker burst, at a
  /// randomized 3-6 second interval so this instance's glitches are
  /// jittered against every other [Layo] on screen instead of firing in
  /// unison — the same schedule shape as [_scheduleNextBlink], for
  /// [LayoEmotion.layo404] instead of [LayoEmotion.mrLayo].
  ///
  /// Every continuation re-checks `mounted`, [_isAnimating], and [_is404]
  /// before acting, so a timer or an in-flight glitch left over from just
  /// before animation was paused (or the emotion switched away from
  /// [LayoEmotion.layo404], or the widget was disposed) cannot fire a
  /// glitch, leave [_glitchController] running, or re-arm the next timer.
  void _scheduleNextGlitch() {
    _glitchTimer?.cancel();
    final seconds = 3.0 + _random.nextDouble() * 3.0;
    _glitchTimer = Timer(Duration(milliseconds: (seconds * 1000).round()), () => unawaited(_playGlitch()));
  }

  /// Plays one full glitch/flicker burst on [_glitchController] and, if
  /// still animating and [_is404] afterward, arms the next
  /// [_scheduleNextGlitch].
  ///
  /// Re-checks `mounted`/[_isAnimating]/[_is404] after each await so a
  /// glitch in flight when animation is paused (or the emotion switched
  /// away, or the widget disposed) neither leaves [_glitchController]
  /// mid-flicker nor re-arms a further glitch.
  Future<void> _playGlitch() async {
    await _glitchController.forward(from: 0);
    if (!mounted || !_isAnimating || !_is404) {
      return;
    }
    await _glitchController.reverse();
    if (!mounted || !_isAnimating || !_is404) {
      return;
    }
    _scheduleNextGlitch();
  }

  /// Arms a one-shot timer for the next "insight" flash burst, at a
  /// randomized 3-6 second interval so this instance's flashes are jittered
  /// against every other [Layo] on screen instead of firing in unison — the
  /// same schedule shape as [_scheduleNextBlink], for [LayoEmotion.idea]
  /// instead of [LayoEmotion.mrLayo].
  ///
  /// Every continuation re-checks `mounted`, [_isAnimating], and [_isIdea]
  /// before acting, so a timer or an in-flight flash left over from just
  /// before animation was paused (or the emotion switched away from idea,
  /// or the widget was disposed) cannot fire a flash, leave
  /// [_flashController] running, or re-arm the next timer.
  void _scheduleNextFlash() {
    _flashTimer?.cancel();
    final seconds = 3.0 + _random.nextDouble() * 3.0;
    _flashTimer = Timer(Duration(milliseconds: (seconds * 1000).round()), () => unawaited(_playFlash()));
  }

  /// Plays one full "insight" flash (rise then fall) on [_flashController]
  /// and, if still animating and [_isIdea] afterward, arms the next
  /// [_scheduleNextFlash].
  ///
  /// Re-checks `mounted`/[_isAnimating]/[_isIdea] after each await so a
  /// flash in flight when animation is paused (or the emotion switched away
  /// from idea, or the widget disposed) neither leaves [_flashController]
  /// mid-rise nor re-arms a further flash.
  Future<void> _playFlash() async {
    await _flashController.forward(from: 0);
    if (!mounted || !_isAnimating || !_isIdea) {
      return;
    }
    await _flashController.reverse();
    if (!mounted || !_isAnimating || !_isIdea) {
      return;
    }
    _scheduleNextFlash();
  }

  /// Arms a one-shot timer for the next [LayoEmotion.cool] gleam sweep, at a
  /// randomized 1.5-3 second interval — noticeably shorter than the shared
  /// 3-6 second interval every other one-shot scheduler on this widget uses
  /// (see [_scheduleNextBlink]), per the maintainer's tuning request so the
  /// gleam reads as a more frequent little shine rather than a rare event —
  /// while still jittering this instance's gleams against every other [Layo]
  /// on screen instead of firing in unison.
  ///
  /// Every continuation re-checks `mounted`, [_isAnimating], and [_isCool]
  /// before acting, so a timer or an in-flight gleam left over from just
  /// before animation was paused (or the emotion switched away from
  /// [LayoEmotion.cool], or the widget was disposed) cannot fire a gleam,
  /// leave [_gleamController] running, or re-arm the next timer.
  void _scheduleNextGleam() {
    _gleamTimer?.cancel();
    final seconds = 1.5 + _random.nextDouble() * 1.5;
    _gleamTimer = Timer(Duration(milliseconds: (seconds * 1000).round()), () => unawaited(_playGleam()));
  }

  /// Plays one full gleam sweep (rise then fall) on [_gleamController] and,
  /// if still animating and [_isCool] afterward, arms the next
  /// [_scheduleNextGleam].
  ///
  /// Re-checks `mounted`/[_isAnimating]/[_isCool] after each await so a gleam
  /// in flight when animation is paused (or the emotion switched away from
  /// [LayoEmotion.cool], or the widget disposed) neither leaves
  /// [_gleamController] mid-sweep nor re-arms a further gleam.
  Future<void> _playGleam() async {
    await _gleamController.forward(from: 0);
    if (!mounted || !_isAnimating || !_isCool) {
      return;
    }
    await _gleamController.reverse();
    if (!mounted || !_isAnimating || !_isCool) {
      return;
    }
    _scheduleNextGleam();
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

  /// Maps [_glitchController]'s `0..1` forward-then-reverse progress to
  /// [LayoPainter.glitchOpacity]'s `0..1` alpha: `1.0` at rest (fully
  /// opaque) and a rapid multi-flicker dip during the burst, derived by
  /// running a fast sine over the controller's own raw linear value so the
  /// digits appear to flicker two or three times within one burst rather
  /// than dip smoothly once.
  double get _glitchOpacity {
    final t = _glitchController.value;
    if (t <= 0.0) return 1.0;
    final flicker = (math.sin(t * math.pi * _kGlitchFlickerCount) + 1.0) / 2.0;
    return 1.0 - _kGlitchMaxDim * flicker * math.sin(t * math.pi);
  }

  /// Maps [_glitchController]'s `0..1` progress to
  /// [LayoPainter.glitchOffset]'s small horizontal jitter (in source units),
  /// in sync with [_glitchOpacity]'s own flicker rhythm, so the digits shift
  /// sideways exactly when they dim.
  double get _glitchOffset {
    final t = _glitchController.value;
    if (t <= 0.0) return 0.0;
    return _kGlitchMaxOffset * math.sin(t * math.pi * _kGlitchFlickerCount) * math.sin(t * math.pi);
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    _twitchTimer?.cancel();
    _burstTimer?.cancel();
    _glitchTimer?.cancel();
    _flashTimer?.cancel();
    _winkTimer?.cancel();
    _tearTimer?.cancel();
    _checkReplayTimer?.cancel();
    _wearWinkTimer?.cancel();
    _popTimer?.cancel();
    _smugTimer?.cancel();
    _gleamTimer?.cancel();
    _pulseController.dispose();
    _blinkController.dispose();
    _wiggleController.dispose();
    _zzzController.dispose();
    _twitchController.dispose();
    _beatController.dispose();
    _burstController.dispose();
    _alertPulseController.dispose();
    _glitchController.dispose();
    _glowController.dispose();
    _flashController.dispose();
    _winkController.dispose();
    _moneyShimmerController.dispose();
    _billRainController.dispose();
    _thoughtController.dispose();
    _eqController.dispose();
    _tearController.dispose();
    _checkDrawController.dispose();
    _checkPopController.dispose();
    _sparkleController.dispose();
    _excitedBounceController.dispose();
    _scanController.dispose();
    _gearController.dispose();
    _wearWinkController.dispose();
    _spinController.dispose();
    _popController.dispose();
    _smugController.dispose();
    _gleamController.dispose();
    _snowController.dispose();
    _pomPomSwayController.dispose();
    _confettiController.dispose();
    _pomPomBobController.dispose();
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
              beatT: _beatController.value,
              burstT: _burstAnimation.value,
              alertPulseT: _alertPulseController.value,
              glitchOpacity: _glitchOpacity,
              glitchOffset: _glitchOffset,
              glowT: _glowController.value,
              flashT: _flashAnimation.value,
              winkT: _winkAnimation.value,
              moneyT: _moneyShimmerController.value,
              billRainT: _billRainController.value,
              thoughtT: _thoughtController.value,
              eqT: _eqController.value,
              tearT: _tearController.value,
              checkDrawT: _checkDrawController.value,
              checkPopT: _checkPopController.value,
              sparkleT: _sparkleController.value,
              excitedBounceT: _excitedBounceController.value,
              scanT: _scanController.value,
              gearT: _gearController.value,
              wearWinkT: _wearWinkAnimation.value,
              spinT: _spinController.value,
              popT: _popAnimation.value,
              smugT: _smugAnimation.value,
              gleamT: _gleamAnimation.value,
              snowT: _snowController.value,
              pomPomSwayT: _pomPomSwayController.value,
              confettiT: _confettiController.value,
              pomPomBobT: _pomPomBobController.value,
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

/// How many quick flicker cycles [_LayoState._glitchOpacity] and
/// [_LayoState._glitchOffset] complete within one glitch burst -- tuned so
/// the "404" glyph group reads as flickering two-to-three times per burst
/// (a broken/no-signal display), rather than dipping smoothly once.
const double _kGlitchFlickerCount = 2.5;

/// How far [_LayoState._glitchOpacity] dims at a flicker's darkest point, as
/// a fraction of full opacity -- e.g. `0.7` dims down to roughly `0.3` alpha
/// at the deepest flicker, matching the "brief opacity drop to ~0.3" the
/// glitch animation was specified against.
const double _kGlitchMaxDim = 0.7;

/// The peak horizontal jitter [_LayoState._glitchOffset] applies during a
/// glitch burst, in source units (pre-`k` scale) -- a couple of source
/// units, small enough to read as a jitter rather than the glyph group
/// visibly relocating.
const double _kGlitchMaxOffset = 1.6;
