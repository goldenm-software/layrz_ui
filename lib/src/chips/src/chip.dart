import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:layrz_ui/src/constants/constants.dart';
import 'package:layrz_ui/src/theme/theme.dart';

import 'chip_style.dart';
import 'chip_style_spec.dart';
import 'chip_type.dart';

/// A Material-free chip widget in the layrz_ui design system.
///
/// [LayrzChip] is a static, non-interactive visual representation of a compact label.
/// It supports optional leading icon and delete affordance. The chip itself has no tap,
/// hover, focus, or selection state — only the optional delete icon is interactive.
///
/// Chips are rendered at a fixed height with a rounded-box border radius
/// ([LayrzRadiusTokens.r1]) to match the design system's compact aesthetic. The
/// design system prefers rounded boxes over pills, so this is deliberately not
/// [LayrzRadiusTokens.full].
class LayrzChip extends StatefulWidget {
  /// The text label displayed in the chip.
  final String labelText;

  /// Optional icon displayed before the label.
  final IconData? leadingIcon;

  /// Called when the delete affordance is tapped. When null, no delete icon is rendered.
  final VoidCallback? onDelete;

  /// The visual style of the chip — determines fill, border, and shadow treatment.
  final LayrzChipStyle style;

  /// The semantic type of the chip — determines which token color to use.
  ///
  /// When [type] is [LayrzChipType.custom], the [color] parameter is honoured.
  /// For any other type, [color] must be null (enforced by assertion).
  final LayrzChipType type;

  /// The accent color for the chip.
  ///
  /// Only applied when [type] is [LayrzChipType.custom].
  /// Defaults to primary brand color if both [type] is custom and [color] is null.
  /// Must be null for any other [type].
  final Color? color;

  /// Creates a new [LayrzChip] with the given properties.
  ///
  /// The chip accent color is determined by [type]:
  /// - For [LayrzChipType.custom], uses the explicit [color] parameter (or primary if null)
  /// - For any other type, resolves to the corresponding semantic token color
  ///
  /// The [color] parameter is only used when [type] is [LayrzChipType.custom];
  /// passing a color with any other type triggers an assertion error.
  const LayrzChip({
    super.key,
    required this.labelText,
    this.leadingIcon,
    this.onDelete,
    this.style = LayrzChipStyle.filled,
    this.type = LayrzChipType.custom,
    this.color,
  }) : assert(
         type == LayrzChipType.custom || color == null,
         'color applies only when type is LayrzChipType.custom.',
       );

  /// Measures the intrinsic width this chip will occupy, in logical pixels.
  ///
  /// This method computes the width by measuring the label text at the current
  /// theme's label typography, then adding space for optional leading and delete icons.
  /// The result includes the horizontal padding and all inter-element spacing.
  ///
  /// Used by [LayrzChipGroup] in compact mode to determine when to show the `+N` indicator.
  double computeWidth(BuildContext context) {
    final tokens = LayrzTheme.of(context).tokens;

    // Measure label text at label typography
    final painter = TextPainter(
      text: TextSpan(
        text: labelText,
        style: tokens.typography.label,
      ),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();

    double width = painter.width;

    // Add space for leading icon
    if (leadingIcon != null) {
      width += kLayrzChipIconSize + tokens.spacing.sp1; // icon + gap
    }

    // Add space for delete icon
    if (onDelete != null) {
      width += kLayrzChipIconSize + tokens.spacing.sp1; // icon + gap
    }

    // Add horizontal padding
    width += (tokens.spacing.sp2 * 2);

    return width;
  }

  @override
  State<LayrzChip> createState() => _LayrzChipState();
}

class _LayrzChipState extends State<LayrzChip> {
  late final WidgetStatesController _deleteIconStatesController;

  @override
  void initState() {
    super.initState();
    _deleteIconStatesController = WidgetStatesController();
  }

  @override
  void dispose() {
    _deleteIconStatesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = LayrzTheme.of(context).tokens;

    // Resolve accent color
    final accent = widget.type.colorToken(tokens) ?? widget.color ?? tokens.colors.primary.shade500;

    // Resolve style spec
    final spec = LayrzChipStyleSpec.resolve(
      style: widget.style,
      accent: accent,
      tokens: tokens,
    );

    return Container(
      padding: EdgeInsets.symmetric(horizontal: tokens.spacing.sp2, vertical: tokens.spacing.sp1 / 2),
      decoration: BoxDecoration(
        color: spec.backgroundColor,
        border: widget.style.hasBorder
            ? Border.all(
                color: spec.borderColor,
                width: spec.borderWidth,
              )
            : null,
        borderRadius: BorderRadius.circular(tokens.radius.r1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Leading icon
          if (widget.leadingIcon != null) ...[
            Icon(
              widget.leadingIcon,
              color: spec.contentColor,
              size: kLayrzChipIconSize,
            ),
            SizedBox(width: tokens.spacing.sp1),
          ],

          // Label text
          Semantics(
            label: widget.labelText,
            child: Text(
              widget.labelText,
              style: tokens.typography.label.copyWith(
                color: spec.contentColor,
                fontWeight: tokens.typography.title.fontWeight,
                fontVariations: tokens.typography.title.fontVariations,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Delete affordance (if onDelete is non-null)
          if (widget.onDelete != null) ...[
            SizedBox(width: tokens.spacing.sp1),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Listener(
                onPointerDown: (_) {
                  _deleteIconStatesController.update(WidgetState.pressed, true);
                },
                onPointerUp: (_) {
                  _deleteIconStatesController.update(WidgetState.pressed, false);
                },
                onPointerCancel: (_) {
                  _deleteIconStatesController.update(WidgetState.pressed, false);
                },
                child: GestureDetector(
                  onTap: widget.onDelete,
                  child: Semantics(
                    button: true,
                    label: 'Delete ${widget.labelText}',
                    child: ValueListenableBuilder<Set<WidgetState>>(
                      valueListenable: _deleteIconStatesController,
                      builder: (context, states, child) {
                        final isPressed = states.contains(WidgetState.pressed);
                        final iconColor = LayrzChipStyleSpec.resolveDeleteIconColor(
                          contentColor: spec.contentColor,
                          isPressed: isPressed,
                        );
                        return Icon(
                          MdiIcons.close,
                          color: iconColor,
                          size: kLayrzChipIconSize,
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
