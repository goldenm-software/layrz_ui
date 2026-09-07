import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'layo_painter.dart';

/// The "MrLayo" brand mascot, rendered entirely with [CustomPainter] — no
/// bundled image or SVG asset.
///
/// This is deliberately named `Layo`, without the `Layrz` prefix used by the
/// rest of this design system's components: it is a brand asset rather than
/// a themeable UI primitive (see decision D11 in `engineering/decisions.md`).
///
/// [Layo] draws the single, static, awake face traced from the reference
/// artwork, and — when [animate] is `true` and the platform is not asking
/// for reduced motion — layers two small idle animations on top of it so the
/// mascot reads as alive rather than a still image: a gentle antenna-tip
/// pulse/glow, and a periodic eye blink. Nothing else moves; the silhouette
/// is identical to the static artwork at every frame, which matters because
/// [Layo] is also used small (~32px) and repeated, e.g. one per message in a
/// chat list.
///
/// Both idle animations are surfaced to an [AnimatedBuilder] wrapping only
/// the [CustomPaint], so an animating [Layo] repaints just its own paint
/// layer every frame — no ancestor widget rebuilds, and no `setState` is
/// ever called for animation ticks. The antenna pulse pauses (and the
/// eye-blink timer is cancelled) whenever [TickerMode.valuesOf] reports
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
  /// `true`, [Layo] plays a subtle idle antenna pulse and periodic eye
  /// blink, automatically pausing while off-screen (via [TickerMode]) and
  /// falling back to the static look when the platform requests reduced
  /// motion (`MediaQuery.disableAnimations`). Pass `false` to force the
  /// fully static look regardless of platform settings — useful for a
  /// caller that wants a still mascot (e.g. a printed/exported view).
  const Layo({this.width, this.animate = true, super.key});

  /// Optional explicit width in logical pixels.
  ///
  /// When null, [Layo] fills the width its parent provides and derives
  /// height from the fixed 500:833 aspect ratio; provide it when [Layo] sits
  /// in an unbounded context (e.g. inside a scrolling [Column]) where the
  /// parent imposes no width.
  final double? width;

  /// Whether [Layo] plays its idle animations (antenna pulse and eye blink).
  ///
  /// Defaults to `true`. Even when `true`, the animations are further gated
  /// by [TickerMode] (paused while an ancestor marks this subtree as not
  /// visible, e.g. scrolled out of view in a list) and by the platform's
  /// reduced-motion preference (`MediaQuery.disableAnimations`), either of
  /// which forces the static look without the caller needing to do
  /// anything. Pass `false` to force the static look unconditionally.
  final bool animate;

  /// The mascot artwork's fixed width:height aspect ratio, traced from the
  /// original 500×833 reference resource (`mr-layo.png`).
  static const double _aspectRatio = 500 / 833;

  @override
  State<Layo> createState() => _LayoState();
}

/// State for [Layo]: owns the two idle-animation controllers and rebuilds
/// only the [CustomPaint] beneath an [AnimatedBuilder] each frame, deriving
/// [LayoPainter.pulseT] and [LayoPainter.blinkT] from their current values.
class _LayoState extends State<Layo> with TickerProviderStateMixin {
  /// Looping controller driving the antenna-tip pulse. Runs a fixed
  /// ~2-second cycle for as long as animation is active via
  /// [AnimationController.repeat]; never restarted or seeked mid-cycle.
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

  /// A single [Listenable] merging [_pulseController] and [_blinkAnimation],
  /// passed to [AnimatedBuilder.animation] so one listener covers both idle
  /// animations.
  late final Listenable _repaint;

  /// Source of the per-blink randomized interval (3-6s), so this instance's
  /// blinks jitter against every other [Layo] on screen instead of firing
  /// in unison.
  final math.Random _random = math.Random();

  /// Self-scheduling timer for the next blink; recreated after every blink
  /// fires (or when animation resumes after being paused) and cancelled
  /// whenever animation is inactive so nothing fires unseen.
  Timer? _blinkTimer;

  /// Whether this instance currently considers itself "animating" — the
  /// combination of [Layo.animate], [TickerMode.valuesOf], and the platform's
  /// reduced-motion preference. Tracked so [didChangeDependencies] and
  /// [didUpdateWidget] only start/stop the tickers and blink scheduler on
  /// an actual transition, rather than re-deriving and acting on it
  /// unconditionally on every rebuild (which would restart the pulse loop
  /// and re-arm the blink timer needlessly).
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000));
    _blinkController = AnimationController(vsync: this, duration: const Duration(milliseconds: 140));
    _blinkAnimation = CurvedAnimation(parent: _blinkController, curve: Curves.easeInOut);
    _repaint = Listenable.merge([_pulseController, _blinkAnimation]);
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
  /// a change, starts or stops the pulse loop and the blink scheduler.
  ///
  /// This is the single place that reads [Layo.animate], [TickerMode.valuesOf],
  /// and `MediaQuery.disableAnimations` — called from both
  /// [didChangeDependencies] (covers [TickerMode] and [MediaQuery] changes,
  /// e.g. scrolling this widget off/on screen) and [didUpdateWidget] (covers
  /// the caller flipping [Layo.animate]).
  void _syncAnimating() {
    final reducedMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final shouldAnimate = widget.animate && !reducedMotion && TickerMode.valuesOf(context).enabled;

    if (shouldAnimate == _isAnimating) {
      return;
    }
    _isAnimating = shouldAnimate;

    if (shouldAnimate) {
      _pulseController.repeat();
      _scheduleNextBlink();
    } else {
      _pulseController.stop();
      _blinkController.stop();
      _blinkController.value = 0;
      _blinkTimer?.cancel();
      _blinkTimer = null;
    }
  }

  /// Arms a one-shot timer for the next blink, at a randomized 3-6 second
  /// interval so this instance's blinks are jittered against every other
  /// [Layo] on screen rather than firing in unison.
  ///
  /// Every continuation re-checks `mounted` and [_isAnimating] before
  /// acting, so a timer or an in-flight blink left over from just before
  /// animation was paused (or the widget was disposed) cannot fire a blink,
  /// leave [_blinkController] running, or re-arm the next timer.
  void _scheduleNextBlink() {
    _blinkTimer?.cancel();
    final seconds = 3.0 + _random.nextDouble() * 3.0;
    _blinkTimer = Timer(Duration(milliseconds: (seconds * 1000).round()), () => unawaited(_playBlink()));
  }

  /// Plays one full blink (close then reopen) on [_blinkController] and, if
  /// still animating afterward, arms the next [_scheduleNextBlink].
  ///
  /// Re-checks `mounted`/[_isAnimating] after each await so a blink in
  /// flight when animation is paused (or the widget disposed) neither
  /// leaves [_blinkController] mid-close nor re-arms a further blink.
  Future<void> _playBlink() async {
    await _blinkController.forward(from: 0);
    if (!mounted || !_isAnimating) {
      return;
    }
    await _blinkController.reverse();
    if (!mounted || !_isAnimating) {
      return;
    }
    _scheduleNextBlink();
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    _pulseController.dispose();
    _blinkController.dispose();
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
              pulseT: _pulseController.value,
              blinkT: _blinkAnimation.value,
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
