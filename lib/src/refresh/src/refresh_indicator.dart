import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:layrz_ui/src/buttons/buttons.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/platform/platform.dart';

import 'refresh_controller.dart';
import 'refresh_fallback_button_mode.dart';
import 'refresh_gesture_detector.dart';
import 'refresh_state.dart';
import 'refresh_visual.dart';

/// A loading affordance reporting a [LayrzRefreshController]'s refresh
/// lifecycle floating above a scrollable region of [child].
///
/// **What this is, despite the name**: the deliverable is the loading
/// affordance — controller, state machine, and indicator — not the drag
/// gesture. Kenny's own framing: *"a way to notify the loading state after a
/// drag to refresh action"* — the noun is the loading state; the drag is one
/// of two ways to reach it. [LayrzRefreshController.refresh] is the
/// always-available, primary entry point; the optional
/// [LayrzRefreshGestureDetector] wraps [child] only when [enableDragGesture]
/// is true, giving touch users the familiar pull affordance as a second path
/// into the exact same controller. A third path exists for pointer users
/// without a drag surface at all: see [fallbackButtonMode].
///
/// **Lifecycle:** if [controller] is null, this widget creates and disposes
/// its own; if non-null, the caller owns disposal and the instance must never
/// be swapped — an assertion fails if a different controller is passed on a
/// rebuild. This mirrors [LayrzStepper]'s controller contract exactly.
///
/// **Layout:** the indicator floats over [child] in a [Stack] rather than
/// occupying its own band — [child] is never resized or pushed down while the
/// indicator reveals or retracts. The reveal/retract animation is a fade
/// (opacity), not a layout size change, and respects reduce-motion via
/// [MediaQuery.disableAnimationsOf].
///
/// ```dart
/// LayrzRefreshIndicator(
///   controller: _refreshController,
///   onRefresh: () async {
///     await api.reloadData();
///   },
///   child: ListView(children: [...]),
/// )
///
/// // Elsewhere, a button drives the exact same loading affordance with no
/// // drag at all:
/// LayrzButton(
///   labelText: 'Refresh',
///   onTap: () => _refreshController.refresh(() => api.reloadData()),
/// )
/// ```
class LayrzRefreshIndicator extends StatefulWidget {
  /// Creates a [LayrzRefreshIndicator].
  const LayrzRefreshIndicator({
    required this.onRefresh,
    required this.child,
    this.controller,
    this.enableDragGesture = true,
    this.triggerDistance = 80.0,
    this.indicatorSize = 32.0,
    this.fallbackButtonMode = LayrzRefreshFallbackButtonMode.auto,
    super.key,
  });

  /// Called whenever a refresh starts, whether triggered by
  /// [LayrzRefreshController.refresh] directly, by the optional drag
  /// gesture, or by the fallback button (see [fallbackButtonMode]). The
  /// returned `Future` is awaited before the indicator settles.
  final Future<void> Function() onRefresh;

  /// The scrollable content this indicator floats above.
  final Widget child;

  /// Optional controller for programmatic refresh triggering.
  ///
  /// If null, this widget creates, owns and disposes an internal controller.
  /// If non-null, the caller owns disposal and the instance must never be
  /// swapped; an assertion fails if a different controller is passed on a
  /// rebuild. Hold a reference to a caller-supplied controller to call
  /// [LayrzRefreshController.refresh] from a button, shortcut, or app logic.
  final LayrzRefreshController? controller;

  /// Whether the optional touch drag gesture is wired up.
  ///
  /// Defaults to `true`. Set to `false` to expose only the programmatic
  /// [LayrzRefreshController.refresh] path — for example on a surface where
  /// a drag-to-refresh gesture would conflict with another gesture already
  /// installed on [child].
  final bool enableDragGesture;

  /// How far, in logical pixels, a drag must travel past the top of the
  /// scroll extent before releasing commits to a refresh. Ignored when
  /// [enableDragGesture] is `false`. See [LayrzRefreshGestureDetector.triggerDistance].
  final double triggerDistance;

  /// The diameter, in logical pixels, of the loading visual.
  final double indicatorSize;

  /// Whether a fallback "refresh" button floats over [child] alongside the
  /// pull gesture.
  ///
  /// A drag gesture needs a finger; a pointer-only session (desktop native,
  /// desktop web, or mobile web without a touchscreen) has no way to produce
  /// one at all. Rather than leaving that case to depend on an application
  /// developer remembering to wire up their own refresh button, the
  /// indicator can supply one itself.
  ///
  /// Defaults to [LayrzRefreshFallbackButtonMode.auto], which shows the
  /// button whenever [LayrzPlatform.isTouchOS] is `false` — see
  /// [LayrzRefreshFallbackButtonMode] for exactly what that covers and the
  /// tradeoff it accepts. Pass [LayrzRefreshFallbackButtonMode.enabled] or
  /// [LayrzRefreshFallbackButtonMode.disabled] to override the automatic
  /// decision outright.
  final LayrzRefreshFallbackButtonMode fallbackButtonMode;

