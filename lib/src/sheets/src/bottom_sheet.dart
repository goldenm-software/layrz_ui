import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:layrz_ui/src/extensions/extensions.dart';

/// A modal or persistent bottom sheet component for presenting content above the page.
///
/// [LayrzBottomSheet] provides a customizable bottom sheet that can be either:
/// - **Modal** ([isPersistent] = `false`, default): displays with a semi-transparent barrier,
///   the page is not interactive while the sheet is open, pressing Escape dismisses the sheet
/// - **Persistent** ([isPersistent] = `true`): no barrier, the page remains interactive,
///   useful for supplementary UI that coexists with the main content
///
/// The sheet is draggable by the drag handle (when [showDragHandle] is true): dragging it
/// resizes the sheet across [minSize], [snapSizes] and [maxSize] exactly as dragging the
/// sheet's own content does, and dragging past the lowest snap point dismisses the sheet.
/// Uses [DraggableScrollableSheet] internally to avoid the classic trap of hand-rolling
/// the drag/scroll handoff — it solves that problem directly.
///
/// The sheet respects accessibility requirements:
/// - Focus moves into the sheet on open and returns to the invoker on close
/// - Escape dismisses modal sheets
/// - Reduce-motion is respected: slide transition is shortened or skipped if
///   [MediaQuery.of(context).disableAnimations] is true
/// - The drag must never be the only route to content; the initial size shows the primary
///   content, and content scrolls independently of the drag
///
/// **Example usage** (a simple picker):
/// ```dart
/// final selected = await LayrzBottomSheet.show<String>(
///   context,
///   builder: (context) => Column(
///     children: options.map((o) => Text(o)).toList(),
///   ),
/// );
/// ```
class LayrzBottomSheet {
  LayrzBottomSheet._();

