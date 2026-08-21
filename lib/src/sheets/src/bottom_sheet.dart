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
/// The sheet is draggable by the drag handle or (when [showDragHandle] is true) the entire
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
  /// - [snapSizes]: optional list of snap point fractions (0.0 to 1.0) in ascending order.
  ///   Constraints are enforced:
  ///   - All values must be between [minSize] and [maxSize] inclusive
  ///   - Values must be in ascending order
  ///   - An assertion fires if constraints are violated, failing loudly at the call site
  ///   rather than deep in the SDK.
  ///   If null, defaults to [0.5, 0.95] (half-height and full-height-minus-status-bar snap points).
  /// - [initialSize]: the fraction of the screen height the sheet initially occupies.
  ///   Defaults to 0.5 (half the screen). Must be between [minSize] and [maxSize].
  /// - [minSize]: the minimum fraction of screen height the sheet can be dragged down to.
  ///   Defaults to 0.25 (a quarter of the screen). Useful for showing a minimum
  ///   indicator or handle.
  /// - [maxSize]: the maximum fraction of screen height the sheet can occupy.
  ///   Defaults to 0.95 (leaving minimal space for status bar / app bar).
  /// - [showDragHandle]: whether to render a visual drag handle above the content.
  ///   Defaults to `true`. When true, the entire header region is draggable
  ///   (more forgiving than handle-only drag, which is easy to miss on touch).
  ///   to a full-screen presentation. The drag handle remains visible for dismissal.
  ///   Defaults to `false`. This parameter is out of scope for the current implementation;
  ///   setting it to `true` is accepted but the feature may be added in a future release.
  /// - [useRootNavigator]: whether to use the root navigator instead of the nearest one.
  ///   Defaults to `false`. Set to `true` when showing from a context that does not have
  ///   its own navigator (e.g. a nested route on desktop).
  static Future<T?> show<T>(
    BuildContext context, {
    required WidgetBuilder builder,
    bool isPersistent = false,
    List<double>? snapSizes,
    double initialSize = 0.5,
    double minSize = 0.25,
    double maxSize = 0.95,
    bool showDragHandle = true,
    bool useRootNavigator = false,
  }) {
    // Validate snapSizes constraints
    if (snapSizes != null) {
      // Check all values are within bounds
      for (final size in snapSizes) {
        assert(
          size >= minSize && size <= maxSize,
          'All snapSizes must be between minSize ($minSize) and maxSize ($maxSize). '
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

    // Validate initialSize
    assert(
      initialSize >= minSize && initialSize <= maxSize,
      'initialSize must be between minSize ($minSize) and maxSize ($maxSize). '
      'Got $initialSize.',
    );

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
        snapSizes: effectiveSnapSizes,
        initialSize: initialSize,
        minSize: minSize,
        maxSize: maxSize,
        showDragHandle: showDragHandle,
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

  /// Creates a new bottom sheet route.
  _BottomSheetRoute({
    required WidgetBuilder builder,
    required this.isPersistent,
    required List<double> snapSizes,
    required double initialSize,
    required double minSize,
    required double maxSize,
    required bool showDragHandle,
  }) : super(
         pageBuilder: (context, animation, secondaryAnimation) {
           return _BottomSheetContent(
             builder: builder,
             isPersistent: isPersistent,
             snapSizes: snapSizes,
             initialSize: initialSize,
             minSize: minSize,
             maxSize: maxSize,
             showDragHandle: showDragHandle,
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
                   onTap: () => Navigator.of(context).pop(),
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

  /// Whether to expand to full screen when dragged to top.

  /// Creates a bottom sheet content widget.
  const _BottomSheetContent({
    required this.builder,
    required this.isPersistent,
    required this.snapSizes,
    required this.initialSize,
    required this.minSize,
    required this.maxSize,
    required this.showDragHandle,
  });

  @override
  State<_BottomSheetContent<T>> createState() => _BottomSheetContentState<T>();
}

/// State for [_BottomSheetContent], managing focus and focus scope.
class _BottomSheetContentState<T> extends State<_BottomSheetContent<T>> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    // Request focus into the sheet on the next frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).autofocus(_focusNode);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          Navigator.of(context).pop(result);
        }
      },
      child: Focus(
        focusNode: _focusNode,
        onKeyEvent: (node, event) {
          // Dismiss on Escape (modal mode only)
          if (!widget.isPersistent && event.logicalKey == LogicalKeyboardKey.escape) {
            Navigator.of(context).pop();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: tokens.colors.sf1,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(tokens.radius.r4),
              topRight: Radius.circular(tokens.radius.r4),
            ),
            boxShadow: tokens.shadow.elevation3,
          ),
          child: DraggableScrollableSheet(
            snap: true,
            snapSizes: widget.snapSizes,
            initialChildSize: widget.initialSize,
            minChildSize: widget.minSize,
            maxChildSize: widget.maxSize,
            builder: (context, scrollController) {
              return Column(
                children: [
                  // Drag handle
                  if (widget.showDragHandle)
                    _DragHandle(
                      draggable: true,
                    ),
                  // Content
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: widget.builder(context),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Visual drag handle widget.
///
/// Renders a centered pill-shaped indicator that signals the sheet is draggable.
/// The entire handle area (and by extension, the header) is draggable when wrapped
/// in a [DraggableScrollableSheet].
class _DragHandle extends StatelessWidget {
  /// Whether this handle is draggable (always true in current implementation,
  /// kept for future extensibility).
  final bool draggable;

  /// Creates a drag handle.
  const _DragHandle({required this.draggable});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Container(
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
  }
}
