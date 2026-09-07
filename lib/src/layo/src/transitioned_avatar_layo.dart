import 'package:flutter/widgets.dart';

import 'avatar_layo.dart';
import 'layo_avatar_shape.dart';
import 'layo_controller.dart';
import 'layo_emotion.dart';
import 'transitioned_layo.dart';

/// The avatar-framed counterpart to [TransitionedLayo]: a head-and-shoulders
/// portrait avatar (framed exactly like [AvatarLayo]) whose face **crossfades**
/// between emotions when driven by a [LayoController], and whose fixed
/// per-emotion background and ring colors **also transition** — smoothly
/// [Color.lerp]-ing between the outgoing and incoming emotion's own colors
/// over the same crossfade, instead of jumping straight to the target
/// palette the instant the face starts to change.
///
/// [TransitionedAvatarLayo] is purely compositional, exactly like
/// [AvatarLayo] and [TransitionedLayo] themselves: it reimplements neither.
/// It reuses [AvatarLayo]'s own frame-building geometry directly (via
/// [AvatarLayo.buildFrame] — the same clip/crop/ring math [AvatarLayo] itself
/// calls, so there is only ever one implementation of "how the avatar frame
/// is built") around a [TransitionedLayo] standing in for the plain [Layo]
/// [AvatarLayo] would otherwise place there, so the crossfade behavior itself
/// is entirely [TransitionedLayo]'s own, untouched.
///
/// # The background/ring lerp
///
/// A plain composition — an [AvatarLayo] frame whose fill/ring never change,
/// simply wrapping a [TransitionedLayo] — would crossfade the *face* but snap
/// the *background and ring* to the target emotion's colors the instant a
/// transition starts, which reads as visually inconsistent (the face fading
/// smoothly while the backdrop behind it jump-cuts). [TransitionedAvatarLayo]
/// avoids this by resolving its own fill and ring colors every frame as
/// `Color.lerp(avatarBackgroundFor(from), avatarBackgroundFor(target), t)`
/// (and the ring equivalently via [avatarRingFor]), where `t` is read
/// straight from [controller]'s own crossfade progress — see
/// [_TransitionedAvatarLayoState] for how that progress is obtained without
/// this widget owning a second, redundant [AnimationController] of its own.
/// [avatarBackgroundFor] and [avatarRingFor] are [AvatarLayo]'s own public
/// per-[LayoEmotion] color resolvers (widened from `avatar_layo.dart`-private
/// functions specifically so this widget could reuse them), so both widgets
/// read from the exact same palette — there is no second copy of the
/// emotion-to-color mapping anywhere in this composition.
///
/// # Reduced motion
///
/// Exactly like [TransitionedLayo]: when [animate] is `false`, or the
/// platform's own `MediaQuery.disableAnimations` reports `true`, an emotion
/// change is a **hard cut** — the face, background, and ring all jump
/// straight to the target emotion's values on the very next frame, with no
/// crossfade or color lerp of any kind ever played.
///
/// # Sizing and shape
///
/// [TransitionedAvatarLayo] is size-automatic and always square (1:1),
/// exactly like [AvatarLayo] — see that class's own doc comment for the full
/// sizing contract. [shape] selects the same [LayoAvatarShape] silhouette
/// [AvatarLayo] itself offers.
///
/// **The background is fixed per emotion, not a parameter**, exactly as
/// [AvatarLayo] documents: there is no `backgroundColor` (or
/// `ringColor`) parameter here either — both are always derived from
/// whichever emotions [controller] is transitioning between.
///
/// See also:
///   - [AvatarLayo], the static avatar frame this widget reuses.
///   - [TransitionedLayo], the crossfading mascot this widget wraps.
///   - [LayoController], the controller driving both.
class TransitionedAvatarLayo extends StatefulWidget {
  /// Creates a new [TransitionedAvatarLayo].
  ///
  /// The [controller] parameter is required: the same [LayoController]
  /// passed to the inner [TransitionedLayo], whose `LayoController.from`/
  /// `LayoController.target` this widget also reads directly to resolve its
  /// own in-flight background/ring lerp.
  ///
  /// The [shape] parameter is optional and defaults to
  /// [LayoAvatarShape.circle], matching [AvatarLayo]'s own default.
  ///
  /// The [initialEmotion] parameter is optional and defaults to
  /// [LayoEmotion.mrLayo]; forwarded to the inner [TransitionedLayo] as its
  /// own `TransitionedLayo.initialEmotion` — see that parameter's own doc
  /// comment for exactly when it matters versus [controller]'s own starting
  /// state.
  ///
  /// The [width] parameter is optional; when null, [TransitionedAvatarLayo]
  /// fills the width its parent provides, exactly like [AvatarLayo.width].
  ///
  /// The [animate] parameter is optional and defaults to `true`; forwarded to
  /// the inner [TransitionedLayo] (and, through it, every [Layo] it builds)
  /// and also gates whether this widget's own background/ring lerp plays or
  /// hard-cuts — see the class doc comment's "Reduced motion" section.
  const TransitionedAvatarLayo({
    required this.controller,
    this.shape = LayoAvatarShape.circle,
    this.initialEmotion = LayoEmotion.mrLayo,
    this.width,
    this.animate = true,
    super.key,
  });