  /// Shows a bottom sheet and returns the result.
  ///
  /// Returns `Future<T?>` that completes with the value passed to [Navigator.pop]
  /// in the sheet, or `null` if the sheet is dismissed without a value.
  ///
  /// **Parameters:**
  /// - [context]: the build context from which to show the sheet. Must contain a Navigator.
  /// - [builder]: a builder function that constructs the sheet's content. The builder
  ///   receives the sheet context as an argument.
  /// - [isPersistent]: whether the sheet is persistent (no barrier, page stays interactive)
  ///   or modal (barrier present, page not interactive). Defaults to `false` (modal).
  /// - [semanticLabel]: optional semantic label for screen readers announcing the sheet.
  ///   For modal sheets, this should describe the purpose and exit mechanism
  ///   (e.g., "Choose an option. Press Escape to close."). This label is required
  ///   when [isPersistent] is false to announce the modal dialog role to screen readers
  ///   and communicate the exit path. Must be localized by the caller. If not provided,
  ///   no dialog semantics are added, preventing a focus trap without announcement.
  ///   Ignored for persistent sheets. Defaults to `null`.
  /// - [snapSizes]: optional list of snap point fractions (0.0 to 1.0) in ascending order.
  ///   Constraints are enforced:
  ///   - List must not be empty
  ///   - All values must be between [minSize] and [maxSize] inclusive
  ///   - Values must be in ascending order
  ///   - An assertion fires at the call site if constraints are violated
  ///   If null, defaults to `[0.5, 0.95]` (half-height and near-full-height snap points, respecting the 0.95 maxSize default).
  /// - [initialSize]: the fraction of the screen height the sheet initially occupies.
  ///   Defaults to 0.5 (half the screen). Must be between [minSize] and [maxSize].
  /// - [minSize]: the minimum fraction of screen height the sheet can be dragged down to.
  ///   Defaults to 0.25 (a quarter of the screen). Useful for showing a minimum
  ///   indicator or handle.
  /// - [maxSize]: the maximum fraction of screen height the sheet can occupy.
  ///   Defaults to 0.95 (leaving minimal space for status bar / app bar).
  /// - [showDragHandle]: whether to render a visual drag handle above the content.
  ///   Defaults to `true`. When true, the entire header region (not just the visible
  ///   pill) is draggable, and dragging it resizes the sheet the same way dragging the
  ///   content does — more forgiving than a handle-only hit target, which is easy to
  ///   miss on touch.
  /// - [useRootNavigator]: whether to use the root navigator instead of the nearest one.
  ///   Defaults to `false`. Set to `true` when showing from a context that does not have
  ///   its own navigator (e.g. a nested route on desktop).
  /// - [scrollable]: whether the sheet wraps [builder]'s content in its own
  ///   [SingleChildScrollView]. Defaults to `true`, which preserves this method's original
  ///   behaviour exactly: the content is wrapped and the sheet's drag/scroll-handoff
  ///   [ScrollController] is attached to that wrapper, so a non-scrolling builder (e.g. a
  ///   `Column`) needs no changes to work.
  ///   Set to `false` when [builder] returns its own scrollable (e.g. a `ListView` or
  ///   `GridView`) — the sheet then hands that [ScrollController] to [builder] instead of
  ///   wrapping it. This exists because a same-axis scrollable nested inside the sheet's own
  ///   `SingleChildScrollView` is given unbounded height by its parent and asserts
  ///   (`Vertical viewport was given unbounded height`); `scrollable: false` is the
  ///   escape hatch so the next caller that reaches for a lazy list finds this flag
  ///   instead of that crash.
  ///   The controller is handed down via [PrimaryScrollController], so a **vertical**
  ///   scrollable in [builder] that sets no `controller` of its own picks it up
  ///   implicitly — that is what gives it the sheet's drag/scroll handoff without an
  ///   explicit wire-up. A caller that wants a *different* controller (e.g. to also
  ///   read its own scroll offset) must pass one explicitly on that scrollable, which
  ///   opts it out of inheriting this one. A **horizontal** scrollable never inherits
  ///   it regardless — [PrimaryScrollController.shouldInherit] only matches a
  ///   [ScrollView] whose `scrollDirection` is [Axis.vertical] — so it keeps its own
  ///   ordinary controller and does not participate in the handoff. If [builder]
  ///   nests a second vertical scrollable inside the first, only the outer one
  ///   inherits (the SDK inserts [PrimaryScrollController.none] below it precisely to
  ///   prevent a descendant from claiming the same controller); the inner one scrolls
  ///   independently, with no drag handoff of its own.
  static Future<T?> show<T>(
    BuildContext context, {
    required WidgetBuilder builder,
    bool isPersistent = false,
    String? semanticLabel,
    List<double>? snapSizes,
    double initialSize = 0.5,
    double minSize = 0.25,
    double maxSize = 0.95,
    bool showDragHandle = true,
    bool useRootNavigator = false,
    bool scrollable = true,
  }) {
    // Validate sizing constraints
    assert(
      minSize <= maxSize,
      'minSize ($minSize) must not exceed maxSize ($maxSize).',
    );

    assert(
      initialSize >= minSize && initialSize <= maxSize,
      'initialSize must be between minSize ($minSize) and maxSize ($maxSize). '
      'Got $initialSize.',
    );

    // Validate snapSizes constraints
    if (snapSizes != null) {
      assert(
        snapSizes.isNotEmpty,
        'snapSizes must not be empty when supplied.',
      );

      // Check all values are within bounds
      for (final size in snapSizes) {
        assert(
          size >= minSize && size <= maxSize,
          'Every entry in snapSizes must lie within minSize ($minSize)..maxSize ($maxSize). '
          'Got $size.',
        );
      }

      // Check ascending order
      for (int i = 1; i < snapSizes.length; i++) {
        assert(
          snapSizes[i] > snapSizes[i - 1],
          'snapSizes must be in ascending order. Got $snapSizes.',
        );
      }
    }

    // Use default snap sizes if not provided
    final effectiveSnapSizes = snapSizes ?? [0.5, 0.95];

    final navigator = Navigator.of(
      context,
      rootNavigator: useRootNavigator,
    );

    return navigator.push<T>(
      _BottomSheetRoute<T>(
        builder: builder,
        isPersistent: isPersistent,
        semanticLabel: semanticLabel,
        snapSizes: effectiveSnapSizes,
        initialSize: initialSize,
        minSize: minSize,
        maxSize: maxSize,
        showDragHandle: showDragHandle,
        scrollable: scrollable,
      ),
    );
  }
}

/// Internal route class for managing the bottom sheet presentation.
///
/// Extends [RawDialogRoute] to leverage the barrier painting, focus management,
/// and transition infrastructure already built into the SDK's dialog system.
/// [RawDialogRoute] provides:
/// - Barrier painting and dismissal on tap
/// - Automatic focus trap and restoration
/// - Transition builders and page builders
/// - Semantic semantics for accessibility
class _BottomSheetRoute<T> extends RawDialogRoute<T> {
  /// Whether the sheet is persistent (no barrier) or modal.
  final bool isPersistent;

