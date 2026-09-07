import 'package:flutter/widgets.dart';

import 'layo.dart';
import 'layo_controller.dart';
import 'layo_emotion.dart';

/// Wraps [Layo] and **animates transitions between emotions**, driven by a
/// [LayoController].
///
/// [Layo] itself is untouched and stays purely presentational: it always
/// draws one static [LayoEmotion] (plus that emotion's own idle animations —
/// see [Layo]'s own doc comment). [TransitionedLayo] is the layer that sits
/// on top and animates the *change* from one emotion to the next whenever
/// [controller]'s target (`LayoController.to`) changes, then hands off to a
/// single plain [Layo] once the transition settles so the target emotion's
/// idle animations resume normally.
///
/// Named `TransitionedLayo`, not `AnimatedLayo`: [Layo] is already
/// idle-animated (blinks, pulses, sways, and so on) on its own, so
/// "`Animated`" would suggest this widget adds motion [Layo] does not already
/// have, when what it actually adds is specifically the cross-fade *between*
/// two emotions.
///
/// # Where the blend actually happens
///
/// The transition is a **whole-widget crossfade**, not a painter-level blend:
/// mid-transition, this widget stacks two complete, independently-correct
/// [Layo] widgets — the outgoing emotion and the incoming one — in a [Stack],
/// fading the outgoing one's opacity `1.0 -> 0.0` and the incoming one's
/// opacity `0.0 -> 1.0` over the same ~280ms via [FadeTransition]. Each
/// [Layo] renders its own emotion exactly as it always does (base, tie,
/// screen glyphs, any overlay/backdrop/body-overlay, antenna, all in that
/// emotion's own correct colors), so the crossfade is a fade between two
/// finished, correct images rather than a shape-by-shape or accent-by-accent
/// interpolation — nothing to get subtly wrong per glyph, and no risk to
/// `LayoPainter`'s existing single-emotion rendering, which this widget never
/// touches: `LayoPainter` carries no transition-specific parameters at all.
/// Once the fade completes, only the target emotion's [Layo] remains
/// mounted, so its own idle animations resume exactly as they would for a
/// bare [Layo] the caller had built directly.
///
/// # Owning the animation
///
/// [TransitionedLayo] owns the [AnimationController] driving the crossfade's
/// `0..1` progress — [controller] (a [LayoController]) holds only *intent*
/// (which emotion the transition is from/to) and notifies on change; it owns
/// no ticker of its own (see [LayoController]'s own doc comment for why).
/// Whenever [controller] fires (i.e. `LayoController.to` was called, whether
/// starting a fresh transition or re-basing an in-flight one), this widget:
///
/// 1. Reads the controller's current `LayoController.from` and
///    `LayoController.target`.
/// 2. Restarts its own ~280ms, [Curves.easeInOut]-eased [AnimationController]
///    from `0.0`.
/// 3. Stacks `LayoController.from`'s [Layo] (fading out) under
///    `LayoController.target`'s [Layo] (fading in), reporting the
///    interpolated progress back to [controller] via
///    `LayoController.reportCurrent` on every tick, so a further re-basing
///    `LayoController.to` call mid-flight knows to start from wherever the
///    mascot visually reads as right now, not from the stale original
///    `from`.
/// 4. Once the animation reaches `1.0`, drops the outgoing [Layo] entirely
///    and renders only `LayoController.target`'s [Layo], so its own idle
///    animations take over exactly as they would for a bare [Layo].
///
/// # Reduced motion
///
/// [TransitionedLayo] **animates transitions by default** — unlike [Layo]'s
/// own idle animations, which merely decorate an otherwise-static face,
/// skipping the transition here would mean the mascot's emotion changes with
/// no animation played at all between them, so the default is `true`.
/// Respecting reduced motion still matters, though: when [animate] is
/// `false`, or the platform's own `MediaQuery.disableAnimations` reports
/// `true`, an emotion change is a **hard cut** — no crossfade ever runs, no
/// two [Layo]s are ever stacked, and the single [Layo] jumps straight to
/// showing the new target emotion on the very next frame after
/// `LayoController.to` fires.
///
/// # Sizing
///
/// [TransitionedLayo] is size-automatic exactly like [Layo]: an [AspectRatio]
/// of 500:833 wraps its content, so it fills whatever width its parent
/// provides (or use the explicit [width] for an unbounded parent) and derives
/// its own height from that fixed ratio — see [Layo]'s own doc comment for
/// the same contract in full.
class TransitionedLayo extends StatefulWidget {
  /// Creates a new [TransitionedLayo].
  ///
  /// The [controller] parameter is required: it is the [LayoController]
  /// whose `LayoController.to` calls this widget listens to and animates.
  ///
  /// The [initialEmotion] parameter is optional and defaults to
  /// [LayoEmotion.mrLayo]. It is used only for the very first frame, before
  /// [controller] has ever been read — in practice this widget instead reads
  /// [controller]'s own current `LayoController.target` on [initState], so
  /// [initialEmotion] matters only if a caller wants this widget's fallback
  /// to differ from the controller's own starting emotion (ordinarily it
  /// should simply match whatever [controller] itself was constructed with).
  ///
  /// The [width] parameter is optional. When null, [TransitionedLayo] expands
  /// to fill the width its parent provides and derives height from the fixed
  /// 500:833 aspect ratio, exactly like [Layo.width] — see that parameter's
  /// own doc comment for the same unbounded-parent caveat.
  ///
  /// The [animate] parameter is optional and defaults to `true`. When
  /// `true`, transitions between emotions play as a ~280ms crossfade (see
  /// the class doc comment's "Reduced motion" section), further gated by the
  /// platform's own reduced-motion preference
  /// (`MediaQuery.disableAnimations`), which forces a hard cut regardless of
  /// this value. Pass `false` to force a hard cut unconditionally. This value
  /// is also forwarded to every inner [Layo] this widget builds, so their own
  /// idle animations respect the same setting.
  const TransitionedLayo({
    required this.controller,
    this.initialEmotion = LayoEmotion.mrLayo,
    this.width,
    this.animate = true,
    super.key,
  });

