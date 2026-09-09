import 'package:flutter/widgets.dart';

import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/tappable/tappable.dart';

/// Which partition of items [LayrzMultiSelectInputSurface] is currently
/// showing in its list.
enum LayrzMultiSelectTab {
  /// Every (search-filtered) item, regardless of draft membership.
  all,

  /// Only the items currently present in the surface's draft.
  selected,
}

/// The "All (count)" / "Selected (count)" tab strip rendered between
/// `LayrzMultiSelectInputSurface`'s header divider and its scrolling list.
///
/// **Deliberately not `LayrzTabView`** — that widget owns and swaps its own
/// content `Column`, which fights the surface's pinned-header +
/// single-`Expanded`-list layout (see `LayrzMultiSelectInputSurface.build`'s
/// own doc). This is a light strip of two tappable, token-styled, D15-
/// compliant segments that only ever changes which partition feeds the one
/// existing `ListView` — it renders no content of its own.
///
/// Both segments are always visible and always tappable (switching to the
/// same tab that's already active is a no-op re-selection, not blocked).
class LayrzMultiSelectTabStrip extends StatelessWidget {
  /// The tab currently selected.
  final LayrzMultiSelectTab activeTab;

  /// The total (or search-filtered) item count shown on the "All" segment.
  final int allCount;

  /// The count of items currently in the draft, shown on the "Selected"
  /// segment.
  final int selectedCount;

  /// Called with the tapped tab when the user selects a segment other than
  /// [activeTab]. Not called when the already-active segment is tapped
  /// again.
  final ValueChanged<LayrzMultiSelectTab> onTabChanged;

  /// Creates a new [LayrzMultiSelectTabStrip].
  const LayrzMultiSelectTabStrip({
    super.key,
    required this.activeTab,
    required this.allCount,
    required this.selectedCount,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = context.l10n;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: tokens.spacing.sp2, vertical: tokens.spacing.sp1),
      child: Row(
        children: [
          Expanded(
            child: _MultiSelectTabSegment(
              label: l10n.multiSelectTabAll(allCount),
              isSelected: activeTab == LayrzMultiSelectTab.all,
              onTap: () => onTabChanged(LayrzMultiSelectTab.all),
            ),
          ),
          SizedBox(width: tokens.spacing.sp1),
          Expanded(
            child: _MultiSelectTabSegment(
              label: l10n.multiSelectTabSelected(selectedCount),
              isSelected: activeTab == LayrzMultiSelectTab.selected,
              onTap: () => onTabChanged(LayrzMultiSelectTab.selected),
            ),
          ),
        ],
      ),
    );
  }
}

/// A single tappable segment in [LayrzMultiSelectTabStrip].
///
/// Interaction states vary only colour per D15 — the segment's geometry
/// (padding, border) is identical whether selected or not.
class _MultiSelectTabSegment extends StatelessWidget {
  /// The text rendered on this segment, already carrying its own count.
  final String label;

  /// Whether this segment is the currently active tab.
  final bool isSelected;

  /// Called when this segment is tapped.
  final VoidCallback onTap;

  /// Creates a new [_MultiSelectTabSegment].
  const _MultiSelectTabSegment({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    final backgroundColor = isSelected ? tokens.colors.primary.withValues(alpha: 0.12) : tokens.colors.sf2;
    final textColor = isSelected ? tokens.colors.primary : tokens.colors.fg3;

    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      onTap: onTap,
      excludeSemantics: true,
      child: LayrzTappable(
        onTap: onTap,
        borderRadius: tokens.radius.br1,
        color: backgroundColor,
        hoverColor: isSelected ? tokens.colors.primary.withValues(alpha: 0.18) : tokens.colors.sf3,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: tokens.spacing.sp2, vertical: tokens.spacing.sp1),
          alignment: Alignment.center,
          child: Text(
            label,
            style: tokens.typography.label.copyWith(
              color: textColor,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
