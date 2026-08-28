import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';

import 'refresh_controller.dart';
import 'refresh_gesture_detector.dart';
import 'refresh_state.dart';
import 'refresh_visual.dart';

/// A loading affordance reporting a [LayrzRefreshController]'s refresh
/// lifecycle above a scrollable region of [child].
///
/// **What this is, despite the name**: the deliverable is the loading
/// affordance — controller, state machine, and indicator — not the drag
/// gesture. Kenny's own framing: *"a way to notify the loading state after a
/// drag to refresh action"* — the noun is the loading state; the drag is one
/// of two ways to reach it. [LayrzRefreshController.refresh] is the
/// always-available, primary entry point; the optional
/// [LayrzRefreshGestureDetector] wraps [child] only when [enableDragGesture]
/// is true, giving touch users the familiar pull affordance as a second path
/// into the exact same controller.
///
/// **Lifecycle:** if [controller] is null, this widget creates and disposes
/// its own; if non-null, the caller owns disposal and the instance must never
/// be swapped — an assertion fails if a different controller is passed on a
/// rebuild. This mirrors [LayrzStepper]'s controller contract exactly.
///
/// **Layout:** the indicator is painted in a fixed-height band above [child],
/// which is itself unaffected — no resistance/overscroll physics reshape the
/// scrollable in v1 (see [LayrzRefreshController] for the state machine this
/// composes). The band animates open on [LayrzRefreshState.refreshing] and
/// closed again once [LayrzRefreshState.settling] completes, respecting
/// reduce-motion via [MediaQuery.disableAnimationsOf].
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
    super.key,
  });

  /// Called whenever a refresh starts, whether triggered by
  /// [LayrzRefreshController.refresh] directly or by the optional drag
  /// gesture. The returned `Future` is awaited before the indicator settles.
  final Future<void> Function() onRefresh;

  /// The scrollable content this indicator sits above.
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
        break;
      case LayrzRefreshState.armed:
        _bandController.value = _effectiveController.dragProgress;
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

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizeTransition(
          sizeFactor: _bandController,
          alignment: const Alignment(-1.0, -1.0),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: context.tokens.spacing.sp2),
            child: Center(
              child: LayrzRefreshVisual(
                state: state,
                dragProgress: _effectiveController.dragProgress,
                size: widget.indicatorSize,
              ),
            ),
          ),
        ),
        Expanded(child: content),
      ],
    );
  }
}
