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
  /// hover/pressed/selected/active states — this factory is the single place
  /// that rule is applied for tree rows. [isActive] marks the row currently
  /// focused by keyboard navigation (see [LayrzTreeController.activeId]); it
  /// is rendered as a border colour change only ([activeBorderColor]), never
  /// as a background swap, so it composes cleanly with [isSelected] /
  /// [isPartiallySelected] instead of fighting them for the same visual slot.
  ///
  /// **Resting background is genuinely transparent** (maintainer ruling,
  /// DESIGN-171, with photographic evidence): an intermediate pass painted an
  /// opaque `sf1` fill at rest on the theory that `sf1` matches most
  /// enclosing containers' own surface colour, so no seam would be visible.
  /// The maintainer rejected that: the row's fill is a square rectangle, and
  /// a container with a rounded border shows the corner of that square
  /// poking past its own curve regardless of whether the two colours match —
  /// the bug is geometric (a square fill inside a rounded frame), not
  /// chromatic (a mismatched colour), so no fill colour choice at rest fixes
  /// it. Resting therefore paints nothing at all, and [LayrzTreeRow] is
  /// separately responsible for keeping every *other* state's fill from
  /// reaching the row's own outer edge (see that file's class doc comment),
  /// which is what actually stops the bleed the maintainer photographed —
  /// that photo was of a *hovered* row, not a resting one.
  ///
  /// [isHovered], [isPressed], [isSelected]/[isPartiallySelected] and
  /// [isActive] each still resolve a visible tint so no interaction feedback
  /// is lost by removing the resting fill (an earlier pass, DESIGN-93, had
  /// selection paint no background at all — that traded on resting *also*
  /// being an opaque fill, which is no longer true either way, so selection
  /// gets its own subdued tint here to stay visible on its own rather than
  /// depending solely on the checkbox glyph). [isPressed] gives the row's own
  /// tap surface the same press feedback its sibling controls
  /// (checkbox/switch/radio) give theirs, now that the label itself is a tap
  /// target (DESIGN-166).
  factory LayrzTreeRowStyleSpec.resolve(
    LayrzTokens tokens, {
    required bool isHovered,
    required bool isSelected,
    required bool isPartiallySelected,
    bool isPressed = false,
    bool isActive = false,
  }) {
    // Selection paints a translucent primary tint underneath everything else,
    // not `primary.shade50`: `LayrzColorSwatch.fromColor` derives shade50 by
    // subtracting 0.40 from the seed's HSL lightness, which clamps to fully
    // opaque black for any seed under that lightness (e.g. the default
    // `kPrimaryColor`, ~0.19) -- the exact defect `checkboxFillColor`'s doc
    // comment below warns about. Applying alpha to the seed colour itself
    // sidesteps the swatch derivation entirely and can never clamp to black.
    Color backgroundColor = (isSelected || isPartiallySelected)
        ? tokens.colors.primary.withValues(alpha: 0.12)
        : const Color(0x00000000);

    // Hover/pressed compose on top of that base rather than replacing it, so
    // a selected row that is also hovered (or pressed) still reads as
    // selected -- an opaque surface step alone would otherwise erase the
    // selection tint underneath it.
    if (isPressed) {
      backgroundColor = Color.alphaBlend(tokens.colors.sf4.withValues(alpha: 0.72), backgroundColor);
    } else if (isHovered) {
      backgroundColor = Color.alphaBlend(tokens.colors.sf3.withValues(alpha: 0.6), backgroundColor);
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
  /// own [backgroundColor] avoids the same defect by applying alpha to the
  /// seed colour directly (see [resolve]) rather than reading a derived
  /// shade.
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