  /// The controller driving which transition this widget animates.
  ///
  /// [TransitionedLayo] subscribes to [controller] in [initState] and
  /// unsubscribes in [dispose]; if a different controller instance is
  /// supplied on a rebuild, [didUpdateWidget] detaches the old listener and
  /// attaches the new one. Disposal of [controller] itself is caller-owned —
  /// this widget never disposes it, matching every other controller in this
  /// design system (e.g. `LayrzStepperController`, `LayrzButtonController`).
  final LayoController controller;

  /// The emotion shown before [controller] has been read, and the fallback
  /// [controller] itself starts on if constructed with no
  /// `LayoController.initialEmotion` of its own.
  ///
  /// Defaults to [LayoEmotion.mrLayo]. See the constructor's own doc comment
  /// for the precise role this plays alongside [controller]'s own starting
  /// state.
  final LayoEmotion initialEmotion;

  /// Optional explicit width in logical pixels.
  ///
  /// When null, [TransitionedLayo] fills the width its parent provides and
  /// derives height from the fixed 500:833 aspect ratio; provide it when this
  /// widget sits in an unbounded context (e.g. inside a scrolling [Column]),
  /// exactly as [Layo.width] documents.
  final double? width;

  /// Whether [TransitionedLayo] animates transitions between emotions, and
  /// whether every inner [Layo] it builds plays its own idle animations.
  ///
  /// Defaults to `true`. Even when `true`, the platform's reduced-motion
  /// preference (`MediaQuery.disableAnimations`) forces a hard cut for
  /// transitions (and the equivalent static look for each [Layo]'s own idle
  /// animations) without the caller needing to do anything. Pass `false` to
  /// force both unconditionally.
  final bool animate;

  @override
  State<TransitionedLayo> createState() => _TransitionedLayoState();
}

/// State for [TransitionedLayo]: owns the [AnimationController] driving the
/// crossfade, listens to [TransitionedLayo.controller] for new transition
/// requests, and settles back onto a single plain [Layo] once each
/// transition completes.
class _TransitionedLayoState extends State<TransitionedLayo> with SingleTickerProviderStateMixin {
  /// Drives this widget's own crossfade progress, `0.0` to `1.0`, over a
  /// fixed ~280ms — restarted from `0.0` every time
  /// [TransitionedLayo.controller] notifies of a new (or re-based) transition
  /// target, via [_onControllerChanged].
  late final AnimationController _fadeController;