  /// Semantic label for screen readers (caller-supplied, optional).
  final String? semanticLabel;

  /// Creates a new bottom sheet route.
  _BottomSheetRoute({
    required WidgetBuilder builder,
    required this.isPersistent,
    required this.semanticLabel,
    required List<double> snapSizes,
    required double initialSize,
    required double minSize,
    required double maxSize,
    required bool showDragHandle,
    required bool scrollable,
  }) : super(
         pageBuilder: (context, animation, secondaryAnimation) {
           return _BottomSheetContent(
             builder: builder,
             isPersistent: isPersistent,
             semanticLabel: semanticLabel,
             snapSizes: snapSizes,
             initialSize: initialSize,
             minSize: minSize,
             maxSize: maxSize,
             showDragHandle: showDragHandle,
             scrollable: scrollable,
           );
         },
         barrierDismissible: !isPersistent,
         barrierColor: const Color(0x00000000), // Transparent initially
         transitionBuilder: (context, animation, secondaryAnimation, child) {
           // Determine barrier color based on isPersistent flag
           final barrierColor = !isPersistent
               ? context.tokens.colors.overlay.withValues(alpha: 0.5)
               : const Color(0x00000000);

           // Respect reduce-motion by shortening or skipping the transition
           final disableAnimations = MediaQuery.of(context).disableAnimations;
           final effectiveAnimation = disableAnimations ? AlwaysStoppedAnimation(1.0) : animation;

           return Stack(
             children: [
               // Barrier
               if (!isPersistent)
                 GestureDetector(
                   // Explicit for clarity/defensiveness: Container(color: ...) already
                   // builds a ColoredBox, whose render object (_RenderColoredBox) is
                   // unconditionally HitTestBehavior.opaque regardless of alpha — so this
                   // barrier already blocks hits to whatever sits behind it in the Stack,
                   // with or without this line. Kept explicit so the GestureDetector's own
                   // hit-testing contract does not silently depend on an implementation
                   // detail of its child. This also means the barrier absorbs MORE taps
                   // than before, not fewer — which is exactly why the guard below is not
                   // optional once this line is present: a barrier that reliably catches
                   // every tap needs to reliably refuse to act on ones it should not.
                   behavior: HitTestBehavior.opaque,
                   onTap: () {
                     // transitionBuilder (this whole Stack) renders for the ENTIRE
                     // transition, including the exit/dismiss animation — the barrier
                     // stays mounted and hit-testable while the sheet slides out. A
                     // second fast tap during that window would otherwise call pop()
                     // on a route that is already popping, which — under go_router —
                     // throws 'currentConfiguration.isNotEmpty' trying to remove the
                     // last page off the stack, or re-enters the Navigator mid-pop
                     // ('!_debugLocked'). ModalRoute.of(context)?.isCurrent is the
                     // SDK's own purpose-built answer to "is this route still the one
                     // to pop" — it is what the barrier's onTap should have always been
                     // conditioned on, independent of the opaque fix above.
                     if (ModalRoute.of(context)?.isCurrent ?? false) {
                       Navigator.of(context).pop();
                     }
                   },
                   child: Container(
                     color: barrierColor,
                   ),
                 ),
               // Sheet
               SlideTransition(
                 position:
                     Tween<Offset>(
                       begin: const Offset(0, 1),
                       end: Offset.zero,
                     ).animate(
                       CurvedAnimation(
                         parent: effectiveAnimation,
                         curve: Curves.easeOut,
                       ),
                     ),
                 child: Align(
                   alignment: Alignment.bottomCenter,
                   child: child,
                 ),
               ),
             ],
           );
         },
         settings: const RouteSettings(name: '/bottom_sheet'),
       );
}

/// The actual content widget displayed inside the bottom sheet route.
///
/// Manages the draggable scrollable sheet, drag handle visibility,
/// PopScope for back button handling, and focus management.
class _BottomSheetContent<T> extends StatefulWidget {
  /// The builder function that constructs the sheet's content.
  final WidgetBuilder builder;

  /// Whether the sheet is persistent (no barrier, page interactive) or modal.
  final bool isPersistent;

  /// Semantic label for screen readers (caller-supplied, optional).
  final String? semanticLabel;

  /// Snap point fractions in ascending order.
  final List<double> snapSizes;

  /// Initial height fraction.
  final double initialSize;

  /// Minimum height fraction.
  final double minSize;

  /// Maximum height fraction.
  final double maxSize;

  /// Whether to show the drag handle.
  final bool showDragHandle;