  @override
  State<LayrzRefreshIndicator> createState() => _LayrzRefreshIndicatorState();
}

class _LayrzRefreshIndicatorState extends State<LayrzRefreshIndicator> with SingleTickerProviderStateMixin {
  late LayrzRefreshController _internalController;
  late LayrzRefreshController _effectiveController;
  late AnimationController _bandController;

  @override
  void initState() {
    super.initState();

    if (widget.controller != null) {
      _effectiveController = widget.controller!;
    } else {
      _internalController = LayrzRefreshController();
      _effectiveController = _internalController;
    }

    _bandController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
      value: 0.0,
    );

    _effectiveController.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(LayrzRefreshIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    assert(
      widget.controller == oldWidget.controller,
      'LayrzRefreshIndicator does not support changing the controller instance. '
      'The same controller must be passed, or null must remain null.',
    );
  }

  @override
  void dispose() {
    _effectiveController.removeListener(_onControllerChanged);
    _bandController.dispose();

    // Caller-supplied controllers are caller-disposed; see field doc on
    // [LayrzRefreshIndicator.controller].
    if (widget.controller == null) {
      _internalController.dispose();
    }

    super.dispose();
  }

  void _onControllerChanged() {
    if (!mounted) return;

    final state = _effectiveController.state;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    switch (state) {
      case LayrzRefreshState.idle:
      case LayrzRefreshState.armed:
        // Both states share the same handling: [dragProgress] is the single
        // source of truth for how far open the band should be while no
        // refresh has committed yet. This covers every path back to a fully
        // collapsed band, not just the ones that happen to route through
        // `armed` first —
        //
        // - a fresh, in-progress sub-threshold drag (state stays `idle`,
        //   `dragProgress` rising from 0): the band opens in step with it;
        // - that same drag reversed back toward the top before release
        //   (state stays or returns to `idle`, `dragProgress` falling back
        //   toward 0): the band retracts in step, instead of staying parked
        //   open at its high-water mark;
        // - a drag that *did* cross the threshold (`armed`) and is then
        //   released below it: [LayrzRefreshController.releaseDrag] resets
        //   `dragProgress` to 0.0 and reports `idle` again, which this case
        //   now also collapses.
        //
        // Previously `idle` was a no-op here, leaving `_bandController`
        // wherever `armed` had last set it — the ring stayed visually
        // stuck open even after the controller had correctly returned to
        // `idle`.
        _bandController.value = _effectiveController.dragProgress.clamp(0.0, 1.0);
      case LayrzRefreshState.refreshing:
        if (reduceMotion) {
          _bandController.value = 1.0;
        } else {
          _bandController.animateTo(1.0, curve: context.tokens.motion.easingEnter);
        }
      case LayrzRefreshState.settling:
        final retract = reduceMotion
            ? Future<void>.value()
            : _bandController.animateTo(0.0, curve: context.tokens.motion.easingExit);
        retract.whenComplete(() {
          if (reduceMotion) _bandController.value = 0.0;
          _effectiveController.settle();
        });
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final state = _effectiveController.state;

    Widget content = widget.child;

    if (widget.enableDragGesture) {
      content = LayrzRefreshGestureDetector(
        controller: _effectiveController,
        onRefresh: widget.onRefresh,
        triggerDistance: widget.triggerDistance,
        child: content,
      );
    }

    return Stack(
      // `StackFit.passthrough` forwards this `Stack`'s own incoming
      // constraints straight to `content` below, instead of the default
      // `StackFit.loose`'s "as small as possible" box. `content` is
      // deliberately the sole *non-positioned* child (see below) so it is
      // the one that determines the `Stack`'s size -- but a `Stack` with only
      // positioned children (as this used to be, via `Positioned.fill`)
      // never contributes to sizing at all, and collapses to zero in any
      // axis where the ambient constraint is not already tight. That is
      // silent: no exception, no overflow banner, just an invisible list --
      // exactly the regression a caller hit on a physical device inside a
      // plain `Column` with no `Expanded`. `passthrough` restores the
      // constraints `content` (typically a scrollable that wants to fill
      // its parent) would have received with no `Stack` in between at all,
      // matching this widget's pre-Stack layout in both the bounded case
      // (e.g. wrapped in `Expanded`) and the unbounded one -- where an
      // unbounded scrollable is a pre-existing Flutter layout error on its
      // own, `LayrzRefreshIndicator` included or not, and now fails loudly
      // instead of silently disappearing.
      fit: StackFit.passthrough,
      children: [
        // The scrollable never resizes or shifts to make room for the
        // indicator or fallback button — both float on top of it. `content`
        // is intentionally NOT wrapped in `Positioned.fill`: a `Stack` sizes
        // itself to its largest non-positioned child, so this is the child
        // that gives the `Stack` a size at all. The overlays below stay
        // `Positioned` and float independently, never displacing it.
        content,
        Positioned(
          top: context.tokens.spacing.sp2,
          left: 0,
          right: 0,
          child: Center(
            child: AnimatedBuilder(
              animation: _bandController,
              builder: (context, _) {
                // A committed refresh (`refreshing`/`settling`) always shows
                // the visual, even in the single frame before the reveal
                // animation has advanced past 0.0 -- that is exactly when its
                // live-region announcement matters most. Outside of that, the
                // visual tracks the raw drag: present while there is
                // something to show (`dragProgress > 0.0`, or `armed`, which
                // implies `dragProgress >= 1.0` anyway), and genuinely absent
                // from the tree otherwise -- not merely faded out. An
                // abandoned or reversed pull must leave nothing behind for a
                // test (or a screen reader) to find; see the regression tests
                // in refresh_indicator_test.dart for exactly the bug this
                // guards.
                final isCommitted = state == LayrzRefreshState.refreshing || state == LayrzRefreshState.settling;
                final hasDragProgress = _effectiveController.dragProgress > 0.0 || state == LayrzRefreshState.armed;

                if (!isCommitted && !hasDragProgress) {
                  return const SizedBox.shrink();
                }

                return IgnorePointer(
                  child: AnimatedOpacity(
                    opacity: _bandController.value,
                    duration: Duration.zero,
                    // At the instant a refresh starts, `_bandController.value`
                    // is still 0.0 until the reveal animation has advanced by
                    // at least one duration-carrying frame -- exactly the
                    // moment the [LayrzRefreshVisual]'s live-region
                    // announcement matters most. `AnimatedOpacity` (via
                    // `RenderOpacity`) excludes semantics outright at opacity
                    // 0.0 unless told not to.
                    alwaysIncludeSemantics: true,
                    // The elevated surface lives here, one level above the
                    // ring itself -- not inside `LayrzRefreshVisual`, which is
                    // reused unadorned by `_FallbackRefreshButton` below for
                    // its own loading state. Baking a surface into the visual
                    // would give that button a nested circle-on-a-circle.
                    // It is also gated by the exact same `isCommitted` /
                    // `hasDragProgress` check that gates the ring, and lives
                    // inside the same `AnimatedOpacity`/fade -- so it never
                    // outlives the ring: it is present exactly when, and only
                    // when, the ring itself is.
                    child: _RefreshFloatingSurface(
                      size: widget.indicatorSize,
                      child: LayrzRefreshVisual(
                        key: const ValueKey('layrz-refresh-pull-visual'),
                        state: state,
                        dragProgress: _effectiveController.dragProgress,
                        size: widget.indicatorSize,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        _FallbackRefreshButton(
          controller: _effectiveController,
          onRefresh: widget.onRefresh,
          mode: widget.fallbackButtonMode,
          indicatorSize: widget.indicatorSize,
        ),
      ],
    );
  }
}

/// The elevated circular surface painted behind the floating pull indicator.
///
/// Before this, the pull ring floated directly over the scrolling list with
/// nothing behind it -- reported from a physical device as reading "strange",
/// with no visual separation from the rows passing underneath. This gives it
/// the conventional pull-to-refresh treatment: a raised disc the ring sits
/// on, so it reads as an object hovering above the list rather than a glyph
/// painted onto it.
///
/// Deliberately not a public widget and not a parameter on
/// [LayrzRefreshIndicator]: this is purely the pull indicator's own
/// presentation, with no reason yet for a caller to reach in and change it.
///
/// **Elevation choice:** the [LayrzShadowTokens] compact ramp (`compact1`),
/// not the elevation ramp -- this is a small floating affordance sized to
/// [size], the same category the [LayrzShadowTokens] doc comment names
/// ("buttons, chips, menu items, badges"), not a card or sheet. `compact1` is
/// also the exact resting shadow [LayrzButtonStyle.filledFab] resolves to,
/// which is what the sibling [_FallbackRefreshButton] already renders in this
/// same overlay slot -- matching it here is what makes the two read as
/// consistent siblings instead of two different elevation languages floating
/// side by side.
///
/// **Surface color:** [LayrzColorTokens.sf1], the same raised-surface default
/// [LayrzCard] uses. [LayrzRefreshVisual] already paints its own ring track
/// in `sf3`, so `sf1` reads as a distinct, lighter disc behind it rather than
/// blending into the ring's own track color.
class _RefreshFloatingSurface extends StatelessWidget {
  /// Creates a [_RefreshFloatingSurface].
  const _RefreshFloatingSurface({
    required this.size,
    required this.child,
  });

  /// The diameter, in logical pixels, of the [LayrzRefreshVisual] this
  /// surface sits behind. The surface itself is sized larger than this by a
  /// fixed padding so the ring reads as inset within it, not edge-to-edge.
  final double size;

  /// The [LayrzRefreshVisual] painted on top of this surface.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Container(
      padding: EdgeInsets.all(tokens.spacing.sp2),
      decoration: BoxDecoration(
        color: tokens.colors.sf1,
        shape: BoxShape.circle,
        boxShadow: tokens.shadow.compact1,
      ),
      child: SizedBox(width: size, height: size, child: child),
    );
  }
}

/// The optional pointer-only fallback affordance floated by
/// [LayrzRefreshIndicator] over the top-centre of its [Stack], in the same
/// slot the pull indicator occupies.
///
/// Visibility is resolved from [mode]: [LayrzRefreshFallbackButtonMode.auto]
/// reads [LayrzPlatform.isTouchOS] once per build (a static, non-subscribed
/// check — see [LayrzRefreshFallbackButtonMode] for the full reasoning),
/// showing the button exactly when the OS is not Android/iOS. The other two
/// modes force the button on or off outright, ignoring that read.
class _FallbackRefreshButton extends StatelessWidget {
  /// Creates a [_FallbackRefreshButton].
  const _FallbackRefreshButton({
    required this.controller,
    required this.onRefresh,
    required this.mode,
    required this.indicatorSize,
  });

  /// The controller this button's tap drives via [LayrzRefreshController.refresh].
  final LayrzRefreshController controller;

  /// The same refresh callback [LayrzRefreshIndicator.onRefresh] awaits for
  /// every other trigger path.
  final Future<void> Function() onRefresh;

  /// Which visibility policy governs this button; see
  /// [LayrzRefreshFallbackButtonMode].
  final LayrzRefreshFallbackButtonMode mode;

  /// The diameter, in logical pixels, of the loading ring shown in place of
  /// the button's icon while a refresh triggered from it is in flight.
  final double indicatorSize;

  bool get _isVisible => switch (mode) {
    LayrzRefreshFallbackButtonMode.enabled => true,
    LayrzRefreshFallbackButtonMode.disabled => false,
    LayrzRefreshFallbackButtonMode.auto => !LayrzPlatform.isTouchOS,
  };

  Future<void> _handleTap() {
    return controller.refresh(onRefresh);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final isRefreshing = controller.isRefreshing;

        return Positioned(
          top: context.tokens.spacing.sp2,
          right: context.tokens.spacing.sp2,
          // While refreshing, [LayrzRefreshVisual] doesn't itself carry a
          // "button" semantic (it is a passive loading ring elsewhere), so an
          // explicit label is supplied here. Once interactive again,
          // [LayrzButton] already provides its own full `button: true` +
          // `label` semantics -- wrapping it again here would just duplicate
          // the same label under two merged nodes.
          child: isRefreshing
              ? Semantics(
                  label: 'Refresh',
                  hint: 'Refreshing',
                  button: true,
                  enabled: false,
                  child: Padding(
                    padding: EdgeInsets.all(context.tokens.spacing.sp2),
                    child: LayrzRefreshVisual(
                      key: const ValueKey('layrz-refresh-fallback-button-visual'),
                      state: controller.state,
                      dragProgress: 0.0,
                      size: indicatorSize,
                    ),
                  ),
                )
              // `Actions` alone (not `FocusableActionDetector`) is deliberate
              // here: `LayrzButton` already installs its own
              // `FocusableActionDetector` internally, so it already owns the
              // one `Focus` node this affordance should have. Wrapping it in
              // a second `FocusableActionDetector` would add a second,
              // independently focusable node around the same button --  a
              // real double-tab-stop regression, not a harmless no-op. This
              // widget only needs to teach that existing focus node's
              // `Actions` lookup how to handle `ActivateIntent`, which plain
              // `Actions` does without creating any focus node of its own.
              : Actions(
                  actions: <Type, Action<Intent>>{
                    ActivateIntent: CallbackAction<ActivateIntent>(
                      onInvoke: (_) {
                        _handleTap();
                        return null;
                      },
                    ),
                  },
                  child: LayrzButton(
                    labelText: 'Refresh',
                    icon: MdiIcons.refresh,
                    style: LayrzButtonStyle.filledFab,
                    onTap: _handleTap,
                  ),
                ),
        );
      },
    );
  }
}
