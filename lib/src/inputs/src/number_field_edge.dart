import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/inputs/src/input_style_spec.dart';
import 'package:layrz_ui/src/tappable/tappable.dart';

/// Increment control button (+) for [LayrzNumberInput].
///
/// Renders as a full-height edge control flanking the input chrome. The control's
/// outer edge is rounded; the inner edge (adjacent to the chrome) is square to form
/// a continuous boundary. State changes affect color, opacity, and cursor only, never geometry.
///
/// Uses the same [LayrzInputStyleSpec] as the chrome to ensure styling consistency across
/// the control and field. The control's background, border, and text colors match the
/// chrome in every interaction state (default, focused, error, disabled, read-only).
class NumberFieldControl extends StatefulWidget {
  /// Callback fired when the control is tapped.
  ///
  /// Ignored if the control is disabled.
  final VoidCallback? onTap;

  /// Whether the control is disabled.
  final bool isDisabled;

  /// Whether the field has errors.
  ///
  /// When true, the control resolves to error styling via [LayrzInputStyleSpec].
  final bool hasErrors;

  /// The widget interaction states (focused, hovered, pressed, disabled).
  ///
  /// Used by [LayrzInputStyleSpec.resolve] to determine border color, background,
  /// and text color in the current state. Must include [WidgetState.disabled] if
  /// [isDisabled] is true, and [WidgetState.focused] if the field is focused.
  final Set<WidgetState> states;

  /// Whether the field is read-only.
  final bool readOnly;

  /// isLeft indicates whether the control is the left (decrement) or right (increment) control.
  final bool isLeft;

  /// Creates a new [NumberFieldControl].
  const NumberFieldControl({
    super.key,
    this.onTap,
    required this.isDisabled,
    required this.hasErrors,
    required this.states,
    required this.readOnly,
    required this.isLeft,
  });

  @override
  State<NumberFieldControl> createState() => _NumberFieldControlState();
}

class _NumberFieldControlState extends State<NumberFieldControl> {
  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    // Resolve the style spec from the field's interaction states
    final spec = LayrzInputStyleSpec.resolve(
      states: widget.states,
      tokens: tokens,
      hasErrors: widget.hasErrors,
      readOnly: widget.readOnly,
    );

    // Glyph color: use the spec's text color
    final glyphColor = spec.textColor;

    // Compute the cap's outer corner radius using the token helper to account for border width.
    // The inner radius subtracts the border width from the outer radius (r2 from the outer container)
    // so the cap's fill sits correctly inside the outer container's stroked border.
    final innerR = Radius.circular(
      tokens.radius.innerRadiusValue(
        outerRadius: tokens.radius.r2,
        spacer: spec.borderWidth,
      ),
    );

    // Each cap rounds its outer corners only; the inner side (facing the chrome) stays square.
    final capRadius = widget.isLeft
        ? BorderRadius.only(topLeft: innerR, bottomLeft: innerR)
        : BorderRadius.only(topRight: innerR, bottomRight: innerR);

    // Divider is error-aware: red on error, neutral in all other states (focused, disabled, etc).
    // This is deliberately independent of focus/disabled states; only error changes it.
    final dividerColor = widget.hasErrors ? tokens.colors.danger : tokens.colors.divider.withValues(alpha: 0.3);
    final divider = BorderSide(
      color: dividerColor,
      width: tokens.border.stroke2,
    );

    // Compute hover and pressed colors: use real colour swaps for clear feedback.
    // On error, stay in the danger family (shade100 hover, shade200 pressed).
    // On non-error, use LayrzTappable's standard steps (sf3 hover, sf4 pressed).
    final Color hoverColor;
    final Color pressedColor;

    if (widget.hasErrors) {
      // Error state: use darker danger shades for clearly visible feedback
      hoverColor = tokens.colors.danger.shade100;
      pressedColor = tokens.colors.danger.shade200;
    } else {
      // Non-error states (focused, disabled, default): use neutral surface steps
      hoverColor = tokens.colors.sf3;
      pressedColor = tokens.colors.sf4;
    }

    final capContent = Padding(
      padding: EdgeInsets.all(tokens.spacing.sp2),
      child: Align(
        alignment: Alignment.center,
        child: Icon(
          widget.isLeft ? MdiIcons.minus : MdiIcons.plus,
          size: tokens.typography.body.fontSize,
          color: glyphColor,
        ),
      ),
    );

    // Build the interactive tappable surface that handles hover/press effects.
    // The idle color is applied to the outer Container instead, to keep the background
    // and border together for testing purposes.
    final tappableSurface = LayrzTappable(
      onTap: widget.onTap,
      disabled: widget.isDisabled,
      borderRadius: capRadius,
      color: spec.backgroundColor,
      hoverColor: hoverColor,
      pressedColor: pressedColor,
      child: capContent,
    );

    // The outer Container applies both the background color (for idle/disabled states)
    // and the divider borders on the inner edges. LayrzTappable inside handles hover/press.
    final capWithDivider = Container(
      decoration: BoxDecoration(
        borderRadius: capRadius,
        color: spec.backgroundColor,
        border: Border(
          right: widget.isLeft ? divider : BorderSide.none,
          left: !widget.isLeft ? divider : BorderSide.none,
        ),
      ),
      child: tappableSurface,
    );

    return AnimatedOpacity(
      duration: tokens.motion.dTransition,
      opacity: widget.isDisabled ? 0.5 : 1.0,
      child: capWithDivider,
    );
  }
}
