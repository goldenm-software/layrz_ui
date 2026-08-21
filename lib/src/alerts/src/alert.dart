import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

import 'package:layrz_ui/src/constants/constants.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/tokens/tokens.dart';

import 'alert_style.dart';
import 'alert_style_spec.dart';
import 'alert_type.dart';

/// An inline status callout that communicates information, success, warnings, or errors.
///
/// [LayrzAlert] is a widget that displays a semantic message via
/// colour, icon, title text, and body text. It supports multiple styles
/// ([LayrzAlertStyle]) and types ([LayrzAlertType]) to fit different contexts.
///
/// The widget requires both [title] and [description] — there are no optional variants.
/// The [type] parameter controls the semantic colour and icon (info, success, warning,
/// danger, context, or custom). The [style] parameter controls visual appearance
/// (layrz or filledIcon).
///
/// **Interaction behavior:**
/// - When [onTap] is **null**, the alert is inert: no hover response, no press response,
///   default cursor, not focusable, and it does NOT appear as a button to assistive technology.
///   No shadow is applied.
/// - When [onTap] is **non-null**, the alert is interactive:
///   - Cursor becomes [SystemMouseCursors.click].
///   - **At rest**: no shadow.
///   - **Hovered**: surface lifts by [kLayrzAlertHoverLift] and shadow appears at elevation 2.
///   - **Focused**: surface lifts (same as hover) and shadow appears at elevation 2.
///   - **Pressed without prior hover** (touch device): surface lifts by [kLayrzAlertHoverLift] and shadow
///     appears at elevation 2 (touch press gets the full hover treatment for visibility).
///   - **Pressed with prior hover** (desktop): surface settles back down and shadow steps down to elevation 1.
///   - Geometry (size, padding, radius) remains constant across states.
///   - Focusable by Tab navigation; activatable by Enter or Space keys.
///   - Announced to assistive technology as an interactive button.
///   - Shadow animates alongside lift with [LayrzTokens.motion.dHover] duration and [LayrzTokens.motion.easingEnter] curve.
///
/// Layout:
/// A split-panel design with an icon on the left and text on the right (neutral
/// surface background). The left panel is tonal for [LayrzAlertStyle.layrz] and solid
/// accent for [LayrzAlertStyle.filledIcon].
///
/// Responsive:
/// - No fixed heights on text-bearing elements (supports WCAG 1.4.4 text scaling).
/// - Only the icon and filledIcon left panel have fixed dimensions.
class LayrzAlert extends StatefulWidget {
  /// The semantic type of the alert.
  ///
  /// Determines the default icon and colour. Defaults to [LayrzAlertType.info].
  /// If [type] is [LayrzAlertType.custom], the [color] and [icon] parameters
  /// control appearance; otherwise they are ignored.
  final LayrzAlertType type;

  /// The title text of the alert.
  ///
  /// Required. Displays as bold title text. Scales with system text scale factor.
  final String title;

  /// The description text of the alert.
  ///
  /// Required. Displays as body text. Limited to [maxLines] lines before ellipsis.
  /// Scales with system text scale factor.
  final String description;

  /// The maximum number of lines for [description] text.
  ///
  /// If the description exceeds this many lines, it is truncated with an ellipsis.
  /// Defaults to 3.
  final int maxLines;

  /// The visual style of the alert.
  ///
  /// Determines background, border, icon chip, and text colours.
  /// Defaults to [LayrzAlertStyle.layrz].
  final LayrzAlertStyle style;

  /// The custom colour of the alert, used only when [type] is [LayrzAlertType.custom].
  ///
  /// If [type] is not custom, this parameter is ignored.
  /// If null and [type] is custom, defaults to [LayrzTokens.colors.primary].
  final Color? color;

  /// The custom icon glyph, used only when [type] is [LayrzAlertType.custom].
  ///
  /// If [type] is not custom, this parameter is ignored.
  /// If null and [type] is custom, defaults to [MdiIcons.informationBoxOutline].
  final IconData? icon;

  /// The size of the icon glyph.
  ///
  /// If null, defaults to [kLayrzAlertFilledIconSize].
  final double? iconSize;

  /// Called when the user taps the alert.
  ///
  /// When null, the alert is not interactive (no cursor change, no hover/press feedback).
  final VoidCallback? onTap;

