import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/sheets/src/drag_handle.dart';
import 'package:layrz_ui/src/sheets/src/modal_route.dart';

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
/// Extends [LayrzModalRoute] to share the barrier, reduce-motion, and
/// double-pop-guard machinery common to every modal surface in the design
/// system. Sheet-specific behaviour — snap sizes, the drag handle, the
/// slide-from-bottom transition, and the keyboard-inset workaround's own
/// widget wiring — stays here rather than in the shared base, because it is
/// meaningless for a non-sheet modal surface such as a dialog.
class _BottomSheetRoute<T> extends LayrzModalRoute<T> {
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
           final effectiveAnimation = LayrzModalRoute.resolveAnimation(context, animation);

           // D65's SHRINK pattern (layout.dart/drawer_scaffold.dart), applied
           // here directly rather than the offset/push-up approach an earlier
           // revision of this fix used. The maintainer's own decision,
           // verbatim: "on open keyboard, just use the remaining space
           // available, disabling the expansion controls because, with an
           // open keyboard, there is not much space available there" -- his
           // form is a tall scroller, so pushing the whole sheet up wholesale
           // (which only repositions it, without changing how much of it is
           // visible above the fold) was never the right shape for that
           // content. Padding the Stack's available height by
           // viewInsets.bottom reduces the box DraggableScrollableSheet sizes
           // itself against; Align(bottomCenter) then keeps the sheet's
           // bottom edge pinned to the BOTTOM OF THAT REDUCED BOX (i.e. right
           // above the keyboard) rather than the true screen edge -- so this
           // is the shrink itself, not a push, once the size that shrinks is
           // pinned at 1.0 of the reduced box (see keyboardVisible below).
           // MediaQuery.removeViewInsets zeroes the inset for the sheet's own
           // subtree so nested readers (a caller's own
           // MediaQuery.viewInsetsOf) do not double-count the same inset this
           // Padding already consumed.
           //
           // keyboardVisible is threaded down to _BottomSheetContentState via
           // _KeyboardVisibility (an InheritedWidget wrapped around `child`
           // below), NOT read again as MediaQuery.viewInsetsOf(context) inside
           // that State. _BottomSheetContent is built once by
           // _BottomSheetRoute's pageBuilder and then cached as ModalRoute's
           // own `_page` widget, handed to this transitionBuilder as `child`
           // rather than rebuilt by it -- and MediaQuery.removeViewInsets
           // below sits strictly ABOVE that State's own context in the
           // resulting element tree. Reading MediaQuery.viewInsetsOf directly
           // inside _BottomSheetContentState was tried first and confirmed,
           // empirically, to never update once the sheet is open (its
           // didChangeDependencies simply never re-fires when the keyboard
           // opens) -- unlike THIS context, which is exactly what the
           // Padding/removeViewInsets above already rely on and is confirmed
           // to update correctly.
           final viewInsets = MediaQuery.viewInsetsOf(context);
           final keyboardVisible = LayrzModalRoute.keyboardViewInsetsOf(context) > 0;

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
                     // ('!_debugLocked'). LayrzModalRoute.popIfCurrent is the shared
                     // guard against exactly that -- see its own doc comment.
                     LayrzModalRoute.popIfCurrent(context);
                   },
                   child: Container(
                     color: barrierColor,
                   ),
                 ),
               // Sheet
               Padding(
                 padding: EdgeInsets.only(bottom: viewInsets.bottom),
                 child: MediaQuery.removeViewInsets(
                   context: context,
                   removeBottom: true,
                   child: SlideTransition(
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
                       child: _KeyboardVisibility(
                         visible: keyboardVisible,
                         child: child,
                       ),
                     ),
                   ),
                 ),
               ),
             ],
           );
         },
         settings: const RouteSettings(name: '/bottom_sheet'),
       );
}

/// Carries whether the on-screen keyboard is currently covering part of the
/// screen down to [_BottomSheetContentState], from [_BottomSheetRoute]'s
/// `transitionBuilder`.
///
/// This exists because [_BottomSheetContent] cannot read
/// `MediaQuery.viewInsetsOf(context)` directly and see it update: it is built
/// once by [_BottomSheetRoute]'s `pageBuilder` and then cached as
/// `ModalRoute`'s own internal `_page` widget, handed to `transitionBuilder`
/// as its `child` parameter rather than rebuilt by it -- and
/// `MediaQuery.removeViewInsets` in `transitionBuilder` sits strictly ABOVE
/// that state's own context in the resulting element tree. An
/// [InheritedWidget] wrapped directly around `child`, computed from
/// `transitionBuilder`'s own context (confirmed to update correctly, since
/// that is exactly what the existing keyboard-avoidance `Padding` already
/// relies on), sidesteps that entirely: the dependency genuinely lives inside
/// the subtree that rebuilds when `viewInsets` changes.
///
/// See [LayrzModalRoute.keyboardViewInsetsOf] for the shared read this value
/// is derived from.
class _KeyboardVisibility extends InheritedWidget {
  /// Whether the keyboard is currently open (`viewInsets.bottom > 0`) as of
  /// the most recent [_BottomSheetRoute.transitionBuilder] rebuild.
  final bool visible;