  /// The controller driving which transition this widget animates.
  ///
  /// Passed straight through to the inner [TransitionedLayo] as its own
  /// `TransitionedLayo.controller`; this widget additionally listens to it
  /// directly (in `State.initState`) so it can re-resolve its own
  /// background/ring lerp on every notification, exactly as
  /// [TransitionedLayo] itself does for the face crossfade. Disposal remains
  /// caller-owned, matching every other controller in this design system.
  final LayoController controller;

  /// Which silhouette this avatar clips itself to.
  ///
  /// Defaults to [LayoAvatarShape.circle]. Passed straight through to
  /// [AvatarLayo.buildFrame] on every frame; applies to the lerped
  /// background fill, the lerped ring, and the clip boundary alike.
  final LayoAvatarShape shape;

  /// The emotion shown before [controller] has been read.
  ///
  /// Defaults to [LayoEmotion.mrLayo]. Forwarded to the inner
  /// [TransitionedLayo] as its own `TransitionedLayo.initialEmotion` — see
  /// that parameter's own doc comment for the precise role it plays.
  final LayoEmotion initialEmotion;

  /// Optional explicit width (and, since this widget is always square,
  /// height) in logical pixels.
  ///
  /// When null, [TransitionedAvatarLayo] fills the width its parent provides
  /// and derives its height from that same width, exactly as
  /// [AvatarLayo.width] documents.
  final double? width;

  /// Whether the inner [TransitionedLayo] animates its face crossfade, and
  /// whether this widget's own background/ring [Color.lerp] plays.
  ///
  /// Defaults to `true`. Even when `true`, the platform's reduced-motion
  /// preference (`MediaQuery.disableAnimations`) forces a hard cut across
  /// all three (face, background, ring) without the caller needing to do
  /// anything — see the class doc comment's "Reduced motion" section.
  final bool animate;

  @override
  State<TransitionedAvatarLayo> createState() => _TransitionedAvatarLayoState();
}

/// State for [TransitionedAvatarLayo]: listens to
/// [TransitionedAvatarLayo.controller] purely to trigger a rebuild whenever
/// the controller's own `LayoController.from`/`LayoController.target` change,
/// so this widget's `build` can re-resolve its background/ring lerp — the
/// actual `0..1` progress value itself is read from the inner
/// [TransitionedLayo] indirectly is NOT possible (it owns a private
/// [AnimationController] of its own), so this state instead owns its own
/// second, identically-configured [AnimationController] driving the same
/// ~280ms crossfade in lockstep, purely to supply `t` to [Color.lerp] here.
///
/// Two independent [AnimationController]s (this one, and
/// [TransitionedLayo]'s own private one) end up perfectly in sync because
/// both are started from `0.0` on the same
/// [LayoController] notification, run the same [Curves.easeInOut] curve over
/// the same fixed duration, and neither is ever paused or seeked
/// independently of the other — so the face crossfade and the color lerp
/// always reach `1.0` on the same frame.
class _TransitionedAvatarLayoState extends State<TransitionedAvatarLayo> with SingleTickerProviderStateMixin {
  /// Drives this widget's own background/ring lerp progress, `0.0` to `1.0`,
  /// over the same fixed ~280ms duration [TransitionedLayo] itself uses for
  /// its face crossfade, restarted from `0.0` on every
  /// [TransitionedAvatarLayo.controller] notification via
  /// [_onControllerChanged] — see this class's own doc comment for why this
  /// widget owns a second controller rather than reading
  /// [TransitionedLayo]'s private one.
  late final AnimationController _colorController;

