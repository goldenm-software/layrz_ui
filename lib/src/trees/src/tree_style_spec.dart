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
  });

  /// Resolves a [LayrzTreeRowStyleSpec] from [tokens] and the row's current
  /// interaction/selection state.
  ///
  /// Per decision D15, only colour (never geometry) varies across
  /// hover/selected/disabled states — this factory is the single place that
  /// rule is applied for tree rows.
  factory LayrzTreeRowStyleSpec.resolve(
    LayrzTokens tokens, {
    required bool isHovered,
    required bool isSelected,
    required bool isPartiallySelected,
  }) {
    final Color backgroundColor;
    if (isSelected || isPartiallySelected) {
      backgroundColor = tokens.colors.primary.shade50;
    } else if (isHovered) {
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
  final Color checkboxFillColor;

  /// The colour of the checkmark/dash glyph drawn inside a filled checkbox.
  final Color checkboxGlyphColor;
}
