import "package:flutter/widgets.dart";
import "package:layrz_ui/src/extensions/extensions.dart";
import "package:layrz_ui/src/scaffold/src/scaffold_item.dart";
import "package:layrz_ui/src/sheets/sheets.dart";
import "package:layrz_ui/src/tokens/tokens.dart";

import "detail_pane.dart";
import "fold_split.dart";
import "list_panel.dart";
import "scaffold_controller.dart";

/// An adaptive list-detail shell widget in the layrz_ui design system.
///
/// [LayrzScaffoldShell] provides a responsive container for list-detail navigation.
/// On wide containers (md, lg, xl breakpoints), the list panel (300px) and detail pane
/// are displayed side-by-side. On narrow containers (xs, sm breakpoints), the list panel
/// is always shown; opening an item presents the detail content in a modal [LayrzBottomSheet]
/// layered over the list. Dismissing the sheet closes the controller. A resize from narrow
/// to wide pops the sheet but preserves the selection, and a resize to narrow auto-opens
/// the sheet for any already-selected item.
///
/// **Narrow layout constraint:** The shell requires a [Navigator] ancestor (e.g. [LayrzApp])
/// to show the detail sheet on narrow breakpoints. If no Navigator is present, the list
/// still renders without the detail, and a debug assertion fires on the sheet attempt.
///
/// The shell is container-driven via [LayoutBuilder] constraints, not viewport-driven.
/// The consuming app passes items and owns the controller; the shell owns the layout
/// and search filtering.
///
/// **Foldable-hinge awareness.** Independently of the breakpoint band, the shell inspects
/// `MediaQuery.displayFeaturesOf(context)` for a physical fold or hinge that genuinely
/// crosses its own box (see [resolveFoldSplit]). When a **vertical** seam is found
/// (splitting the box left/right, e.g. a Z Fold in portrait, or a Z Flip rotated to
/// landscape), it overrides the band and always forces a side-by-side split, at the seam's
/// own mapped position — even at an `xs`/`sm` width that would otherwise render the narrow
/// list + sheet path. The two panes are deliberately **asymmetric**, matching whatever the
/// physical seam actually measures; they are never equalised. There is no keyboard-aware
/// behavior in this split: it has no presentation to change, so its height simply follows
/// `MediaQuery.viewInsetsOf` the same way any other inline layout would.
///
/// A **horizontal** seam (e.g. a Z Flip in portrait, or a Z Fold rotated to landscape)
/// never produces a split at all — [resolveFoldSplit] always returns `null` for it, a
/// decision made after a stacked top/bottom layout for that case was built and tested on
/// real hardware and found to fight the on-screen keyboard (see [resolveFoldSplit]'s own
/// doc comment for the specifics). A device reporting only a horizontal seam, or no usable
/// display feature at all (the vast majority of them), sees no change in behavior — the
/// shell falls through to exactly the band-driven path below.
class LayrzScaffoldShell<T> extends StatefulWidget {
  /// The items to display in the list.
  final List<LayrzScaffoldItem<T>> items;

  /// Callback to build the detail content for an opened item.
  final Widget Function(T) onDetailsBuild;

  /// Controller for managing the opened item.
  final LayrzScaffoldController controller;

  /// Optional footer widget for the list panel.
  final Widget? footer;

  /// Whether the search field is visible.
  final bool searchable;

  /// Optional title widget rendered above the search field in the list panel.
  final Widget? title;

  /// The item extent for the list panel.
  final double itemExtent;

  /// Optional widget to display when the list is empty.
  ///
  /// If null, a localized default message is displayed.
  final Widget? emptyState;

