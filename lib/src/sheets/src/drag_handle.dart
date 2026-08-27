import 'package:flutter/widgets.dart';

import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/sheets/src/modal_route.dart';

/// Visual drag handle widget for [LayrzBottomSheet].
///
/// Renders a centered pill-shaped indicator that signals the sheet is draggable.
/// When [draggable] is true, the entire header region — not just the visible
/// 40x4 pill — is the drag target: dragging it resizes the attached sheet across
/// [snapSizes], the same way dragging the sheet's own content does, and dragging
/// past [lowSnapSize] on release dismisses the sheet. The hit region is a fixed
/// size regardless of hover/press state (per D15, interaction states never change
/// geometry); only the pill's colour may vary with theme.
class DragHandle extends StatefulWidget {
  /// Whether this handle responds to vertical drag gestures. When false (or when
  /// [controller] is null), the handle is purely visual.
  final bool draggable;

  /// Controls the sheet this handle drags. Required for [draggable] to have effect.
  final DraggableScrollableController? controller;

  /// The sheet's snap point fractions, in ascending order. On drag release, the
  /// sheet animates to whichever of these is nearest its current size. Ignored
  /// when [draggable] is false or [dismissOnly] is true.
  final List<double> snapSizes;

  /// The lowest existing snap point fraction. Releasing the drag with the sheet's
  /// current size below this dismisses the sheet instead of snapping back to it —
  /// this is how dismissal "falls out of" dragging past the low end, rather than
  /// being a separate dismiss-only gesture. Ignored when [draggable] is false or
  /// [dismissOnly] is true.
  final double lowSnapSize;

  /// When true, the handle no longer resizes the sheet at all (expansion is
  /// suppressed -- there is nothing to resize INTO with the keyboard up,
  /// per the maintainer's decision), but a downward drag past a fixed pixel
  /// threshold still dismisses the sheet. This is a genuinely separate drag
  /// path from the ordinary resize-then-check-lowSnapSize one: with the
  /// keyboard open, [DraggableScrollableSheet]'s own min/max are pinned to
  /// `1.0` (see the sheet content's own state), so driving this through
  /// [DraggableScrollableController.jumpTo] the normal way would either be a
  /// no-op (nowhere to move the size to) or, worse, briefly violate the
  /// pinned bounds mid-drag. Tracking raw drag distance instead sidesteps the
  /// sheet's own size entirely -- dismissal here is a decision made from the
  /// gesture, not from the sheet's current fractional size.
  final bool dismissOnly;

  /// Creates a drag handle.
  const DragHandle({
    super.key,
    required this.draggable,
    this.controller,
    this.snapSizes = const [],
    this.lowSnapSize = 0.0,
    this.dismissOnly = false,
  });

  @override
  State<DragHandle> createState() => _DragHandleState();
}

class _DragHandleState extends State<DragHandle> {
  /// Accumulated downward drag distance in the current gesture, used only by
  /// [widget.dismissOnly] mode. Reset on every drag start/end.
  double _dismissDragDistance = 0.0;

  /// The pixel distance a downward drag must cover, in [widget.dismissOnly]
  /// mode, before releasing dismisses the sheet. Chosen to require a
  /// deliberate swipe (roughly a third of the drag handle's own visual travel
  /// on a typical phone), not an incidental jitter while trying to type.
  static const double _dismissOnlyThreshold = 80.0;

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

    final sheetController = widget.controller;
    if (!widget.draggable || sheetController == null) {
      return header;
    }

    if (widget.dismissOnly) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragStart: (_) => _dismissDragDistance = 0.0,
        onVerticalDragUpdate: (details) => _dismissDragDistance += details.delta.dy,
        onVerticalDragEnd: (_) => _onDismissOnlyDragEnd(context),
        child: header,
      );
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
  /// the result to the sheet's own `minSize`/`maxSize` internally (inside
  /// `updateSize`), but only AFTER its own `assert(size >= 0 && size <= 1)` — that
  /// assert fires on the raw, unclamped value, so a `newSize` outside `[0, 1]`
  /// crashes before the minSize/maxSize clamping this comment used to (wrongly)
  /// credit with covering this. `pixelsToSize` converts by dividing by the sheet's
  /// parent height; with the keyboard open, the bottom-sheet keyboard-avoidance
  /// Padding (see `_BottomSheetRoute`) reduces that parent height, so the same
  /// drag delta in pixels now converts to a larger fraction than it did against
  /// the full screen — a single fast drag can land `newSize` past 1.0 (or below
  /// 0.0) well before the finger physically leaves the sheet. Clamp here so this
  /// holds for any large-enough delta, keyboard-driven or not.
  ///
  /// Not reached in [widget.dismissOnly] mode -- see [_onDismissOnlyDragEnd].
  void _onDragUpdate(DraggableScrollableController sheetController, DragUpdateDetails details) {
    if (!sheetController.isAttached) {
      return;
    }
    final newSize = sheetController.size - sheetController.pixelsToSize(details.delta.dy);
    sheetController.jumpTo(newSize.clamp(0.0, 1.0));
  }

  /// Dismisses the sheet if the just-completed drag moved downward by at
  /// least [_dismissOnlyThreshold] pixels; otherwise leaves the sheet exactly
  /// where it is -- there is no snap-back animation to play, since the
  /// sheet's own size was never touched by this gesture in the first place.
  void _onDismissOnlyDragEnd(BuildContext context) {
    final distance = _dismissDragDistance;
    _dismissDragDistance = 0.0;
    if (distance < _dismissOnlyThreshold) {
      return;
    }
    // Guarded the same way as every other pop site in this file -- see
    // LayrzModalRoute.popIfCurrent for the full rationale.
    LayrzModalRoute.popIfCurrent(context);
  }

  /// On release, either dismisses the sheet (current size below [widget.lowSnapSize])
  /// or animates it to the nearest snap point. [DraggableScrollableController.jumpTo]
  /// does not snap on its own — snapping only happens after a drag through the
  /// sheet's own [DraggableScrollableSheet.snap], which this handle drives manually
  /// so it matches what dragging the content already does.
  ///
  /// Not reached in [widget.dismissOnly] mode -- see [_onDismissOnlyDragEnd].
  void _onDragEnd(BuildContext context, DraggableScrollableController sheetController) {
    if (!sheetController.isAttached) {
      return;
    }

    final currentSize = sheetController.size;
    if (currentSize < widget.lowSnapSize) {
      // Guarded the same way as the barrier's onTap and the Escape handler, for
      // consistency across every pop site in this file. In practice a second
      // drag-to-dismiss during the exit animation was not reproducible as a
      // double-pop in testing: `sheetController.isAttached` (checked above)
      // already returns early once the sheet detaches, before this line is
      // ever reached — but the guard costs nothing and removes the asymmetry.
      LayrzModalRoute.popIfCurrent(context);
      return;
    }

    var nearestSnapSize = widget.snapSizes.isNotEmpty ? widget.snapSizes.first : currentSize;
    var smallestDiff = (currentSize - nearestSnapSize).abs();
    for (final snapSize in widget.snapSizes) {
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
