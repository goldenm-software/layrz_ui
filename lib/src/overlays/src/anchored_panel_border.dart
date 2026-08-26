import 'package:flutter/widgets.dart';

/// Describes an optional border painted around [LayrzAnchoredPanel]'s own
/// decorated box -- the box that wraps its scroll viewport and is clamped to
/// [LayrzAnchoredPanel.maxHeight] -- rather than around any content the
/// caller passes as `child`.
///
/// This exists because every panel caller that wants a border historically
/// drew it itself, around its own content widget. Content sits *inside* the
/// panel's `SingleChildScrollView`, which relaxes its child's height
/// constraint to unbounded along the scroll axis -- so a hand-rolled bordered
/// box there sizes itself to the full, uncapped content height instead of the
/// panel's actual, capped viewport. [LayrzAnchoredPanelBorder] lets a caller
/// describe the border it wants and hand it to the panel, which paints it
/// around the box that is genuinely capped.
///
/// Painted with `strokeAlign: BorderSide.strokeAlignOutside` so adding a
/// border never insets the panel's content or changes its occupied geometry
/// (D15 -- interaction-driven appearance changes must never affect layout).
@immutable
class LayrzAnchoredPanelBorder {
  /// The color of the border stroke.
  ///
  /// Typically a semantic token color, such as `tokens.colors.primary` for a
  /// focused state or `tokens.colors.danger` for an error state.
  final Color color;

  /// The width of the border stroke in logical pixels.
  ///
  /// Typically `tokens.border.base`. Painted with
  /// `strokeAlign: BorderSide.strokeAlignOutside`, so this width extends
  /// outward from the panel's decorated box and never changes its size.
  final double width;

  /// Creates a new [LayrzAnchoredPanelBorder].
  ///
  /// Both [color] and [width] are required: a border description with no
  /// visual definition is not a meaningful value, so there are no defaults to
  /// silently fall back to.
  const LayrzAnchoredPanelBorder({
    required this.color,
    required this.width,
  });

  /// Returns a copy of this border description with the given fields
  /// replaced.
  LayrzAnchoredPanelBorder copyWith({
    Color? color,
    double? width,
  }) {
    return LayrzAnchoredPanelBorder(
      color: color ?? this.color,
      width: width ?? this.width,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LayrzAnchoredPanelBorder &&
          runtimeType == other.runtimeType &&
          color == other.color &&
          width == other.width;

  @override
  int get hashCode => Object.hash(color, width);

  @override
  String toString() => 'LayrzAnchoredPanelBorder(color: $color, width: $width)';
}