  /// Creates a [LayrzAlert].
  const LayrzAlert({
    super.key,
    this.type = LayrzAlertType.info,
    required this.title,
    required this.description,
    this.maxLines = 3,
    this.style = LayrzAlertStyle.layrz,
    this.color,
    this.icon,
    this.iconSize,
    this.onTap,
  });

  @override
  State<LayrzAlert> createState() => _LayrzAlertState();
}

class _LayrzAlertState extends State<LayrzAlert> {
  /// Controller to manage interactive states (hovered, pressed, focused).
  late WidgetStatesController _statesController;

  /// Current vertical lift amount during interaction.
  late double _currentLift;

  @override
  void initState() {
    super.initState();
    _statesController = WidgetStatesController();
    _currentLift = 0.0;
  }

  @override
  void dispose() {
    _statesController.dispose();
    super.dispose();
  }

  /// Handles pointer down to set the pressed state.
  void _onPointerDown(PointerDownEvent event) {
    if (widget.onTap == null) return;
    _statesController.update(WidgetState.pressed, true);
    _updateLift();
  }

  /// Handles pointer up or cancel to release the pressed state.
  void _onPointerUp(PointerEvent event) {
    if (widget.onTap == null) return;
    _statesController.update(WidgetState.pressed, false);
    _updateLift();
  }

  /// Updates the current lift based on hover, press, and focus states.
  ///
  /// A press not preceded by hover gets the hover treatment (touch press feedback).
  /// A press preceded by hover settles back down (desktop interaction).
  void _updateLift() {
    if (!mounted) return;

    double newLift = 0.0;
    final states = _statesController.value;
    final isPressed = states.contains(WidgetState.pressed);
    final isHovered = states.contains(WidgetState.hovered);
    final isFocused = states.contains(WidgetState.focused);

    // Hover or Focus: lift the surface up.
    if (isHovered || isFocused) {
      newLift = kLayrzAlertHoverLift;
    }

    // Press handling: touch press gets hover treatment, desktop press settles down.
    if (isPressed) {
      if (isHovered) {
        // Desktop case: press while already hovered settles back down.
        newLift = 0.0;
      } else {
        // Touch case: press without prior hover gets hover treatment (lift + elevation2).
        newLift = kLayrzAlertHoverLift;
      }
    }

    if (newLift != _currentLift) {
      setState(() {
        _currentLift = newLift;
      });
    }
  }

  /// Resolves the shadow list for the current interactive state.
  ///
  /// Returns null for inert alerts (onTap == null) and at-rest interactive alerts.
  /// Returns [LayrzShadowTokens.elevation2] for:
  ///   - Hovered or focused states
  ///   - Pressed state without prior hover (touch press gets hover treatment)
  /// Returns [LayrzShadowTokens.elevation1] for pressed state with prior hover (desktop interaction).
  List<BoxShadow>? _resolveShadow(LayrzTokens tokens) {
    // Inert alerts have no shadow.
    if (widget.onTap == null) return null;

    final states = _statesController.value;
    final isPressed = states.contains(WidgetState.pressed);
    final isHovered = states.contains(WidgetState.hovered);
    final isFocused = states.contains(WidgetState.focused);

    // Pressed without prior hover: elevated shadow (touch press gets hover treatment).
    if (isPressed && !isHovered) {
      return tokens.shadow.elevation2;
    }

    // Pressed with prior hover: lower shadow level (desktop interaction).
    if (isPressed && isHovered) {
      return tokens.shadow.elevation1;
    }

    // Hovered or Focused: elevated shadow.
    if (isHovered || isFocused) {
      return tokens.shadow.elevation2;
    }

    // At rest: no shadow.
    return null;
  }

