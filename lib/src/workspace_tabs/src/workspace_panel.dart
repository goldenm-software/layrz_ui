import 'package:flutter/widgets.dart';

import 'package:layrz_ui/src/extensions/extensions.dart';

import 'workspace_split_view.dart';
import 'workspace_tab.dart';

/// The connected content panel rendered below a [LayrzWorkspaceTabs] strip.
///
/// [LayrzWorkspacePanel] renders whichever tab is active — its
/// [LayrzWorkspaceTab.left] alone, or [LayrzWorkspaceTab.left] and
/// [LayrzWorkspaceTab.right] side-by-side behind a resizable divider when
/// [LayrzWorkspaceTab.right] is non-null — clipped to the card's own rounded
/// shape.
///
/// This widget paints no fill and no border of its own: both come from the
/// single [LayrzWorkspaceSilhouettePainter] that [LayrzWorkspaceTabs] layers
/// beneath it, covering the active tab's bump and this panel's whole area as
/// one continuous `sf1` surface. This widget's only job is to clip its
/// content to that same rounded-card shape so content never bleeds past the
/// card's own corners.
///
/// This widget always expands to fill the height it is given — it is
/// designed to sit as the `Expanded` child of the `Column` `LayrzWorkspaceTabs`
/// itself builds, not to be given a fixed height. When [tab]'s [right] is
/// non-null, both panes and the divider likewise fill that height.
class LayrzWorkspacePanel extends StatelessWidget {
  /// The currently active tab, or `null` when [LayrzWorkspaceTabs.activeId]
  /// matches no tab (e.g. transiently while the caller updates its own
  /// state after a close).
  ///
  /// A `null` tab renders an empty panel with no content.
  final LayrzWorkspaceTab? tab;

  /// The current split ratio for [tab]'s split view (the fraction of width
  /// given to [LayrzWorkspaceTab.left]), used only when [tab] is non-null
  /// and [LayrzWorkspaceTab.right] is non-null.
  final double splitRatio;

  /// Called with the new split ratio whenever the user drags the divider in
  /// [tab]'s split view.
  final ValueChanged<double> onSplitRatioChanged;

  /// Creates a new [LayrzWorkspacePanel].
  ///
  /// [splitRatio] and [onSplitRatioChanged] are required even for a
  /// single-pane tab, since [tab] may change to a split tab across rebuilds
  /// without this widget being recreated.
  const LayrzWorkspacePanel({
    super.key,
    required this.tab,
    required this.splitRatio,
    required this.onSplitRatioChanged,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final tab = this.tab;

    final content = tab == null
        ? const SizedBox.expand()
        : SizedBox.expand(
            child: tab.right == null
                ? tab.left
                : LayrzWorkspaceSplitView(
                    left: tab.left,
                    right: tab.right!,
                    ratio: splitRatio,
                    onRatioChanged: onSplitRatioChanged,
                  ),
          );

    // The card's own outer radius matches the browser frame's inner edge
    // (frame radius minus the frame's `sp1` inset) -- see
    // `LayrzWorkspaceTabs.build`'s `panelRadius`. The content clip radius is
    // that same value stepped in once more by the painted border's stroke
    // width, so the clip hugs just inside the silhouette's own stroke.
    final cardRadius = tokens.radius.innerRadiusValue(outerRadius: tokens.radius.r3, spacer: tokens.spacing.sp1);
    final contentRadius = tokens.radius.innerRadiusValue(outerRadius: cardRadius, spacer: tokens.border.stroke1);

    return Padding(
      // Keeps content clear of the silhouette's own painted border stroke
      // on every side.
      padding: EdgeInsets.all(tokens.border.stroke1),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(contentRadius),
        child: content,
      ),
    );
  }
}