  /// [_fadeController]'s own [Curves.easeInOut]-eased value, shared by the
  /// incoming [Layo]'s own [FadeTransition] directly, and by the outgoing
  /// one via [_outgoingOpacity]'s own reversal of it — so the crossfade
  /// always uses the same ease every other UI transition of this length in
  /// this design system uses.
  late final Animation<double> _fadeAnimation;

  /// The outgoing [Layo]'s own opacity, reversed from [_fadeAnimation] (via
  /// [Tween.animate]) rather than computing `1 - value` inline on every
  /// build, so both [FadeTransition]s in [build] read a plain [Animation]
  /// the same way.
  late final Animation<double> _outgoingOpacity;

  /// The emotion this widget most recently painted a **fully-settled** (not
  /// mid-transition) frame for — this is the sole [Layo] rendered once
  /// [_fadeController] reaches `1.0`, and it is also the value
  /// [TransitionedLayo.controller] is told about (via
  /// `LayoController.reportCurrent`) once a transition finishes.
  late LayoEmotion _settledEmotion;

  /// The emotion the currently in-flight (or just-started) transition is
  /// fading **from** — captured once, when [_onControllerChanged] starts a
  /// transition, so a later re-basing `LayoController.to` call (which changes
  /// [TransitionedLayo.controller]'s own `LayoController.from`) does not
  /// retroactively change what this specific already-in-flight transition
  /// started from; [_onControllerChanged] instead restarts [_fadeController]
  /// from `0.0` and recaptures this field fresh.
  late LayoEmotion _transitionFrom;

