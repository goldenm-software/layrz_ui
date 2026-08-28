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
  factory LayrzTreeRowStyleSpec.resolve(
    LayrzTokens tokens, {
    required bool isHovered,
    required bool isSelected,
    required bool isPartiallySelected,
    bool isActive = false,
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