  /// [_colorController]'s own [Curves.easeInOut]-eased value, matching
  /// [TransitionedLayo]'s own internal easing exactly so the color lerp and
  /// the face crossfade always read as one single, synchronized transition
  /// rather than two effects drifting out of step.
  late final Animation<double> _colorAnimation;

  /// The emotion the currently in-flight (or just-started) color lerp is
  /// fading **from** — captured once per [_onControllerChanged] call, for
  /// exactly the same re-basing reason [TransitionedLayo]'s own
  /// `_transitionFrom` field is: a later re-basing `LayoController.to` call
  /// must not retroactively change what this specific already-in-flight lerp
  /// started from.
  late LayoEmotion _lerpFrom;

  /// The fixed ~280ms duration both this widget's [_colorController] and
  /// [TransitionedLayo]'s own private crossfade controller use — kept as a
  /// named constant here (rather than a bare literal) so the "these two
  /// controllers must stay in lockstep" contract this class's doc comment
  /// describes has one single place backing it.
  static const Duration _kTransitionDuration = Duration(milliseconds: 280);

  @override
  void initState() {
    super.initState();
    _lerpFrom = widget.controller.from;
    _colorController = AnimationController(vsync: this, duration: _kTransitionDuration);
    _colorAnimation = CurvedAnimation(parent: _colorController, curve: Curves.easeInOut);
    widget.controller.addListener(_onControllerChanged);
    if (widget.controller.from != widget.controller.target) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _onControllerChanged());
    }
  }

  @override
  void didUpdateWidget(covariant TransitionedAvatarLayo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
      _lerpFrom = widget.controller.from;
      _colorController.value = widget.controller.from == widget.controller.target ? 1.0 : 0.0;
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _colorController.dispose();
    super.dispose();
  }

  /// Whether this widget currently animates its background/ring lerp:
  /// [TransitionedAvatarLayo.animate] is `true` and the platform is not
  /// asking for reduced motion. Mirrors [TransitionedLayo]'s own
  /// `_shouldAnimate` gate exactly, so both widgets always agree on whether
  /// the current transition is animated or a hard cut.
  bool get _shouldAnimate => widget.animate && !(MediaQuery.maybeOf(context)?.disableAnimations ?? false);

  /// Called whenever [TransitionedAvatarLayo.controller] notifies — i.e.
  /// every `LayoController.to` call, whether starting a fresh transition or
  /// re-basing one already in flight.
  ///
  /// When [_shouldAnimate] is `false`, this performs a hard cut: the color
  /// lerp jumps straight to `1.0` (so `build` resolves the target emotion's
  /// colors with no intermediate frame) and no [_colorController] animation
  /// ever plays. Otherwise, it restarts [_colorController] from `0.0`,
  /// capturing [_lerpFrom] fresh — mirroring [TransitionedLayo]'s own
  /// `_onControllerChanged` exactly, so both controllers restart on the same
  /// notification and reach `1.0` on the same frame.
  void _onControllerChanged() {
    if (!mounted) return;

    if (!_shouldAnimate) {
      setState(() {
        _lerpFrom = widget.controller.target;
      });
      _colorController.value = 1.0;
      return;
    }

    setState(() {
      _lerpFrom = widget.controller.from;
    });
    _colorController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final content = LayoutBuilder(
      builder: (context, constraints) {
        final side = constraints.maxWidth;
        return AnimatedBuilder(
          animation: _colorAnimation,
          builder: (context, _) {
            final t = _colorAnimation.value;
            final fillColor = Color.lerp(
              avatarBackgroundFor(_lerpFrom),
              avatarBackgroundFor(widget.controller.target),
              t,
            )!;
            final ringColor = Color.lerp(
              avatarRingFor(_lerpFrom),
              avatarRingFor(widget.controller.target),
              t,
            )!;
            return AvatarLayo.buildFrame(
              side: side,
              shape: widget.shape,
              fillColor: fillColor,
              ringColor: ringColor,
              mascotBuilder: (layoWidth) => TransitionedLayo(
                controller: widget.controller,
                initialEmotion: widget.initialEmotion,
                width: layoWidth,
                animate: widget.animate,
              ),
            );
          },
        );
      },
    );

    if (widget.width case final explicitWidth?) {
      return SizedBox(
        width: explicitWidth,
        height: explicitWidth,
        child: content,
      );
    }

    return AspectRatio(
      aspectRatio: 1.0,
      child: content,
    );
  }
}