  @override
  void initState() {
    super.initState();
    _settledEmotion = widget.controller.target;
    _transitionFrom = widget.controller.from;
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 280));
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);
    _outgoingOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(_fadeAnimation);
    _fadeController.addListener(_reportProgressToController);
    widget.controller.addListener(_onControllerChanged);
    // The controller may already be mid-transition (from != target) at the
    // moment this widget first attaches to it; if so, jump straight into
    // animating that transition rather than only reacting to a future
    // notification that may never come. Deferred to right after this frame
    // (rather than calling _onControllerChanged, which calls setState,
    // directly here) since setState is illegal during initState, before this
    // widget's first build has happened at all.
    if (widget.controller.from != widget.controller.target) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _onControllerChanged());
    }
  }

  @override
  void didUpdateWidget(covariant TransitionedLayo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
      _settledEmotion = widget.controller.target;
      _transitionFrom = widget.controller.from;
      _fadeController.value = widget.controller.from == widget.controller.target ? 1.0 : 0.0;
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _fadeController.removeListener(_reportProgressToController);
    _fadeController.dispose();
    super.dispose();
  }

  /// Reports this widget's own actually-visible emotion back to
  /// [TransitionedLayo.controller] on every tick of [_fadeController], via
  /// `LayoController.reportCurrent` — registered once, in [initState], as a
  /// plain [AnimationController] listener rather than as a side effect inside
  /// [build], since a rebuild is not the right place to mutate a
  /// [ChangeNotifier] this widget does not own.
  ///
  /// Reports [_transitionFrom] for the first half of the transition
  /// (`_fadeAnimation.value < 0.5`) and `LayoController.target` for the
  /// second half — a simple nearer-endpoint estimate of "what the mascot
  /// visually reads as right now", good enough for [LayoController.to]'s own
  /// purpose (deciding a re-basing transition's new `LayoController.from`),
  /// without this widget needing to expose any finer-grained blended notion
  /// of "current emotion" than a single [LayoEmotion] value allows.
  void _reportProgressToController() {
    final progress = _fadeAnimation.value;
    widget.controller.reportCurrent(progress < 0.5 ? _transitionFrom : widget.controller.target);
  }

  /// Whether this widget currently animates transitions:
  /// [TransitionedLayo.animate] is `true` and the platform is not asking for
  /// reduced motion. Mirrors [Layo]'s own `_syncAnimating` gate, but
  /// recomputed on demand here rather than cached, since
  /// [_onControllerChanged] (a listener callback, not a lifecycle method)
  /// cannot rely on [didChangeDependencies] having already run for the
  /// current frame.
  bool get _shouldAnimate => widget.animate && !(MediaQuery.maybeOf(context)?.disableAnimations ?? false);

  /// Called whenever [TransitionedLayo.controller] notifies — i.e. every
  /// `LayoController.to` call, whether starting a fresh transition or
  /// re-basing one already in flight.
  ///
  /// When [_shouldAnimate] is `false` (reduced motion, or
  /// [TransitionedLayo.animate] is `false`), this performs a **hard cut**:
  /// [_settledEmotion] jumps straight to `LayoController.target` with no
  /// crossfade of any kind, [_fadeController] is left at rest, and
  /// `LayoController.reportCurrent` is told the same settled value
  /// immediately — no two [Layo]s are ever stacked.
  ///
  /// Otherwise, this restarts [_fadeController] from `0.0`, capturing
  /// [_transitionFrom] as the controller's own current `LayoController.from`
  /// at this exact moment (see [_transitionFrom]'s own doc comment for why
  /// this snapshot, rather than reading `LayoController.from` fresh every
  /// frame, is what a re-base needs) and awaiting completion to settle.
  void _onControllerChanged() {
    if (!mounted) return;

    if (!_shouldAnimate) {
      setState(() {
        _settledEmotion = widget.controller.target;
        _transitionFrom = widget.controller.target;
      });
      _fadeController.value = 1.0;
      widget.controller.reportCurrent(_settledEmotion);
      return;
    }

    setState(() {
      _transitionFrom = widget.controller.from;
    });
    _playTransition();
  }

  /// Plays the crossfade captured by [_onControllerChanged] from `0.0` to
  /// `1.0`, reporting the interpolated progress back to
  /// [TransitionedLayo.controller] on every frame (via
  /// [_reportProgressToController], a plain [_fadeController] listener),
  /// then settles [_settledEmotion] on whichever emotion
  /// `LayoController.target` holds once the animation finishes.
  ///
  /// Re-checks `mounted` once the animation's own future completes so a
  /// transition in flight when this widget is disposed mid-animation neither
  /// calls `setState` after unmount nor reports a stale value to a
  /// controller this widget no longer owns a listener on. The returned
  /// future is deliberately not awaited by the caller
  /// ([_onControllerChanged]): a new [_onControllerChanged] call re-basing
  /// this transition simply calls [AnimationController.forward] again
  /// (`from: 0.0`), which redirects this in-flight future's own animation
  /// without throwing.
  void _playTransition() {
    _fadeController.forward(from: 0.0).then((_) {
      if (!mounted) return;
      setState(() {
        _settledEmotion = widget.controller.target;
      });
      widget.controller.reportCurrent(_settledEmotion);
    });
  }

  /// The mascot artwork's fixed width:height aspect ratio — identical to, and
  /// kept in step with, [Layo]'s own private constant of the same name and
  /// value.
  static const double _aspectRatio = 500 / 833;

  /// Whether [_fadeController] is currently mid-crossfade (strictly between
  /// its `0.0` and `1.0` rest points, or actively animating toward `1.0`) —
  /// the single condition [build] uses to decide between stacking the two
  /// crossfading [Layo]s and rendering a single settled one for
  /// [_settledEmotion].
  bool get _isTransitioning =>
      _fadeController.isAnimating || (_fadeController.value > 0.0 && _fadeController.value < 1.0);

  @override
  Widget build(BuildContext context) {
    if (!_isTransitioning) {
      return Layo(emotion: _settledEmotion, animate: widget.animate, width: widget.width);
    }

    // Two complete, independently-correct Layo widgets stacked and
    // crossfaded -- see the class doc comment's "Where the blend actually
    // happens" section for why this (rather than a painter-level blend) is
    // the chosen mechanism.
    final stack = AspectRatio(
      aspectRatio: _aspectRatio,
      child: Stack(
        fit: StackFit.expand,
        children: [
          FadeTransition(
            opacity: _outgoingOpacity,
            child: Layo(emotion: _transitionFrom, animate: widget.animate),
          ),
          FadeTransition(
            opacity: _fadeAnimation,
            child: Layo(emotion: widget.controller.target, animate: widget.animate),
          ),
        ],
      ),
    );

    if (widget.width == null) {
      return stack;
    }
    return SizedBox(width: widget.width, child: stack);
  }
}