  /// Creates a new [LayrzScaffoldShell].
  ///
  /// - [items]: The items to display in the list. Required.
  /// - [onDetailsBuild]: Callback to build the detail content for an opened item. Required.
  /// - [controller]: Controller for managing the opened item. Required.
  /// - [footer]: Optional footer widget for the list panel. Defaults to null.
  /// - [searchable]: Whether the search field is visible. Defaults to true.
  /// - [title]: Optional title widget rendered above the search field. Defaults to null.
  /// - [itemExtent]: The height of each list item. Required.
  /// - [emptyState]: Optional widget to display when the list is empty. Defaults to null.
  const LayrzScaffoldShell({
    super.key,
    required this.items,
    required this.onDetailsBuild,
    required this.controller,
    this.footer,
    this.searchable = true,
    this.title,
    required this.itemExtent,
    this.emptyState,
  });

  @override
  State<LayrzScaffoldShell<T>> createState() => _LayrzScaffoldShellState<T>();
}

class _LayrzScaffoldShellState<T> extends State<LayrzScaffoldShell<T>> {
  late VoidCallback _controllerListener;
  late ValueNotifier<int> _itemsChangeNotifier;

  /// Whether a detail sheet is currently open on narrow layouts.
  bool _sheetOpen = false;

  /// Whether the shell initiated the last sheet pop (band transition).
  /// If true, don't close the controller when the sheet closes.
  bool _dismissedByShell = false;

  /// Reference to the builder context from the narrow sheet, used to pop it specifically.
  BuildContext? _narrowSheetContext;

  /// Key on the outermost box this widget returns, used ONLY as the anchor
  /// [_scheduleShellRectRefresh] reads from -- never touched during [build]
  /// or layout.
  ///
  /// **Why this cannot be resolved during [build]/layout at all**, not even
  /// via a key one layer out from the naive `LayoutBuilder` context: an
  /// earlier version of this code read `_shellBoundaryKey`'s box directly
  /// inside `build` (reasoning it held the *previous* frame's already-laid-out
  /// geometry) and called `RenderBox.localToGlobal` on it there. That still
  /// crashed on a real device, because `localToGlobal` doesn't just read the
  /// keyed box's own offset -- it walks every ANCESTOR via
  /// `RenderObject.getTransformTo`, and `RenderTransform.applyPaintTransform`
  /// asserts `hasSize` on each one it walks through. Under `LayrzLayout`'s
  /// drawer presentation, that ancestor chain includes the animated drawer's
  /// own `RenderTransform` -- and *that* ancestor can still be
  /// `NEEDS-LAYOUT` while this shell's `LayoutBuilder` is being built as part
  /// of the very same frame's layout pass (composition puts the shell inside
  /// an `Overlay`'s `_RenderTheater`, several proxy boxes, and the drawer's
  /// `RenderTransform`, in that order). A previous-frame box being fully laid
  /// out does not make ITS ancestors fully laid out on THIS frame -- they are
  /// laid out top-down, and a `LayoutBuilder` deep in the tree can run before
  /// an animating ancestor higher up has reached its own `performLayout` this
  /// frame. There is no depth in the tree from which `localToGlobal` is safe
  /// to call synchronously during any part of the layout phase.
  ///
  /// The fix: never call `localToGlobal` from `build` at all.
  /// [_scheduleShellRectRefresh] reads it from a post-frame callback instead,
  /// where the ENTIRE frame's layout (every ancestor, animating or not) is
  /// guaranteed complete -- see [_scheduleShellRectRefresh]'s own doc comment.
  final GlobalKey _shellBoundaryKey = GlobalKey();

  /// The shell's own global rect, as last computed by
  /// [_scheduleShellRectRefresh]. `null` until the first post-frame callback
  /// has run at least once.
  ///
  /// [_resolveFoldSplit] reads this value ONLY -- it never touches
  /// [_shellBoundaryKey] or calls `localToGlobal` itself. Because this is
  /// necessarily last-frame's geometry (see [_scheduleShellRectRefresh]), a
  /// fold appearing or the shell moving resolves with a one-frame lag, the
  /// same trade-off the previous (crashing) approach already accepted.
  Rect? _lastShellRect;

