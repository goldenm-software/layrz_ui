import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/inputs/src/input_style_spec.dart';

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
  bool _isHovered = false;
  bool _isPressed = false;

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

    // Divider is a neutral internal visual element, independent of the field's border state
    final divider = BorderSide(
      color: tokens.colors.divider.withValues(alpha: 0.3),
      width: tokens.border.stroke2,
    );

    /// Computes the cap's background color based on interaction state.
    ///
    /// **Design decision: Hand-rolled hover/press instead of LayrzTappable**
    ///
    /// This widget uses a custom MouseRegion + Listener + GestureDetector implementation
    /// rather than LayrzTappable, because LayrzTappable hardcodes hover/press colors to
    /// its token-based surfaces (sf3/sf4) and cannot preserve the spec-derived tint through
    /// interaction states.
    ///
    /// Requirement: Error state shows pale danger, and hover/press must preserve that
    /// danger tint (not jump to a neutral surface). This requires deriving hover/press
    /// fills from a dynamic base color (spec.backgroundColor), which LayrzTappable cannot
    /// express.
    ///
    /// LayrzTappable API limitation (lib/src/tappable/src/tappable.dart, line 122):
    /// - `_resolveColor()` hardcodes hover → sf3, pressed → sf4
    /// - No parameter to supply per-state colors or a callback to resolve them
    /// - Can only accept a single static `color` for the idle state
    ///
    /// Solution: Modulate opacity of the spec-derived base color to indicate hover/press
    /// while maintaining hue and saturation. Idle uses spec.backgroundColor directly,
    /// hover increases opacity to 1.1x, pressed decreases to 0.85x.
    ///
    /// Future: If LayrzTappable is extended to accept a color resolution callback,
    /// this hand-rolled implementation should be replaced.
    Color resolveBackgroundColor() {
      if (widget.isDisabled) {
        // Disabled uses a tint that's independent of the spec (grey-ish)
        return tokens.colors.fg3.withValues(alpha: 0.12);
      }

      if (_isPressed) {
        // Pressed: slightly darker than the spec's background, maintaining the tint
        // Reduce opacity slightly to indicate pressed state
        final currentAlpha = (spec.backgroundColor.a * 255.0).round();
        final pressedAlpha = (currentAlpha * 0.85 / 255.0).clamp(0.0, 1.0);
        return spec.backgroundColor.withValues(alpha: pressedAlpha);
      }

      if (_isHovered) {
        // Hover: slightly lighter than the spec's background, maintaining the tint
        // Increase opacity slightly to indicate hover state
        final currentAlpha = (spec.backgroundColor.a * 255.0).round();
        final hoveredAlpha = (currentAlpha * 1.1 / 255.0).clamp(0.0, 1.0);
        return spec.backgroundColor.withValues(alpha: hoveredAlpha);
      }

      // Idle: use the spec's background so error state shows pale danger
      return spec.backgroundColor;
    }

    return AnimatedOpacity(
      duration: tokens.motion.dTransition,
      opacity: widget.isDisabled ? 0.5 : 1.0,
      child: MouseRegion(
        onEnter: widget.isDisabled ? null : (_) => setState(() => _isHovered = true),
        onExit: widget.isDisabled ? null : (_) => setState(() => _isHovered = false),
        cursor: widget.isDisabled ? MouseCursor.defer : SystemMouseCursors.click,
        child: Listener(
          onPointerDown: widget.isDisabled ? null : (_) => setState(() => _isPressed = true),
          onPointerUp: widget.isDisabled ? null : (_) => setState(() => _isPressed = false),
          onPointerCancel: widget.isDisabled ? null : (_) => setState(() => _isPressed = false),
          child: GestureDetector(
            onTap: widget.onTap,
            child: Container(
              padding: EdgeInsets.all(tokens.spacing.sp2),
              decoration: BoxDecoration(
                borderRadius: capRadius,
                color: resolveBackgroundColor(),
                border: Border(
                  right: widget.isLeft ? divider : BorderSide.none,
                  left: !widget.isLeft ? divider : BorderSide.none,
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
        ),
      ),
    );
  }
}