  /// Whether the sheet wraps [builder]'s content in its own [SingleChildScrollView].
  /// See [LayrzBottomSheet.show] for the full contract.
  final bool scrollable;

  /// Creates a bottom sheet content widget.
  const _BottomSheetContent({
    required this.builder,
    required this.isPersistent,
    required this.semanticLabel,
    required this.snapSizes,
    required this.initialSize,
    required this.minSize,
    required this.maxSize,
    required this.showDragHandle,
    required this.scrollable,
  });

  @override
  State<_BottomSheetContent<T>> createState() => _BottomSheetContentState<T>();
}

/// State for [_BottomSheetContent], managing focus, focus scope, and the
/// [DraggableScrollableController] that lets the drag handle resize the sheet.
class _BottomSheetContentState<T> extends State<_BottomSheetContent<T>> {
  late FocusNode _focusNode;

  /// Controls the sheet's extent programmatically, so the drag handle can resize
  /// and dismiss it the same way dragging the sheet's own content does.
  late DraggableScrollableController _sheetController;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _sheetController = DraggableScrollableController();
    // Request focus into the sheet on the next frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).autofocus(_focusNode);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _sheetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    // The lowest existing snap point; dragging the handle past it dismisses the sheet
    // rather than resizing further, matching the natural end of a continuous drag.
    final lowSnapSize = widget.snapSizes.isNotEmpty ? widget.snapSizes.first : widget.minSize;

