import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/platform/platform.dart';
import 'package:layrz_ui/src/selection/selection.dart';
import 'package:layrz_ui/src/tokens/tokens.dart';

/// The right detail pane of the scaffold shell.
///
/// Shows the detail content built by [contentBuilder] when [opened] is non-null,
/// or an empty state otherwise. The detail content is wrapped in its own
/// [SelectableRegion], scoped independently of whatever ancestor selection scope
/// (e.g. `LayrzLayout`'s `selectableContent`) this pane happens to be composed
/// under -- see [contentBuilder] for why this matters.
class DetailPane<T> extends StatelessWidget {
  /// The currently opened item, or null.
  final T? opened;

  /// Callback to build the detail content.
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
  final Widget Function(T)? contentBuilder;

  /// Creates a new [DetailPane].
  ///
  /// - [opened]: The currently opened item, or null. Defaults to null.
  /// - [contentBuilder]: Callback to build the detail content, or null. Defaults to null.
  const DetailPane({
    super.key,
    this.opened,
    this.contentBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Container(
      color: tokens.colors.sf1,
      child: opened == null ? _buildEmptyState(tokens) : _buildSelectableContent(context, opened as T),
    );
  }

  Widget _buildSelectableContent(BuildContext context, T item) {
    final content = contentBuilder?.call(item);
    if (content == null) {
      return const SizedBox.shrink();
    }
    return SelectableRegion(
      selectionControls: _selectionControls,
      contextMenuBuilder: _buildContextMenu,
      child: content,
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