  /// Whether a [_scheduleShellRectRefresh] post-frame callback is already
  /// pending for the current frame.
  ///
  /// Without this guard, calling [_scheduleShellRectRefresh] from every
  /// [build] (as [build] does, unconditionally, since it cannot know in
  /// advance whether the rect actually moved) would queue a new
  /// post-frame callback on every single rebuild -- harmless in the sense
  /// that duplicate callbacks would each just recompute the same value, but
  /// wasteful and, more importantly, exactly the shape of bug that has bitten
  /// this file before (see the `didUpdateWidget` items-change-notifier
  /// comment above). One callback per frame is enough: it always reads the
  /// LATEST geometry once the frame's layout is done, regardless of how many
  /// times [build] ran to get there.
  bool _shellRectRefreshScheduled = false;

  /// Schedules a post-frame callback that reads [_shellBoundaryKey]'s
  /// current global rect and, if it changed, stores it in [_lastShellRect]
  /// and triggers exactly one rebuild to consume the fresh value.
  ///
  /// This is the ONLY place [RenderBox.localToGlobal] is called anywhere in
  /// this class, and it is called from
  /// [WidgetsBinding.addPostFrameCallback], never from [build] -- see
  /// [_shellBoundaryKey]'s own doc comment for why calling it during layout
  /// crashes on a real device. By the time a post-frame callback runs, the
  /// ENTIRE frame's layout phase has finished for the whole tree, not just
  /// this widget's own subtree -- every ancestor, including an animating
  /// `RenderTransform` like `LayrzLayout`'s drawer, is guaranteed to already
  /// have `hasSize == true`. That is what makes `localToGlobal` safe here
  /// and nowhere else.
  ///
  /// The `setState` only fires when the newly-read rect actually differs
  /// from [_lastShellRect] (or the first successful read). A
  /// steady-state frame where nothing moved recomputes the same rect and
  /// schedules no further work, so this cannot degrade into an unconditional
  /// per-frame rebuild loop -- the same discipline
  /// `_scheduledFoldResolveFrame` (the earlier, now-removed one-shot guard)
  /// existed to preserve.
  void _scheduleShellRectRefresh() {
    if (_shellRectRefreshScheduled) return;
    _shellRectRefreshScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _shellRectRefreshScheduled = false;
      if (!mounted) return;

      final renderObject = _shellBoundaryKey.currentContext?.findRenderObject();
      if (renderObject is! RenderBox || !renderObject.attached || !renderObject.hasSize) {
        // Still not laid out even after a full frame (e.g. the very first
        // frame ever, before this widget has been through layout at all).
        // Try again next frame rather than giving up -- but only once more
        // is queued at a time, per the guard above.
        _scheduleShellRectRefresh();
        return;
      }

      final rect = renderObject.localToGlobal(Offset.zero) & renderObject.size;
      if (rect != _lastShellRect) {
        setState(() {
          _lastShellRect = rect;
        });
      }
    });
  }

  double get _itemExtent => widget.itemExtent + context.tokens.spacing.pd2.vertical;

  @override
  void initState() {
    super.initState();
    _controllerListener = () {
      setState(() {});
    };
    _itemsChangeNotifier = ValueNotifier(widget.items.length);
    widget.controller.addListener(_controllerListener);
  }

  @override
  void didUpdateWidget(LayrzScaffoldShell<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_controllerListener);
      widget.controller.addListener(_controllerListener);
    }
    // Notify when items list instance changes (handles refetches with same keys but new instances),
    // but only while the narrow sheet's ListenableBuilder is actually listening to this notifier —
    // otherwise the bump is both unobserved and unsafe.
    //
    // The bump is deferred to a post-frame callback rather than applied synchronously here: this
    // notifier is merged into the Listenable driving the sheet's ListenableBuilder, so an immediate
    // `.value++` fires `notifyListeners()` -> `setState()` on that (possibly still-mounted, e.g.
    // mid exit-animation) builder while the framework may already be building this shell's own
    // subtree (e.g. from a LayoutBuilder-driven breakpoint change). That is an illegal
    // setState-during-build. Deferring costs at most one extra frame, and only when the sheet is
    // actually open to observe it.
    if (_sheetOpen && !identical(oldWidget.items, widget.items)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _sheetOpen) {
          _itemsChangeNotifier.value++;
        }
      });
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_controllerListener);
    _itemsChangeNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Always (re)schedule a post-frame rect refresh -- see
    // _scheduleShellRectRefresh's own doc comment for why this is cheap
    // (guarded to at most one pending callback) and why it is the only
    // place this class ever calls localToGlobal.
    _scheduleShellRectRefresh();

    return KeyedSubtree(
      key: _shellBoundaryKey,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tokens = context.tokens;
          final breakpoint = tokens.breakpoints.bandAt(constraints.maxWidth);
          final isWide = breakpoint.index >= LayrzBreakpoint.md.index;

          final foldSplit = _resolveFoldSplit(context);

          // Only a vertical seam ever produces a foldSplit at all (see
          // resolveFoldSplit's own doc comment for why a horizontal seam is
          // rejected before it ever reaches here) -- so there is no axis
          // check to make here, and deliberately no keyboard term: a
          // horizontal seam never splits, and a vertical split has no
          // presentation change tied to the keyboard to guard against.
          final useFoldedSideBySide = foldSplit != null;

          // Any presentation change the shell itself must reverse (band crossing to
          // wide, or a fold appearing/disappearing that switches the shell into or
          // out of a layout that never shows the sheet) pops a currently-open sheet
          // without closing the controller, so the selection survives the switch.
          final sheetMustClose = _sheetOpen && (isWide || useFoldedSideBySide);
          if (sheetMustClose) {
            // Schedule the pop for after the build, to avoid modifying the widget tree during build.
            // Mark it as shell-initiated so the sheet dismissal callback doesn't close the controller.
            _dismissedByShell = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_narrowSheetContext != null && _narrowSheetContext!.mounted) {
                Navigator.of(_narrowSheetContext!).pop();
                _narrowSheetContext = null;
              }
            });
          }

          if (useFoldedSideBySide) {
            return _buildFoldedSideBySideLayout(context, tokens, foldSplit);
          }
          if (isWide) {
            return _buildWideLayout(context, tokens);
          } else {
            return _buildNarrowLayout(context, tokens);
          }
        },
      ),
    );
  }

  /// Resolves the shell's own physical-seam split, or `null` when there is
  /// none to act on.
  ///
  /// Reads [_lastShellRect] ONLY -- this method never touches
  /// [_shellBoundaryKey], never calls [RenderBox.localToGlobal], and is safe
  /// to call unconditionally from [build] on every frame, including mid
  /// layout. See [_shellBoundaryKey]'s own doc comment for why calling
  /// `localToGlobal` from here used to crash on a real device (an ancestor
  /// `RenderTransform`, e.g. `LayrzLayout`'s drawer, mid-layout) and
  /// [_scheduleShellRectRefresh] for where that offset is actually computed
  /// instead.
  ///
  /// If [_lastShellRect] is still `null` -- this widget's very first frame,
  /// before any post-frame callback has run yet -- this returns `null` and
  /// behaves exactly like a non-foldable device for that one frame; the
  /// [_scheduleShellRectRefresh] call already unconditionally made from
  /// [build] resolves it as soon as the first frame's layout completes.
  LayrzFoldSplit? _resolveFoldSplit(BuildContext context) {
    final shellRect = _lastShellRect;
    if (shellRect == null) {
      return null;
    }

    final features = MediaQuery.displayFeaturesOf(context);
    if (features.isEmpty) {
      return null;
    }

    return resolveFoldSplit(features: features, shellRect: shellRect);
  }

  /// Find the item with the opened key, or null if not found in the full list.
  ///
  /// This looks up the opened key in the unfiltered items list, so the detail pane
  /// can stay open even when its item is filtered out of the search results.
  LayrzScaffoldItem<T>? _findOpenedItem() {
    final openedKey = widget.controller.openedKey;
    if (openedKey == null) return null;
    try {
      return widget.items.firstWhere((item) => item.key == openedKey);
    } catch (e) {
      return null;
    }
  }

  Widget _buildWideLayout(BuildContext context, LayrzTokens tokens) {
    final openedItem = _findOpenedItem();

    return Row(
      children: [
        ListPanel<T>(
          items: widget.items,
          openedKey: widget.controller.openedKey,
          onTap: (item) {
            widget.controller.open(item.key);
          },
          searchable: widget.searchable,
          footer: widget.footer,
          title: widget.title,
          itemExtent: _itemExtent,
          emptyState: widget.emptyState,
        ),
        Container(
          width: 1,
          color: tokens.colors.divider,
        ),
        Expanded(
          child: DetailPane<T>(
            opened: openedItem?.item,
            contentBuilder: openedItem != null ? widget.onDetailsBuild : null,
          ),
        ),
      ],
    );
  }

  /// Builds the side-by-side split forced by a vertical physical seam.
  ///
  /// Structurally identical to [_buildWideLayout] -- same [ListPanel]/[DetailPane]
  /// wiring, same `onTap` -> [LayrzScaffoldController.open] -- except the list
  /// panel takes [split]'s mapped [LayrzFoldSplit.leadingExtent] instead of its
  /// usual fixed width, and the divider is a hairline when the seam is
  /// creaseless ([LayrzFoldSplit.gap] `== 0`) or a spacer sized to the seam's
  /// actual occlusion otherwise. The two panes are deliberately asymmetric,
  /// matching the physical seam -- they are never equalised to 50/50.
  Widget _buildFoldedSideBySideLayout(BuildContext context, LayrzTokens tokens, LayrzFoldSplit split) {
    final openedItem = _findOpenedItem();

    return Row(
      children: [
        ListPanel<T>(
          items: widget.items,
          openedKey: widget.controller.openedKey,
          onTap: (item) {
            widget.controller.open(item.key);
          },
          searchable: widget.searchable,
          footer: widget.footer,
          title: widget.title,
          itemExtent: _itemExtent,
          emptyState: widget.emptyState,
          width: split.leadingExtent,
        ),
        split.gap == 0 ? Container(width: 1, color: tokens.colors.divider) : SizedBox(width: split.gap),
        Expanded(
          child: DetailPane<T>(
            opened: openedItem?.item,
            contentBuilder: openedItem != null ? widget.onDetailsBuild : null,
          ),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout(BuildContext context, LayrzTokens tokens) {
    // Always show the list panel on narrow layouts
    final panel = ListPanel<T>(
      items: widget.items,
      openedKey: widget.controller.openedKey,
      onTap: (item) {
        widget.controller.open(item.key);
      },
      searchable: widget.searchable,
      footer: widget.footer,
      title: widget.title,
      itemExtent: _itemExtent,
      emptyState: widget.emptyState,
    );

    // Schedule the sheet presentation in a post-frame callback to avoid building during build.
    // Only schedule if controller is open and no sheet is already open.
    if (widget.controller.isOpen && !_sheetOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showNarrowDetailSheet(context);
        }
      });
    }

    return panel;
  }

  /// Shows the detail sheet for narrow layouts.
  ///
  /// Opens a LayrzBottomSheet with the detail content. Handles the case where
  /// the opened item is no longer in the list, and manages dismissal to close
  /// the controller (unless the shell initiated the pop via band transition).
  Future<void> _showNarrowDetailSheet(BuildContext context) async {
    // Guard: if sheet is already open, do not open again (prevents stacking)
    if (_sheetOpen) return;

    // Reset the shell-dismissal flag so a stale value doesn't leak across presentations
    _dismissedByShell = false;

    // Mark the sheet as open before checking anything else
    _sheetOpen = true;

    // Guard: check if the ROOT Navigator is reachable -- LayrzBottomSheet.show
    // always pushes there intrinsically, so this must validate the same
    // Navigator it pushes to. Checking the nearest one instead would pass
    // here and still throw at the push if only a nested Navigator exists
    // with no root above it (impossible under LayrzApp in practice, but the
    // guard should not claim success for a Navigator it isn't actually
    // going to use).
    final navigator = Navigator.maybeOf(context, rootNavigator: true);
    if (navigator == null) {
      assert(
        false,
        'LayrzScaffoldShell on narrow breakpoints requires a Navigator ancestor '
        '(e.g., inside LayrzApp) to present the detail sheet. No Navigator found in context.',
      );
      _sheetOpen = false;
      return;
    }

    // If the opened item doesn't exist, close the controller
    if (_findOpenedItem() == null) {
      _sheetOpen = false;
      if (mounted) {
        widget.controller.close();
      }
      return;
    }

    // Show the sheet
    //
    // LayrzBottomSheet.show always pushes on the root Navigator intrinsically,
    // which is exactly what this shell needs: it is meant to be composed under
    // an app shell that owns its own nested Navigator (e.g. go_router's
    // ShellRoute -- "All ShellRoutes build a Navigator by default. Child
    // GoRoutes are placed onto this Navigator instead of the root Navigator.")
    // sitting inside a LayrzLayout ancestor. Pushing to the nearest Navigator
    // would resolve to that nested one, whose Overlay is a descendant of
    // LayrzLayout's own SelectableRegion -- so the sheet's content would be a
    // genuine widget-tree descendant of the page's selection scope, and a
    // double-tap physically on the sheet's own text could resolve against a
    // page-body row behind it instead. That nested Overlay would also be
    // bounded by LayrzLayout's body, not the full physical screen, so the
    // sheet's own barrier could not cover LayrzLayout's own chrome (e.g. the
    // narrow-mode top bar) either -- a tap on that chrome while the sheet is
    // open would reach the chrome's own controls instead of being blocked by
    // the modal scrim. Pushing to the root Navigator escapes both: the sheet's
    // Overlay entry sits above LayrzLayout entirely, genuinely outside its
    // SelectableRegion and genuinely covering the full screen. A modal sheet
    // belongs above the app's chrome, not nested inside the page's own
    // subtree, independent of either symptom.
    await LayrzBottomSheet.show<void>(
      context,
      builder: (sheetContext) {
        _narrowSheetContext = sheetContext;
        return ListenableBuilder(
          listenable: Listenable.merge([widget.controller, _itemsChangeNotifier]),
          builder: (context, _) {
            final openedItem = _findOpenedItem();
            if (openedItem == null) {
              // Item was removed from the list while the sheet is genuinely still
              // open; pop the sheet in the next frame. Guarding on `_sheetOpen` (not
              // just context-mounted) matters: this `ListenableBuilder` stays mounted
              // for the sheet route's own exit animation, so a user-initiated dismiss
              // (barrier tap / drag) reaches here too — via `widget.controller.close()`
              // notifying this same listenable while the route animates out. At that
              // point `_sheetOpen` is already false (set right after the dismiss's
              // `await LayrzBottomSheet.show` resolves, before this rebuild runs), so
              // it is a clean discriminator between "still open, must pop" and
              // "already closing, must not pop again" — unlike context.mounted, which
              // stays true throughout the exit animation either way.
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && _sheetOpen && _narrowSheetContext != null && _narrowSheetContext!.mounted) {
                  Navigator.of(_narrowSheetContext!).pop();
                }
              });
              return const SizedBox.shrink();
            }
            return DetailPane(
              opened: openedItem.item,
              contentBuilder: widget.onDetailsBuild,
            );
          },
        );
      },
    );

    // Mark the sheet as closed
    _sheetOpen = false;

    // When the sheet is dismissed (user dragged down, tapped barrier, etc.),
    // close the controller to match the screen state — unless the shell initiated
    // the pop (band transition). In that case, the selection should be preserved.
    if (_dismissedByShell) {
      _dismissedByShell = false;
    } else {
      if (mounted) {
        widget.controller.close();
      }
    }
  }
}