  /// Builds the split-panel content for layrz and filledIcon styles.
  ///
  /// Creates a clipped row with a left panel (icon on colored background)
  /// and a right panel (title and description on surface background).
  /// The border is painted via foregroundDecoration to avoid antialiasing seams.
  Widget _buildSplitPanelContent({
    required LayrzTokens tokens,
    required Color leftPanelColor,
    required IconData icon,
    required Color iconColor,
    required double iconSize,
  }) {
    return ClipRRect(
      borderRadius: tokens.radius.br3,
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Left panel: colored background with icon.
            ExcludeSemantics(
              child: Container(
                color: leftPanelColor,
                padding: EdgeInsets.all(tokens.spacing.sp3),
                child: Center(
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: iconSize,
                  ),
                ),
              ),
            ),
            // Right panel: surface background with title and description.
            Expanded(
              child: Container(
                color: tokens.colors.sf2,
                padding: EdgeInsets.all(tokens.spacing.sp3),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: tokens.typography.title.copyWith(
                        fontWeight: FontWeight.bold,
                        color: tokens.colors.fg1,
                      ),
                    ),
                    SizedBox(height: tokens.spacing.sp1),
                    Text(
                      widget.description,
                      style: tokens.typography.body.copyWith(
                        color: tokens.colors.fg2,
                      ),
                      maxLines: widget.maxLines,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    // Resolve accent colour.
    Color accentColor;
    if (widget.type == LayrzAlertType.custom) {
      accentColor = widget.color ?? tokens.colors.primary.shade500;
    } else {
      accentColor = widget.type.colorToken(tokens) ?? tokens.colors.primary.shade500;
    }

    // Resolve icon.
    IconData resolvedIcon;
    if (widget.type == LayrzAlertType.custom) {
      resolvedIcon = widget.icon ?? MdiIcons.informationBoxOutline;
    } else {
      resolvedIcon = widget.type.icon ?? MdiIcons.informationBoxOutline;
    }

    // Resolve icon size.
    final effectiveIconSize = widget.iconSize ?? kLayrzAlertFilledIconSize;

    // Resolve spec.
    final spec = LayrzAlertStyleSpec.resolve(
      style: widget.style,
      accent: accentColor,
      tokens: tokens,
      isInteractive: widget.onTap != null,
    );

    // Build split-panel content.
    final content = _buildSplitPanelContent(
      tokens: tokens,
      leftPanelColor: spec.leftPanelColor,
      icon: resolvedIcon,
      iconColor: spec.iconColor,
      iconSize: effectiveIconSize,
    );

    // If not interactive, return the content as-is with container semantics.
    if (widget.onTap == null) {
      return Semantics(
        label: '${widget.title}. ${widget.description}',
        container: true,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: tokens.radius.br3,
          ),
          foregroundDecoration: BoxDecoration(
            border: Border.all(
              color: spec.borderColor,
              width: spec.borderWidth,
            ),
            borderRadius: tokens.radius.br3,
          ),
          child: content,
        ),
      );
    }

    // If interactive, wrap with focus, keyboard, and semantic support.
    final interactiveAlert = FocusableActionDetector(
      onShowHoverHighlight: (show) {
        _statesController.update(WidgetState.hovered, show);
        _updateLift();
      },
      onShowFocusHighlight: (show) {
        _statesController.update(WidgetState.focused, show);
        _updateLift();
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onTap!();
            return null;
          },
        ),
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) {
          _statesController.update(WidgetState.hovered, true);
          _updateLift();
        },
        onExit: (_) {
          _statesController.update(WidgetState.hovered, false);
          _updateLift();
        },
        child: Listener(
          onPointerDown: _onPointerDown,
          onPointerUp: _onPointerUp,
          onPointerCancel: _onPointerUp,
          child: GestureDetector(
            onTap: widget.onTap,
            onTapCancel: () {
              _statesController.update(WidgetState.pressed, false);
              _updateLift();
            },
            child: AnimatedContainer(
              duration: tokens.motion.dHover,
              curve: tokens.motion.easingEnter,
              transform: Matrix4.translationValues(0, -_currentLift, 0),
              decoration: BoxDecoration(
                borderRadius: tokens.radius.br3,
                boxShadow: _resolveShadow(tokens),
              ),
              foregroundDecoration: BoxDecoration(
                border: Border.all(
                  color: spec.borderColor,
                  width: spec.borderWidth,
                ),
                borderRadius: tokens.radius.br3,
              ),
              child: content,
            ),
          ),
        ),
      ),
    );

    return Semantics(
      button: true,
      enabled: true,
      label: '${widget.title}. ${widget.description}',
      child: interactiveAlert,
    );
  }
}
