import 'package:flutter/widgets.dart';

import 'package:layrz_ui/src/extensions/extensions.dart';

import 'workspace_panel_border_painter.dart';
import 'workspace_split_view.dart';
import 'workspace_tab.dart';

/// The connected content panel rendered below a [LayrzWorkspaceTabs] strip.
///
/// [LayrzWorkspacePanel] renders whichever tab is active — its
/// [LayrzWorkspaceTab.left] alone, or [LayrzWorkspaceTab.left] and
/// [LayrzWorkspaceTab.right] side-by-side behind a resizable divider when
/// [LayrzWorkspaceTab.right] is non-null — inside a bordered surface whose
/// outline physically connects to the active tab above it: see
/// [LayrzWorkspacePanelBorderPainter] for how the top border opens under
/// [activeTabLeft]–[activeTabRight] and curves into the tab's own shoulders.
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
  /// A `null` tab renders an empty, unbroken-border panel with no content.
  final LayrzWorkspaceTab? tab;

  /// The active tab's left edge, in this panel's own local x-coordinates,
  /// used to carve the top-border gap it visually connects through.
  ///
  /// `null` when [tab] is `null`, in which case the panel draws an unbroken
  /// border.
  final double? activeTabLeft;

  /// The active tab's right edge, in this panel's own local x-coordinates.
  ///
  /// `null` when [tab] is `null`.
  final double? activeTabRight;

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
    required this.activeTabLeft,
    required this.activeTabRight,
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

    return CustomPaint(
      painter: LayrzWorkspacePanelBorderPainter(
        fillColor: tokens.colors.sf1,
        outerRadius: tokens.radius.r3,
        shoulderRadius: tokens.radius.r1,
        activeTabLeft: activeTabLeft,
        activeTabRight: activeTabRight,
        borderColor: tokens.colors.divider,
        borderWidth: tokens.border.stroke1,
      ),
      child: Padding(
        // Keeps content clear of the painted border stroke on every side;
        // the top inset additionally clears the carved gap's curve.
        padding: EdgeInsets.all(tokens.border.stroke1),
        child: ClipRRect(
          borderRadius: tokens.radius.innerRadius(outerRadius: tokens.radius.r3, spacer: tokens.border.stroke1),
          child: content,
        ),
      ),
    );
  }
}
