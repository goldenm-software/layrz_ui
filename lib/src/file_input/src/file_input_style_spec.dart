import 'package:flutter/widgets.dart';

import 'package:layrz_ui/src/tokens/tokens.dart';

/// The four visually distinct states [LayrzFileInput]'s drop-zone box can be in.
///
/// Unlike a standard chrome-based field (see `LayrzInputStyleSpec`), the box has
/// no read-only or focused-text state of its own -- it is a click/drop target,
/// not a text field -- so its state set is deliberately narrower.
enum LayrzFileInputState {
  /// No files have been picked or dropped yet, and the pointer is not
  /// currently over the box.
  empty,

  /// The pointer is hovering the box (desktop/mouse only), with no active
  /// drag-and-drop operation. Also used while the box has keyboard focus.
  hover,

  /// A drag-and-drop operation from the OS or browser is currently over the
  /// box. Distinct from [hover] because a drop is imminent -- see the class
  /// doc on [LayrzFileInput] for why this must read as its own state rather
  /// than reusing [hover]'s styling.
  dragging,

  /// At least one file has been picked or dropped and accepted.
  populated,
}

/// Immutable specification of visual properties for [LayrzFileInput]'s
/// drop-zone box in a given [LayrzFileInputState].
///
/// Holds only paint properties -- fill color, border color, border width, and
/// icon/text color -- computed by [resolve] from the current state, whether
/// the box currently reports errors (e.g. a rejected file), and design tokens.
///
/// Per decision D15, only colour/border-colour/shadow vary across states;
/// [resolve] never changes geometry (padding, border width stays constant,
/// only its colour does).
@immutable
class LayrzFileInputStyleSpec {
  /// The fill color of the drop-zone box.
  final Color backgroundColor;

  /// The color of the drop-zone box's border.
  final Color borderColor;

  /// The width of the drop-zone box's border in logical pixels.
  final double borderWidth;

  /// The color used for the box's icon and label text.
  final Color contentColor;

  /// Creates a new [LayrzFileInputStyleSpec].
  const LayrzFileInputStyleSpec({
    required this.backgroundColor,
    required this.borderColor,
    required this.borderWidth,
    required this.contentColor,
  });

  /// Returns a copy of this spec with the given fields replaced.
  LayrzFileInputStyleSpec copyWith({
    Color? backgroundColor,
    Color? borderColor,
    double? borderWidth,
    Color? contentColor,
  }) {
    return LayrzFileInputStyleSpec(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      contentColor: contentColor ?? this.contentColor,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LayrzFileInputStyleSpec &&
          runtimeType == other.runtimeType &&
          backgroundColor == other.backgroundColor &&
          borderColor == other.borderColor &&
          borderWidth == other.borderWidth &&
          contentColor == other.contentColor;

  @override
  int get hashCode => Object.hash(backgroundColor, borderColor, borderWidth, contentColor);

  /// Resolves a [LayrzFileInputStyleSpec] from the current [state], tokens,
  /// and whether the box currently reports errors (e.g. a rejected file).
  ///
  /// **State precedence:** disabled > error > dragging > hover > populated > empty.
  /// A disabled box never reflects [state] at all -- disabled always wins.
  /// An error color takes over the border/content regardless of [state], since
  /// a rejection must stay visible even while the pointer is hovering again to
  /// retry.
  ///
  /// | State | Fill | Border | Content |
  /// |---|---|---|---|
  /// | disabled | `sf2` | transparent | `fg4` |
  /// | error | `danger.shade50` | `danger` | `danger` |
  /// | dragging | `primary.shade50` | `primary` (thicker) | `primary` |
  /// | hover | `sf3` | `primary` | `primary` |
  /// | populated | `sf1` | `divider` | `fg1` |
  /// | empty | `sf2` | `divider` (dashed intent) | `fg3` |
  ///
  /// Border width is [LayrzBorderTokens.stroke2] for every state except
  /// [LayrzFileInputState.dragging], which uses double that width -- the one
  /// deliberate geometry change, reserved for the single state where a
  /// stronger affordance ("drop here now") outweighs D15's usual constraint.
  static LayrzFileInputStyleSpec resolve({
    required LayrzFileInputState state,
    required LayrzTokens tokens,
    required bool hasErrors,
    bool disabled = false,
  }) {
    if (disabled) {
      return LayrzFileInputStyleSpec(
        backgroundColor: tokens.colors.sf2,
        borderColor: const Color(0x00000000),
        borderWidth: tokens.border.stroke2,
        contentColor: tokens.colors.fg4,
      );
    }

    if (hasErrors) {
      return LayrzFileInputStyleSpec(
        backgroundColor: tokens.colors.danger.shade50,
        borderColor: tokens.colors.danger,
        borderWidth: tokens.border.stroke2,
        contentColor: tokens.colors.danger,
      );
    }

    switch (state) {
      case LayrzFileInputState.dragging:
        return LayrzFileInputStyleSpec(
          backgroundColor: tokens.colors.primary.shade50,
          borderColor: tokens.colors.primary,
          borderWidth: tokens.border.stroke2 * 2,
          contentColor: tokens.colors.primary,
        );
      case LayrzFileInputState.hover:
        return LayrzFileInputStyleSpec(
          backgroundColor: tokens.colors.sf3,
          borderColor: tokens.colors.primary,
          borderWidth: tokens.border.stroke2,
          contentColor: tokens.colors.primary,
        );
      case LayrzFileInputState.populated:
        return LayrzFileInputStyleSpec(
          backgroundColor: tokens.colors.sf1,
          borderColor: tokens.colors.divider,
          borderWidth: tokens.border.stroke2,
          contentColor: tokens.colors.fg1,
        );
      case LayrzFileInputState.empty:
        return LayrzFileInputStyleSpec(
          backgroundColor: tokens.colors.sf2,
          borderColor: tokens.colors.divider,
          borderWidth: tokens.border.stroke2,
          contentColor: tokens.colors.fg3,
        );
    }
  }
}