    final focusChild = Focus(
      focusNode: _focusNode,
      onKeyEvent: (node, event) {
        // Dismiss on Escape (modal mode only)
        if (!widget.isPersistent && event.logicalKey == LogicalKeyboardKey.escape) {
          Navigator.of(context).pop();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: DraggableScrollableSheet(
        controller: _sheetController,
        snap: true,
        snapSizes: widget.snapSizes,
        initialChildSize: widget.initialSize,
        minChildSize: widget.minSize,
        maxChildSize: widget.maxSize,
        builder: (context, scrollController) {
          // The decoration is built here, inside the sheet's own builder, so that it
          // is sized by the sheet's FractionallySizedBox — i.e. to the sheet's own
          // extent — rather than by DraggableScrollableSheet's outer SizedBox.expand,
          // which spans the full viewport. Decorating the outer box (as this used to)
          // paints the surface across the whole screen and, because DecoratedBox
          // absorbs any tap within its own bounds, makes the barrier below it in the
          // transition Stack unreachable no matter how far outside the visible sheet
          // the tap lands.
          // Shared by the decoration and the clip below so the two can never drift apart —
          // only the top corners are rounded, matching the sheet's bottom-anchored shape.
          final topRadius = BorderRadius.only(
            topLeft: Radius.circular(tokens.radius.r4),
            topRight: Radius.circular(tokens.radius.r4),
          );

          return DecoratedBox(
            decoration: BoxDecoration(
              color: tokens.colors.sf1,
              borderRadius: topRadius,
              boxShadow: tokens.shadow.elevation3,
            ),
            // Clips the content to the same rounded top edge the decoration paints.
            // Without this, content taller than the sheet's visible extent keeps its
            // square corners and bleeds past the decoration's rounded shape at the top.
            child: ClipRRect(
              borderRadius: topRadius,
              child: Column(
                children: [
                  // Drag handle
                  if (widget.showDragHandle)
                    _DragHandle(
                      draggable: true,
                      controller: _sheetController,
                      snapSizes: widget.snapSizes,
                      lowSnapSize: lowSnapSize,
                    ),
                  // Content
                  Expanded(
                    child: widget.scrollable
                        ? SingleChildScrollView(
                            controller: scrollController,
                            child: widget.builder(context),
                          )
                        // scrollable: false hands the caller the scrollController via
                        // PrimaryScrollController instead of wrapping the content: a
                        // vertical ListView/GridView that sets no controller of its own
                        // binds to it automatically, giving it the sheet's drag/scroll
                        // handoff without being nested inside another same-axis scrollable.
                        // automaticallyInheritForPlatforms covers every platform, not just
                        // mobile (PrimaryScrollController's own default) — the sheet already
                        // knows which ScrollController it wants used, on every platform.
                        : PrimaryScrollController(
                            controller: scrollController,
                            automaticallyInheritForPlatforms: TargetPlatform.values.toSet(),
                            child: widget.builder(context),
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    // For modal sheets with a semantic label, wrap with Semantics to expose route semantics.
    // scopesRoute: announces to screen readers that this subtree is a route/modal context
    // namesRoute: uses the label to name that route for screen readers
    // explicitChildNodes: required by Flutter when scopesRoute is true; keeps child nodes
    //   from merging into the parent, so the label is announced independently
    // Persistent sheets never get route semantics (they are supplementary UI, not modal routes).
    // If no label is supplied, no dialog semantics are added (prevents focus trap without announcement).
    if (!widget.isPersistent && widget.semanticLabel != null) {
      return Semantics(
        label: widget.semanticLabel,
        scopesRoute: true,
        namesRoute: true,
        explicitChildNodes: true,
        enabled: true,
        child: focusChild,
      );
    }

    return focusChild;
  }
}

/// Visual drag handle widget.
///
/// Renders a centered pill-shaped indicator that signals the sheet is draggable.
/// When [draggable] is true, the entire header region — not just the visible
/// 40x4 pill — is the drag target: dragging it resizes the attached sheet across
/// [snapSizes], the same way dragging the sheet's own content does, and dragging
/// past [lowSnapSize] on release dismisses the sheet. The hit region is a fixed
/// size regardless of hover/press state (per D15, interaction states never change
/// geometry); only the pill's colour may vary with theme.
class _DragHandle extends StatelessWidget {
  /// Whether this handle responds to vertical drag gestures. When false (or when
  /// [controller] is null), the handle is purely visual.
  final bool draggable;

  /// Controls the sheet this handle drags. Required for [draggable] to have effect.
  final DraggableScrollableController? controller;

  /// The sheet's snap point fractions, in ascending order. On drag release, the
  /// sheet animates to whichever of these is nearest its current size. Ignored
  /// when [draggable] is false.
  final List<double> snapSizes;

  /// The lowest existing snap point fraction. Releasing the drag with the sheet's
  /// current size below this dismisses the sheet instead of snapping back to it —
  /// this is how dismissal "falls out of" dragging past the low end, rather than
  /// being a separate dismiss-only gesture. Ignored when [draggable] is false.
  final double lowSnapSize;

  /// Creates a drag handle.
  const _DragHandle({
    required this.draggable,
    this.controller,
    this.snapSizes = const [],
    this.lowSnapSize = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    final header = Container(
      padding: EdgeInsets.symmetric(vertical: tokens.spacing.sp3),
      alignment: Alignment.center,
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: tokens.colors.fg3,
          borderRadius: tokens.radius.br5,
        ),
      ),
    );

    final sheetController = controller;
    if (!draggable || sheetController == null) {
      return header;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragUpdate: (details) => _onDragUpdate(sheetController, details),
      onVerticalDragEnd: (details) => _onDragEnd(context, sheetController),
      child: header,
    );
  }

  /// Resizes the sheet by the drag delta. Dragging up (negative `dy`) grows the
  /// sheet; dragging down shrinks it. [DraggableScrollableController.jumpTo] clamps
  /// the result to the sheet's own `minSize`/`maxSize`, so no clamping is done here.
  void _onDragUpdate(DraggableScrollableController sheetController, DragUpdateDetails details) {
    if (!sheetController.isAttached) {
      return;
    }
    final newSize = sheetController.size - sheetController.pixelsToSize(details.delta.dy);
    sheetController.jumpTo(newSize);
  }

  /// On release, either dismisses the sheet (current size below [lowSnapSize]) or
  /// animates it to the nearest snap point. [DraggableScrollableController.jumpTo]
  /// does not snap on its own — snapping only happens after a drag through the
  /// sheet's own [DraggableScrollableSheet.snap], which this handle drives manually
  /// so it matches what dragging the content already does.
  void _onDragEnd(BuildContext context, DraggableScrollableController sheetController) {
    if (!sheetController.isAttached) {
      return;
    }

    final currentSize = sheetController.size;
    if (currentSize < lowSnapSize) {
      Navigator.of(context).pop();
      return;
    }

    var nearestSnapSize = snapSizes.isNotEmpty ? snapSizes.first : currentSize;
    var smallestDiff = (currentSize - nearestSnapSize).abs();
    for (final snapSize in snapSizes) {
      final diff = (currentSize - snapSize).abs();
      if (diff < smallestDiff) {
        smallestDiff = diff;
        nearestSnapSize = snapSize;
      }
    }

    final motion = context.tokens.motion;
    sheetController.animateTo(nearestSnapSize, duration: motion.dTransition, curve: motion.easing);
  }
}
