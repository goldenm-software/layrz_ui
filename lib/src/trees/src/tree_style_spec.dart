import 'package:flutter/widgets.dart';

import 'package:layrz_ui/src/tokens/tokens.dart';

/// Resolved visual values for a single row of [LayrzTreeView] or
/// [LayrzSliverTreeView], derived from [LayrzTokens] plus the row's own
/// selection/hover state.
///
/// This mirrors the "style spec" pattern used across the design system (e.g.
/// `LayrzChipStyleSpec`): a plain data holder computed once per row build,
/// so the row widget itself never re-derives colors from raw tokens inline.
@immutable
class LayrzTreeRowStyleSpec {
  /// Creates a [LayrzTreeRowStyleSpec].
  const LayrzTreeRowStyleSpec({
    required this.backgroundColor,
    required this.foregroundColor,
    required this.indentGuideColor,
    required this.chevronColor,
    required this.checkboxBorderColor,
    required this.checkboxFillColor,
    required this.checkboxGlyphColor,
    required this.activeBorderColor,
  });

  /// Resolves a [LayrzTreeRowStyleSpec] from [tokens] and the row's current
  /// interaction/selection state.
  ///
  /// Per decision D15, only colour (never geometry) varies across
  /// hover/selected/active/disabled states — this factory is the single place
  /// that rule is applied for tree rows. [isActive] marks the row currently
  /// focused by keyboard navigation (see [LayrzTreeController.activeId]); it
  /// is rendered as a border colour change only ([activeBorderColor]), never
  /// as a background swap, so it composes cleanly with [isSelected] /
  /// [isPartiallySelected] instead of fighting them for the same visual slot.
  ///
  /// Selection itself is intentionally NOT painted as a background fill: the
  /// checkbox affordance ([checkboxBorderColor]/[checkboxFillColor]) is the
  /// sole visual marker of [isSelected]/[isPartiallySelected] (maintainer
  /// review, DESIGN-93) -- a full-row tint was judged redundant with the
  /// checkbox and would otherwise force every foreground colour drawn on the
  /// row to stay legible against a background that can change per-row.
  factory LayrzTreeRowStyleSpec.resolve(
    LayrzTokens tokens, {
    required bool isHovered,
    required bool isSelected,
    required bool isPartiallySelected,
    bool isActive = false,
  }) {
    final Color backgroundColor;
    if (isHovered) {
      backgroundColor = tokens.colors.sf2;
    } else {
      backgroundColor = tokens.colors.sf1;
    }

    return LayrzTreeRowStyleSpec(
      backgroundColor: backgroundColor,
      foregroundColor: tokens.colors.fg1,
      indentGuideColor: tokens.colors.divider,
      chevronColor: tokens.colors.fg2,
      checkboxBorderColor: isSelected || isPartiallySelected ? tokens.colors.primary.shade500 : tokens.colors.fg3,
      checkboxFillColor: tokens.colors.primary.shade500,
      checkboxGlyphColor: tokens.colors.sf1,
      activeBorderColor: isActive ? tokens.colors.primary.shade500 : const Color(0x00000000),
    );
  }

  /// The row's background fill.
  final Color backgroundColor;

  /// The row's label text/icon colour.
  final Color foregroundColor;

  /// The colour of the vertical indent guide lines.
  final Color indentGuideColor;

  /// The colour of the expand/collapse chevron glyph.
  final Color chevronColor;

  /// The border colour of the selection checkbox affordance when unfilled.
  final Color checkboxBorderColor;

  /// The fill colour of the selection checkbox affordance when
  /// selected or partially selected.
  ///
  /// This reads `primary.shade500`, not `primary.shade50`:
  /// `LayrzColorSwatch.fromColor` derives shade50 by subtracting 0.40 from
  /// the seed's HSL lightness, which clamps to fully opaque black whenever
  /// the seed itself is dark (e.g. the default `kPrimaryColor`, lightness
  /// ~0.19). shade500 is guaranteed sane, since it always equals the seed
  /// colour unchanged. This generator defect is still present upstream and
  /// unfixed; it is documented here because this is the field in this spec
  /// that still resolves a primary shade for a filled visual -- the row's
  /// background fill that previously hit this same defect has since been
  /// removed entirely (selection is now marked by the checkbox alone, per
  /// maintainer review, DESIGN-93).
  final Color checkboxFillColor;

  /// The colour of the checkmark/dash glyph drawn inside a filled checkbox.
  final Color checkboxGlyphColor;

  /// The colour of the row's outline when it is the keyboard-active row.
  ///
  /// Fully transparent when the row is not active. The outline is always
  /// painted at a constant width (see [LayrzTreeRow]) and only its colour
  /// changes, per D15 — this keeps the row's geometry identical whether or
  /// not it is active, avoiding reflow when keyboard focus moves.
  final Color activeBorderColor;
}
