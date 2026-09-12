import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/platform/platform.dart';
import 'package:layrz_ui/src/selection/selection.dart';
import 'package:layrz_ui/src/tokens/tokens.dart';

/// The right detail pane of the scaffold shell.
///
/// Shows the content built by [builder] when it is non-null, or an empty state
/// otherwise. The detail content is wrapped in its own [SelectableRegion], scoped
/// independently of whatever ancestor selection scope (e.g. `LayrzLayout`'s
/// `selectableContent`) this pane happens to be composed under -- see [builder]
/// for why this matters.
///
/// [DetailPane] no longer resolves an opened item against `LayrzScaffoldShell`'s
/// item list itself -- it renders whatever [LayrzScaffoldController.openedBuilder]
/// currently is, verbatim. This is what lets a "create new item" detail pane exist
/// with no backing list item at all: the caller supplies [builder] directly via
/// `LayrzScaffoldController.open`, and this pane has no opinion on what it builds.
class DetailPane extends StatelessWidget {
  /// Builds the detail pane's content, or null to show the empty state.
  ///
  /// The built content is wrapped in its own [SelectableRegion] (double-tap
  /// selects a word, long-press selects a word and enables drag-to-extend --
  /// both are supported, unconditionally). This is deliberate: [DetailPane] is
  /// rendered both in `LayrzScaffoldShell`'s wide-layout side-by-side pane and
  /// inside its narrow-layout modal sheet, and the SAME content must be
  /// selectable the same way in both places rather than only in one. Giving it
  /// an independent [SelectableRegion] also means a gesture on this pane's text
  /// resolves against THIS content, never against whatever list content
  /// happens to sit in an ancestor selection scope -- see [DetailPane]'s own
  /// class doc.
  final WidgetBuilder? builder;

  /// Creates a new [DetailPane].
  ///
  /// - [builder]: Builds the detail pane's content, or null. Defaults to null, which
  ///   shows the empty state.
  const DetailPane({
    super.key,
    this.builder,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Container(
      color: tokens.colors.sf1,
      child: builder == null ? _buildEmptyState(tokens) : _buildSelectableContent(context, builder!),
    );
  }

  Widget _buildSelectableContent(BuildContext context, WidgetBuilder builder) {
    final content = builder(context);
    // In the wide and folded layouts this pane sits inside an `Expanded`,
    // which hands it a bounded box -- a shrink-wrapping [content] (e.g. a
    // `Column(mainAxisSize: MainAxisSize.min)`) has no reason on its own to
    // claim that whole box, so without an explicit top-left anchor it renders
    // centered in the pane instead of flush with the top, unlike every other
    // showroom-style view. In the narrow layout this same pane is instead the
    // `builder` of a `LayrzBottomSheet`, which -- unless the caller opts out
    // via `scrollable: false` -- wraps it in a `SingleChildScrollView` and so
    // hands it *unbounded* height instead; `SizedBox.expand` would assert
    // there. `Align` alone handles both: it fills the available space along
    // any axis that is bounded (pinning [content] to that axis's top/left),
    // and shrinks to [content]'s own size along any axis that is not --
    // exactly what a scroll view's child needs.
    return Align(
      alignment: Alignment.topLeft,
      child: SelectableRegion(
        selectionControls: _selectionControls,
        contextMenuBuilder: _buildContextMenu,
        child: content,
      ),
    );
  }

  /// The [TextSelectionControls] used by this pane's [SelectableRegion].
  ///
  /// DESIGN-147: touch selection handles and the selection action menu are
  /// Android/iOS only, on web or native (per [LayrzPlatform.isTouchOS]).
  /// [SelectableRegion.selectionControls] is required and non-nullable, so
  /// (unlike `LayrzEditableField`) the null-both-parameters mechanism does
  /// not apply here. [emptyTextSelectionControls] is used as the "off" value
  /// instead: it does not mix in `TextSelectionHandleControls`, so
  /// [SelectableRegion] takes its `is! TextSelectionHandleControls` branch
  /// internally and shows a toolbar via the deprecated `buildToolbar()` path
  /// rather than force-unwrapping [_buildContextMenu] -- which is still
  /// passed unconditionally below and would otherwise null-check-crash on
  /// right-click. [EmptyTextSelectionControls.buildToolbar] and `buildHandle`
  /// both return `SizedBox.shrink()`, so nothing is ever visibly painted.
  /// Both branches are stable, package-level singleton instances.
  TextSelectionControls get _selectionControls =>
      LayrzPlatform.isTouchOS ? LayrzTextSelectionControls.instance : emptyTextSelectionControls;

  /// Builds the copy toolbar for this pane's own [SelectableRegion].
  ///
  /// Mirrors `LayrzLayout`'s own `_buildContextMenu` -- a bare [SelectableRegion]
  /// with no `contextMenuBuilder` null-crashes on long-press in this repo, since
  /// there is no Material default to fall back on. On non-touch platforms this
  /// builder is never actually invoked -- see [_selectionControls] -- but it
  /// must remain unconditionally wired for the same reason.
  Widget _buildContextMenu(BuildContext context, SelectableRegionState state) {
    final tokens = context.tokens;
    final anchors = state.contextMenuAnchors;

    final toolbar = LayrzSelectionToolbar(
      actions: {LayrzSelectableAction.copy},
      anchorAbove: anchors.primaryAnchor,
      anchorBelow: anchors.secondaryAnchor,
      tokens: tokens,
      onActionPressed: (actionType) {
        if (actionType == 'copy') {
          // ignore: deprecated_member_use
          state.copySelection(SelectionChangedCause.toolbar);
        }
      },
    );

    return CustomSingleChildLayout(
      delegate: TextSelectionToolbarLayoutDelegate(
        anchorAbove: anchors.primaryAnchor,
        anchorBelow: anchors.secondaryAnchor ?? Offset.zero,
      ),
      child: toolbar,
    );
  }

  Widget _buildEmptyState(LayrzTokens tokens) {
    return Center(
      child: Text(
        "No item selected",
        style: TextStyle(fontSize: 13, color: tokens.colors.fg3),
      ),
    );
  }
}
