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

    // Build the current states for style resolution

    // Resolve the style spec from the field's interaction states
    final spec = LayrzInputStyleSpec.resolve(
      states: widget.states,
      tokens: tokens,
      hasErrors: widget.hasErrors,
      readOnly: widget.readOnly,
    );

    // Glyph color: use the spec's text color
    final glyphColor = spec.textColor;

    BorderRadius borderRadius;
    if (widget.isLeft) {
      borderRadius = BorderRadius.only(
        topLeft: Radius.circular(tokens.radius.r2),
        bottomLeft: Radius.circular(tokens.radius.r2),
      );
    } else {
      borderRadius = BorderRadius.only(
        topRight: Radius.circular(tokens.radius.r2),
        bottomRight: Radius.circular(tokens.radius.r2),
      );
    }

    final borderSpec = BorderSide(
      color: spec.borderColor,
      width: spec.borderWidth,
    );

    return AnimatedOpacity(
      duration: tokens.motion.dTransition,
      opacity: widget.isDisabled ? 0.5 : 1.0,
      child: LayrzTappable(
        disabled: widget.isDisabled,
        onTap: widget.onTap,
        color: tokens.colors.sf2,
        borderRadius: borderRadius,
        child: Container(
          padding: EdgeInsets.all(tokens.spacing.sp2),
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            border: Border(
              top: borderSpec,
              bottom: borderSpec,
              right: !widget.isLeft ? borderSpec : BorderSide.none,
              left: !widget.isLeft ? BorderSide.none : borderSpec,
            ),
          ),
          child: Align(
            alignment: Alignment.center,
            child: Icon(
              widget.isLeft ? MdiIcons.minus : MdiIcons.plus,
              size: tokens.typography.body.fontSize,
              color: glyphColor,
            ),
          ),
        ),
      ),
    );
  }
}