  /// Creates a [_KeyboardVisibility] scope.
  const _KeyboardVisibility({
    required this.visible,
    required super.child,
  });

  /// Reads the nearest [_KeyboardVisibility.visible] value, establishing a
  /// rebuild dependency on it. Defaults to `false` if none is found (should
  /// not happen in practice -- [_BottomSheetContent] is always built inside
  /// one -- but avoids a hard crash if the widget tree is ever restructured).
  static bool of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_KeyboardVisibility>()?.visible ?? false;
  }

  @override
  bool updateShouldNotify(_KeyboardVisibility oldWidget) => visible != oldWidget.visible;
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

  /// Whether the keyboard was visible ([MediaQuery.viewInsetsOf] `.bottom > 0`)
  /// the last time [build] ran. Tracked purely to detect the hidden->visible
  /// EDGE, not the level -- the sheet is only ever driven to fill the
  /// remaining space at the MOMENT the keyboard opens (see [build]); once
  /// there, ordinary drag-to-dismiss can move it away again, and re-pinning it
  /// on every subsequent rebuild while the keyboard stays up would fight that.
  bool _wasKeyboardVisible = false;

  /// The sheet's own fractional size at the moment the keyboard opened, so
  /// closing the keyboard can restore it exactly rather than leaving the
  /// sheet clamped at `maxSize` (pinning sets the internal size to `1.0`,
  /// which -- once maxSize reverts to its normal value on keyboard close --
  /// would otherwise just clamp DOWN to maxSize instead of back to whatever
  /// the user had before, a visibly jarring jump for anything smaller than
  /// maxSize). `null` when the keyboard is not open / has not been pinned.
  double? _sizeBeforeKeyboard;

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

    // The maintainer's decision, verbatim: "on open keyboard, just use the
    // remaining space available, disabling the expansion controls because,
    // with an open keyboard, there is not much space available there." The
    // Padding in _BottomSheetRoute.transitionBuilder already reduces the box
    // this sheet sizes itself against by viewInsets.bottom -- what's missing
    // is PINNING the sheet to fill that reduced box (rather than staying at
    // whatever fraction it happened to be at when the keyboard opened) and
    // SUPPRESSING drag-to-expand/snap while it stays open. minChildSize ==
    // maxChildSize == 1.0 makes the DraggableScrollableSheet's own drag
    // handling a structural no-op for resizing (there is no range left to
    // drag within), which is a stronger and simpler guarantee than trying to
    // intercept the gesture. Drag-to-DISMISS is deliberately preserved
    // through a *different* path -- see DragHandle's dismissOnly mode below
    // -- since disabling expansion has nothing to do with taking away the
    // user's ability to swipe the sheet away while typing.
    //
    // This reads _KeyboardVisibility, NOT MediaQuery.viewInsetsOf(context)
    // directly. _BottomSheetContent is built once by _BottomSheetRoute's
    // pageBuilder and then CACHED as ModalRoute's own `_page` widget --
    // handed to transitionBuilder as its `child` parameter rather than
    // rebuilt by it. MediaQuery.removeViewInsets(removeBottom: true, ...) in
    // transitionBuilder also sits strictly ABOVE this State's own context in
    // the resulting element tree (confirmed empirically: this State's own
    // MediaQuery.viewInsetsOf(context) never changes, and didChangeDependencies
    // never re-fires, once the keyboard opens -- unlike an ordinary widget in
    // the same app, which rebuilds correctly). _KeyboardVisibility is an
    // InheritedWidget transitionBuilder wraps `child` with, computed from ITS
    // OWN context (confirmed to update correctly, since that context is what
    // the original keyboard-avoidance Padding/removeViewInsets already relies
    // on) -- so this dependency genuinely lives inside the subtree that
    // actually rebuilds when viewInsets changes.
    final keyboardVisible = _KeyboardVisibility.of(context);
    if (keyboardVisible && !_wasKeyboardVisible) {
      // Rising edge: remember the sheet's own size BEFORE pinning it, so
      // closing the keyboard can restore this exact value instead of merely
      // clamping down to maxSize (see _sizeBeforeKeyboard's own doc).
      // sheetController.isAttached guards against the sheet not yet having
      // laid out on the very first frame it opens simultaneously with the
      // keyboard (e.g. a caller that auto-focuses a field) -- in that case
      // there is no prior on-screen size to preserve, so pinning alone
      // (no restore value recorded) is correct.
      if (_sheetController.isAttached) {
        _sizeBeforeKeyboard = _sheetController.size;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_sheetController.isAttached) {
          _sheetController.jumpTo(1.0);
        }
      });
    } else if (!keyboardVisible && _wasKeyboardVisible) {
      // Falling edge: restore the sheet to whatever size it was showing
      // before the keyboard opened, now that effectiveMinSize/maxSize below
      // have reverted to widget.minSize/maxSize for this same build --
      // without this, the pinned internal size (1.0) would just clamp DOWN
      // to maxSize once unpinned, which for any initialSize/size smaller
      // than maxSize is a visibly jarring jump instead of a return to rest.
      final restoreSize = _sizeBeforeKeyboard;
      _sizeBeforeKeyboard = null;
      if (restoreSize != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_sheetController.isAttached) {
            _sheetController.jumpTo(restoreSize);
          }
        });
      }
    }
    _wasKeyboardVisible = keyboardVisible;

    final effectiveMinSize = keyboardVisible ? 1.0 : widget.minSize;
    final effectiveMaxSize = keyboardVisible ? 1.0 : widget.maxSize;
    final effectiveInitialSize = keyboardVisible ? 1.0 : widget.initialSize;
    final effectiveSnapSizes = keyboardVisible ? const [1.0] : widget.snapSizes;

    final focusChild = Focus(
      focusNode: _focusNode,
      onKeyEvent: (node, event) {
        // Dismiss on Escape (modal mode only). Guarded the same way as the
        // barrier's onTap (see the comment there) for consistency across every
        // pop site in this file — a fast repeated Escape was not reproducible as
        // an actual double-pop in testing (the second key event is not even
        // delivered to this handler once the first pop is in flight, unlike the
        // barrier tap, which is a spatial hit-test unaffected by focus state),
        // but the guard costs nothing and removes the asymmetry.
        if (!widget.isPersistent &&
            event.logicalKey == LogicalKeyboardKey.escape &&
            (ModalRoute.of(context)?.isCurrent ?? false)) {
          LayrzModalRoute.popIfCurrent(context);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: DraggableScrollableSheet(
        controller: _sheetController,
        snap: true,
        snapSizes: effectiveSnapSizes,
        initialChildSize: effectiveInitialSize,
        minChildSize: effectiveMinSize,
        maxChildSize: effectiveMaxSize,
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
              // The surface (the DecoratedBox above) deliberately stays OUTSIDE
              // this SafeArea and keeps extending edge-to-edge under the status
              // bar and the Android navigation bar -- that full-bleed background
              // is the point, matching the modern Android look the maintainer
              // asked for. Only the CONTENT is inset clear of those system bars.
              // This uses SafeArea rather than a bespoke Padding so it composes
              // with the keyboard for free: SafeArea's default `bottom: true`
              // reads MediaQuery.paddingOf, which the engine already reports as
              // zero for any edge the keyboard is currently covering -- unlike
              // viewPadding, which holds the device's permanent inset regardless
              // of the keyboard. So once the keyboard is up and covers the nav
              // bar, this bottom inset already collapses to zero on its own;
              // nothing here needs to know about the keyboard to avoid
              // double-insetting on top of it (see _BottomSheetRoute.transitionBuilder
              // for the other half of that composition). left/right are left
              // unhandled (false) since the sheet is always full-width and has no
              // side notches to avoid, matching the selective-edge precedent in
              // top_bar.dart (SafeArea(bottom: false)) and navigator_panel.dart
              // (SafeArea(right: false)).
              child: SafeArea(
                left: false,
                right: false,
                child: Column(
                  children: [
                    // Drag handle
                    if (widget.showDragHandle)
                      DragHandle(
                        draggable: true,
                        controller: _sheetController,
                        snapSizes: widget.snapSizes,
                        lowSnapSize: lowSnapSize,
                        // With the keyboard up, effectiveMinSize/maxSize above
                        // already make ordinary resizing a structural no-op --
                        // dismissOnly switches the handle to a SEPARATE
                        // dismiss-by-drag path that does not go through
                        // sheetController.jumpTo/the min/max-locked size at
                        // all (see DragHandle's _onDragUpdate), so a deliberate
                        // downward swipe still closes the sheet even though
                        // "expand/resize" is inert. The maintainer's brief
                        // asked only to disable EXPANSION; nothing about
                        // taking away dismissal while typing.
                        dismissOnly: keyboardVisible,
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
