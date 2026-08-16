import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:layrz_icons/layrz_icons.dart';

import 'package:layrz_ui/constants.dart';
import 'package:layrz_ui/extensions.dart';
import 'package:layrz_ui/tokens.dart';

import 'button_content.dart' show buildButtonContent, buildFabContent, buildButtonContentSpan;
import 'button_controller.dart';
import 'button_indicator.dart';
import 'button_style.dart';
import 'button_style_spec.dart';
import 'button_tooltip_position.dart';
import 'button_type.dart';

/// Resolves the appropriate button style for semantic factories based on elevation context.
///
/// This helper encapsulates the style resolution logic used by the semantic factories
/// (`.save`, `.info`, `.show`, `.edit`) to determine whether to use the elevated or filled
/// variant based on the [isElevated] flag and the [isFab] layout.
///
/// Parameters:
/// - [isFab]: whether the button should use a Fab (square, icon-only) layout
/// - [isElevated]: whether the button sits on a plain surface (true) or inside an elevated container (false)
/// - [baseStyle]: the regular-layout style to use when [isElevated] is true
/// - [baseFabStyle]: the Fab-layout style to use when [isElevated] is true
///
/// Returns the appropriate [LayrzButtonStyle], swapping the base styles for their filled
/// counterparts when [isElevated] is false.
LayrzButtonStyle _resolveSemanticStyle({
  required bool isFab,
  required bool isElevated,
  required LayrzButtonStyle baseStyle,
  required LayrzButtonStyle baseFabStyle,
}) {
  if (!isElevated) {
    // When not elevated, swap elevated styles for filled styles.
    if (baseStyle == LayrzButtonStyle.elevated) {
      return isFab ? LayrzButtonStyle.filledFab : LayrzButtonStyle.filled;
    }
  }

  // When elevated or for other styles, use the base styles as provided.
  return isFab ? baseFabStyle : baseStyle;
}

/// A Material-free button widget in the layrz_ui design system.
///
/// [LayrzButton] supports six visual styles (filled, elevated, filledTonal, outlined,
/// outlinedTonal, and their Fab equivalents), optional loading/cooldown indicators,
/// and semantic factories for common actions.
///
/// The button respects disabled state through both [onTap] == null and the [isDisabled]
/// flag. Geometry (height, padding, border width) is fixed across interaction states
/// per decision D15 — only color, shadow, and opacity change on hover/press.
class LayrzButton extends StatefulWidget {
  /// The text displayed on the button.
  final String labelText;

  /// Optional icon displayed before the label (non-Fab only).
  final IconData? icon;

  /// Called when the button is tapped. `null` disables the button.
  final VoidCallback? onTap;

  /// If `true`, the button is disabled regardless of [onTap] and [controller].
  final bool isDisabled;

  /// An optional controller that drives the busy state (loading or cooldown).
  ///
  /// When non-null, the controller manages all busy-state rendering and interaction:
  /// - Loading indicator from [LayrzButtonController.isLoading]
  /// - Cooldown countdown from [LayrzButtonController.cooldownTotal]
  ///
  /// Multiple buttons can share a single controller instance, enabling lockstep busy-state
  /// management across a form or action group. All buttons subscribed to the same controller
  /// move in perfect sync, preventing frame-by-frame drift.
  ///
  /// When null, the button has no loading or cooldown states and behaves normally.
  ///
  /// The button attaches and detaches listeners dynamically. If the controller is swapped
  /// via `didUpdateWidget`, the old listener is detached and the new one attached.
  /// Disposal is caller-owned. If a button's controller is disposed before the button unmounts,
  /// the button remains functional and will not throw or `setState` after unmount.
  final LayrzButtonController? controller;

  /// The semantic type of the button — determines which token color to use.
  ///
  /// When [type] is [LayrzButtonType.custom], the [color] parameter is honoured.
  /// For any other type, [color] must be null (enforced by assertion).
  final LayrzButtonType type;

  /// The accent color for the button.
  ///
  /// Only applied when [type] is [LayrzButtonType.custom].
  /// Defaults to primary brand color if both [type] is custom and [color] is null.
  /// Must be null for any other [type].
  final Color? color;

  /// The visual style of the button.
  final LayrzButtonStyle style;

  /// Text for a tooltip hint (non-Fab variants only).
  ///
  /// When non-null, hovering over or long-pressing the button shows a tooltip
  /// containing this hint text. Fab buttons always show a tooltip composed of
  /// [labelText] and optionally [hintText] if both are present.
  /// For non-Fab buttons, this field alone determines whether a tooltip is shown.
  final String? hintText;

  /// Creates a new [LayrzButton] with the given properties.
  ///
  /// The button accent color is determined by [type]:
  /// - For [LayrzButtonType.custom], uses the explicit [color] parameter (or primary if null)
  /// - For any other type, resolves to the corresponding semantic token color
  ///
  /// The [color] parameter is only used when [type] is [LayrzButtonType.custom];
  /// passing a color with any other type triggers an assertion error.
  ///
  /// Tooltip behavior is determined by [style] and [hintText]:
  /// - **Fab buttons** always show a tooltip (labelText, or labelText + hintText if hint is provided)
  /// - **Non-Fab buttons** show a tooltip only when [hintText] is non-null
  ///
  /// Button sizing is fixed and not caller-configurable: height, width, icon size,
  /// and spacing all use design system constants. Buttons can be constrained by their
  /// parent (e.g. `SizedBox(width: 120)`) and will clamp to that constraint,
  /// but the intrinsic sizing is standardised.
  ///
  /// Use the semantic factories (`.save()`, `.cancel()`, etc.) for convenience.
  const LayrzButton({
    super.key,
    required this.labelText,
    this.icon,
    this.onTap,
    this.isDisabled = false,
    this.controller,
    this.type = LayrzButtonType.custom,
    this.color,
    this.style = LayrzButtonStyle.elevated,
    this.hintText,
  }) : assert(
         type == LayrzButtonType.custom || color == null,
         'color is only applied when type is LayrzButtonType.custom.',
       );

  /// Creates a save button with success accent and optional Fab layout.
  ///
  /// When [isFab] is `false` and [isElevated] is `true` (default), renders as [elevated];
  /// when [isFab] is `false` and [isElevated] is `false`, renders as [filled].
  /// When [isFab] is `true`, the [isElevated] parameter selects between [elevatedFab]
  /// (default, for buttons on a plain surface) and [filledFab] (for buttons inside elevated containers).
  ///
  /// The [isElevated] parameter indicates whether the button sits on a plain surface (true)
  /// or is inside an elevated container like a card (false). Defaults to `true`.
  ///
  /// Sizing is standardised and not configurable.
  ///
  /// The [hintText] parameter is optional and applies only to Fab buttons, where it
  /// is displayed alongside the labelText in the tooltip. For non-Fab buttons, the
  /// label is already visible, so hintText is not shown unless explicitly provided.
  factory LayrzButton.save({
    required String labelText,
    required VoidCallback onTap,
    bool isFab = false,
    bool isElevated = true,
    bool isDisabled = false,
    LayrzButtonController? controller,
    String? hintText,
    Key? key,
  }) {
    final style = _resolveSemanticStyle(
      isFab: isFab,
      isElevated: isElevated,
      baseStyle: isElevated ? LayrzButtonStyle.elevated : LayrzButtonStyle.filled,
      baseFabStyle: isElevated ? LayrzButtonStyle.elevatedFab : LayrzButtonStyle.filledFab,
    );

    return LayrzButton(
      key: key,
      labelText: labelText,
      icon: LayrzIcons.solarOutlineInboxIn,
      onTap: isDisabled ? null : onTap,
      isDisabled: isDisabled,
      controller: controller,
      type: LayrzButtonType.success,
      style: style,
      hintText: hintText,
    );
  }

  /// Creates a cancel button with danger accent and optional Fab layout.
  ///
  /// When [isFab] is `false` and [isElevated] is `false` (default), renders as [filled];
  /// when [isFab] is `false` and [isElevated] is `true`, renders as [elevated].
  /// When [isFab] is `true`, the [isElevated] parameter selects between [filledFab]
  /// (default, for buttons inside elevated containers) and [elevatedFab] (for buttons on a plain surface).
  ///
  /// **Unlike other semantic factories, `.cancel()` defaults to `isElevated: false`.** This reflects
  /// the design intent: cancel/destructive actions are visually quiet by default (solid fill, no shadow),
  /// and developers explicitly opt into shadow depth with `isElevated: true`. This inversion prevents
  /// accidentally over-emphasizing destructive actions.
  ///
  /// The [isElevated] parameter indicates whether the button sits on a plain surface (true)
  /// or is inside an elevated container like a card (false). Defaults to `false` for this factory only.
  ///
  /// Sizing is standardised and not configurable.
  ///
  /// The [hintText] parameter is optional and applies only to Fab buttons, where it
  /// is displayed alongside the labelText in the tooltip. For non-Fab buttons, the
  /// label is already visible, so hintText is not shown unless explicitly provided.
  factory LayrzButton.cancel({
    required String labelText,
    required VoidCallback onTap,
    bool isFab = false,
    bool isElevated = false,
    bool isDisabled = false,
    LayrzButtonController? controller,
    String? hintText,
    Key? key,
  }) {
    final style = _resolveSemanticStyle(
      isFab: isFab,
      isElevated: isElevated,
      baseStyle: isElevated ? LayrzButtonStyle.elevated : LayrzButtonStyle.filled,
      baseFabStyle: isElevated ? LayrzButtonStyle.elevatedFab : LayrzButtonStyle.filledFab,
    );

    return LayrzButton(
      key: key,
      labelText: labelText,
      icon: LayrzIcons.solarOutlineCloseSquare,
      onTap: isDisabled ? null : onTap,
      isDisabled: isDisabled,
      controller: controller,
      type: LayrzButtonType.danger,
      style: style,
      hintText: hintText,
    );
  }

  /// Creates an info button with info accent and optional Fab layout.
  ///
  /// When [isFab] is `false` and [isElevated] is `true` (default), renders as [elevated];
  /// when [isFab] is `false` and [isElevated] is `false`, renders as [filled].
  /// When [isFab] is `true`, the [isElevated] parameter selects between [elevatedFab]
  /// (default, for buttons on a plain surface) and [filledFab] (for buttons inside elevated containers).
  ///
  /// The [isElevated] parameter indicates whether the button sits on a plain surface (true)
  /// or is inside an elevated container like a card (false). Defaults to `true`.
  ///
  /// Sizing is standardised and not configurable.
  ///
  /// The [hintText] parameter is optional and applies only to Fab buttons, where it
  /// is displayed alongside the labelText in the tooltip. For non-Fab buttons, the
  /// label is already visible, so hintText is not shown unless explicitly provided.
  factory LayrzButton.info({
    required String labelText,
    required VoidCallback onTap,
    bool isFab = false,
    bool isElevated = true,
    bool isDisabled = false,
    LayrzButtonController? controller,
    String? hintText,
    Key? key,
  }) {
    final style = _resolveSemanticStyle(
      isFab: isFab,
      isElevated: isElevated,
      baseStyle: isElevated ? LayrzButtonStyle.elevated : LayrzButtonStyle.filled,
      baseFabStyle: isElevated ? LayrzButtonStyle.elevatedFab : LayrzButtonStyle.filledFab,
    );

    return LayrzButton(
      key: key,
      labelText: labelText,
      icon: LayrzIcons.solarOutlineInfoSquare,
      onTap: isDisabled ? null : onTap,
      isDisabled: isDisabled,
      controller: controller,
      type: LayrzButtonType.info,
      style: style,
      hintText: hintText,
    );
  }

  /// Creates a show button with info accent and optional Fab layout.
  ///
  /// When [isFab] is `false` and [isElevated] is `true` (default), renders as [elevated];
  /// when [isFab] is `false` and [isElevated] is `false`, renders as [filled].
  /// When [isFab] is `true`, the [isElevated] parameter selects between [elevatedFab]
  /// (default, for buttons on a plain surface) and [filledFab] (for buttons inside elevated containers).
  ///
  /// The [isElevated] parameter indicates whether the button sits on a plain surface (true)
  /// or is inside an elevated container like a card (false). Defaults to `true`.
  ///
  /// Sizing is standardised and not configurable.
  ///
  /// The [hintText] parameter is optional and applies only to Fab buttons, where it
  /// is displayed alongside the labelText in the tooltip. For non-Fab buttons, the
  /// label is already visible, so hintText is not shown unless explicitly provided.
  factory LayrzButton.show({
    required String labelText,
    required VoidCallback onTap,
    bool isFab = false,
    bool isElevated = true,
    bool isDisabled = false,
    LayrzButtonController? controller,
    String? hintText,
    Key? key,
  }) {
    final style = _resolveSemanticStyle(
      isFab: isFab,
      isElevated: isElevated,
      baseStyle: isElevated ? LayrzButtonStyle.elevated : LayrzButtonStyle.filled,
      baseFabStyle: isElevated ? LayrzButtonStyle.elevatedFab : LayrzButtonStyle.filledFab,
    );

    return LayrzButton(
      key: key,
      labelText: labelText,
      icon: LayrzIcons.solarOutlineEyeScan,
      onTap: isDisabled ? null : onTap,
      isDisabled: isDisabled,
      controller: controller,
      type: LayrzButtonType.info,
      style: style,
      hintText: hintText,
    );
  }

  /// Creates an edit button with warning accent and optional Fab layout.
  ///
  /// When [isFab] is `false` and [isElevated] is `true` (default), renders as [elevated];
  /// when [isFab] is `false` and [isElevated] is `false`, renders as [filled].
  /// When [isFab] is `true`, the [isElevated] parameter selects between [elevatedFab]
  /// (default, for buttons on a plain surface) and [filledFab] (for buttons inside elevated containers).
  ///
  /// The [isElevated] parameter indicates whether the button sits on a plain surface (true)
  /// or is inside an elevated container like a card (false). Defaults to `true`.
  ///
  /// Sizing is standardised and not configurable.
  ///
  /// The [hintText] parameter is optional and applies only to Fab buttons, where it
  /// is displayed alongside the labelText in the tooltip. For non-Fab buttons, the
  /// label is already visible, so hintText is not shown unless explicitly provided.
  factory LayrzButton.edit({
    required String labelText,
    required VoidCallback onTap,
    bool isFab = false,
    bool isElevated = true,
    bool isDisabled = false,
    LayrzButtonController? controller,
    String? hintText,
    Key? key,
  }) {
    final style = _resolveSemanticStyle(
      isFab: isFab,
      isElevated: isElevated,
      baseStyle: isElevated ? LayrzButtonStyle.elevated : LayrzButtonStyle.filled,
      baseFabStyle: isElevated ? LayrzButtonStyle.elevatedFab : LayrzButtonStyle.filledFab,
    );

    return LayrzButton(
      key: key,
      labelText: labelText,
      icon: LayrzIcons.solarOutlinePenNewSquare,
      onTap: isDisabled ? null : onTap,
      isDisabled: isDisabled,
      controller: controller,
      type: LayrzButtonType.warning,
      style: style,
      hintText: hintText,
    );
  }

  /// Creates a delete button with danger accent and optional Fab layout.
  ///
  /// When [isFab] is `false` and [isElevated] is `false` (default), renders as [filled];
  /// when [isFab] is `false` and [isElevated] is `true`, renders as [elevated].
  /// When [isFab] is `true`, the [isElevated] parameter selects between [filledFab]
  /// (default, for buttons inside elevated containers) and [elevatedFab] (for buttons on a plain surface).
  ///
  /// **Unlike other semantic factories, `.delete()` defaults to `isElevated: false`.** This reflects
  /// the design intent: delete actions are visually quiet by default (solid fill, no shadow),
  /// and developers explicitly opt into shadow depth with `isElevated: true`. This inversion prevents
  /// accidentally over-emphasizing destructive actions.
  ///
  /// The [isElevated] parameter indicates whether the button sits on a plain surface (true)
  /// or is inside an elevated container like a card (false). Defaults to `false` for this factory only.
  ///
  /// Sizing is standardised and not configurable.
  ///
  /// The [hintText] parameter is optional and applies only to Fab buttons, where it
  /// is displayed alongside the labelText in the tooltip. For non-Fab buttons, the
  /// label is already visible, so hintText is not shown unless explicitly provided.
  factory LayrzButton.delete({
    required String labelText,
    required VoidCallback onTap,
    bool isFab = false,
    bool isElevated = false,
    bool isDisabled = false,
    LayrzButtonController? controller,
    String? hintText,
    Key? key,
  }) {
    final style = _resolveSemanticStyle(
      isFab: isFab,
      isElevated: isElevated,
      baseStyle: isElevated ? LayrzButtonStyle.elevated : LayrzButtonStyle.filled,
      baseFabStyle: isElevated ? LayrzButtonStyle.elevatedFab : LayrzButtonStyle.filledFab,
    );

    return LayrzButton(
      key: key,
      labelText: labelText,
      icon: LayrzIcons.solarOutlineTrashBinMinimalisticN2,
      onTap: isDisabled ? null : onTap,
      isDisabled: isDisabled,
      controller: controller,
      type: LayrzButtonType.danger,
      style: style,
      hintText: hintText,
    );
  }

  @override
  State<LayrzButton> createState() => _LayrzButtonState();
}

class _LayrzButtonState extends State<LayrzButton> with TickerProviderStateMixin {
  late WidgetStatesController _statesController;
  late AnimationController _cooldownController;

  @override
  void initState() {
    super.initState();
    _statesController = WidgetStatesController();
    _statesController.addListener(_onStatesChanged);
    _cooldownController = AnimationController(vsync: this);
    _subscribe();
  }

  @override
  void didUpdateWidget(LayrzButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Resubscribe if controller changed identity.
    if (oldWidget.controller != widget.controller) {
      _unsubscribe();
      _subscribe();
    }
  }

  @override
  void dispose() {
    _statesController.removeListener(_onStatesChanged);
    _unsubscribe();
    _cooldownController.dispose();
    _statesController.dispose();
    super.dispose();
  }

  void _subscribe() {
    widget.controller?.addListener(_onControllerChanged);
  }

  void _unsubscribe() {
    widget.controller?.removeListener(_onControllerChanged);
  }

  void _onStatesChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _onControllerChanged() {
    if (!mounted) return;
    setState(() {});
  }

  /// Whether the button is disabled for interaction, visual, and semantic purposes.
  ///
  /// This includes actual disable states (onTap == null, isDisabled)
  /// and transient busy states (controller reports isBusy).
  /// Used to suppress taps, set cursor, control semantics.enabled, and render
  /// the disabled visual style (greyed appearance).
  bool get _effectivelyDisabled => widget.onTap == null || widget.isDisabled || (widget.controller?.isBusy ?? false);

  /// Resolves the accent color from the button's type and optional color override.
  Color _resolveAccent(LayrzTokens tokens) {
    switch (widget.type) {
      case LayrzButtonType.success:
        return tokens.colors.success;
      case LayrzButtonType.info:
        return tokens.colors.info;
      case LayrzButtonType.context:
        return tokens.colors.contextual;
      case LayrzButtonType.danger:
        return tokens.colors.danger;
      case LayrzButtonType.warning:
        return tokens.colors.warning;
      case LayrzButtonType.custom:
        return widget.color ?? tokens.colors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final accent = _resolveAccent(tokens);

    final states = _statesController.value;
    if (_effectivelyDisabled && !states.contains(WidgetState.disabled)) {
      _statesController.update(WidgetState.disabled, true);
    } else if (!_effectivelyDisabled && states.contains(WidgetState.disabled)) {
      _statesController.update(WidgetState.disabled, false);
    }

    final spec = LayrzButtonStyleSpec.resolve(
      style: widget.style,
      states: states,
      tokens: tokens,
      accent: accent,
    );

    final isFab = widget.style.isFab;

    final controller = widget.controller;
    final isLoading = controller?.isLoading ?? false;
    final hasCooldown = controller?.cooldownTotal != null;

    final buttonContent = LayoutBuilder(
      builder: (context, constraints) {
        final buttonWidth = _computeButtonWidth(context, tokens, constraints, spec);

        return FocusableActionDetector(
          onShowHoverHighlight: (show) {
            _statesController.update(WidgetState.hovered, show);
          },
          onShowFocusHighlight: (show) {
            _statesController.update(WidgetState.focused, show);
          },
          child: MouseRegion(
            cursor: _effectivelyDisabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
            child: GestureDetector(
              onTap: _effectivelyDisabled ? null : widget.onTap,
              onTapDown: (_) {
                _statesController.update(WidgetState.pressed, true);
              },
              onTapUp: (_) {
                _statesController.update(WidgetState.pressed, false);
              },
              onTapCancel: () {
                _statesController.update(WidgetState.pressed, false);
              },
              child: AnimatedContainer(
                duration: tokens.motion.dHover,
                curve: tokens.motion.easing,
                width: buttonWidth,
                height: kLayrzButtonHeight,
                decoration: BoxDecoration(
                  color: spec.backgroundColor,
                  border: Border.all(
                    color: spec.borderColor,
                    width: spec.borderWidth,
                  ),
                  borderRadius: BorderRadius.circular(tokens.radius.base),
                  boxShadow: spec.shadows,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Content layer (icon + label or Fab icon).
                    if (!isFab)
                      buildButtonContent(
                        labelText: widget.labelText,
                        icon: widget.icon,
                        spec: spec,
                        tokens: tokens,
                      )
                    else
                      buildFabContent(
                        icon: widget.icon,
                        spec: spec,
                      ),

                    // Indicator overlay (loading or cooldown).
                    if (isLoading || hasCooldown)
                      Positioned(
                        left: spec.borderWidth + kLayrzButtonIndicatorInsetHorizontal,
                        right: spec.borderWidth + kLayrzButtonIndicatorInsetHorizontal,
                        bottom: spec.borderWidth + kLayrzButtonIndicatorInsetBottom,
                        height: kLayrzButtonIndicatorHeight,
                        child: ValueListenableBuilder<double>(
                          valueListenable: _CooldownProgressListenable(controller),
                          builder: (context, _, _) {
                            final cooldownProgress = controller?.cooldownProgress ?? 0.0;
                            final isDeterminateMode = hasCooldown && cooldownProgress < 1.0;

                            return LayrzButtonIndicator(
                              trackColor: const Color(0x00000000),
                              indicatorColor: spec.contentColor,
                              borderRadius: kLayrzButtonIndicatorHeight / 2,
                              height: kLayrzButtonIndicatorHeight,
                              progress: isDeterminateMode ? cooldownProgress : null,
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    final tooltipMessage = _composeTooltipMessage();
    final wrappedContent = _shouldShowTooltip()
        ? RawTooltip(
            semanticsTooltip: tooltipMessage,
            tooltipBuilder: (context, animation) {
              return FadeTransition(
                opacity: animation,
                child: _buildTooltip(context, tokens, tooltipMessage),
              );
            },
            hoverDelay: Duration.zero,
            triggerMode: TooltipTriggerMode.longPress,
            positionDelegate: layrzButtonTooltipPosition,
            child: buttonContent,
          )
        : buttonContent;

    return Semantics(
      button: true,
      label: widget.labelText,
      hint: widget.hintText,
      enabled: !_effectivelyDisabled,
      excludeSemantics: true,
      child: wrappedContent,
    );
  }

  /// Measures the width of the button content using the shared span.
  ///
  /// This uses the exact same span that [buildButtonContent] renders, ensuring
  /// consistent width calculation without hand-summing icon, separator, and label widths.
  /// Returns the width in logical pixels, accounting for text scaling.
  double _measureButtonContentWidth(BuildContext context, LayrzTokens tokens, LayrzButtonStyleSpec spec) {
    final span = buildButtonContentSpan(
      labelText: widget.labelText,
      icon: widget.icon,
      spec: spec,
      tokens: tokens,
    );

    final painter = TextPainter(
      text: span,
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    );

    // If the span contains a WidgetSpan (for icon), notify TextPainter of placeholder dimensions.
    if (widget.icon != null) {
      painter.setPlaceholderDimensions(
        const [
          PlaceholderDimensions(
            size: Size(kLayrzButtonIconSize + kLayrzButtonIconSeparator, kLayrzButtonIconSize),
            alignment: PlaceholderAlignment.middle,
          ),
        ],
      );
    }

    painter.layout();
    return painter.width;
  }

  /// Computes the button width based on content and constraints.
  ///
  /// For Fab buttons: returns [kLayrzButtonHeight] (square).
  ///
  /// For non-Fab buttons:
  /// - Measures the shared content span (icon + label) directly via TextPainter
  /// - Adds horizontal padding (left + right) and border widths
  /// - Clamps to constraints
  ///
  /// Using the shared span eliminates hand-summing of component widths and ensures
  /// measurement matches rendering exactly.
  ///
  /// The result is clamped to available constraints. When constraints are
  /// unbounded, the full computed width is used. When bounded, it is clamped
  /// to [maxWidth]. This allows callers to constrain the button via parent
  /// (e.g. `SizedBox(width: 120)`) while still using intrinsic sizing by default.
  double _computeButtonWidth(
    BuildContext context,
    LayrzTokens tokens,
    BoxConstraints constraints,
    LayrzButtonStyleSpec spec,
  ) {
    final isFab = widget.style.isFab;

    // Fab is always square.
    if (isFab) return kLayrzButtonHeight;

    // Measure content span (icon + label together) — single source of truth.
    final contentWidth = _measureButtonContentWidth(context, tokens, spec);

    // Horizontal padding
    double computed = contentWidth + (kLayrzButtonHorizontalPadding * 2);

    // Border width — all buttons have a Border.all() applied, regardless of color.
    // The border always insets the child, so we must account for it in width computation.
    computed += tokens.border.base * 2;

    // Clamp to constraints. If maxWidth is infinite (unbounded context like Row/Wrap),
    // use the full computed width. Otherwise, clamp to the available width.
    if (constraints.maxWidth.isFinite) {
      computed = computed.clamp(0, constraints.maxWidth);
    }

    return computed;
  }

  bool _shouldShowTooltip() {
    // Fab always shows a tooltip.
    if (widget.style.isFab) return true;

    // Non-Fab shows tooltip only if hintText is provided.
    return widget.hintText != null;
  }

  /// Composes the tooltip message content based on button style and text fields.
  ///
  /// For Fab buttons: returns [labelText], optionally followed by a newline and
  /// [hintText] if [hintText] is provided.
  ///
  /// For non-Fab buttons: returns [hintText] only (the label is already visible
  /// on the button itself, so repeating it would be redundant).
  String _composeTooltipMessage() {
    final isFab = widget.style.isFab;

    if (isFab) {
      if (widget.hintText != null) {
        return '${widget.labelText}\n${widget.hintText}';
      }
      return widget.labelText;
    }

    return widget.hintText ?? '';
  }

  /// Builds the tooltip widget with the given [message].
  ///
  /// The tooltip displays text in the foreground color (fg1) with a contrasting
  /// background, rendered in the small label style from the design system.
  Widget _buildTooltip(BuildContext context, LayrzTokens tokens, String message) {
    const tooltipPadding = 12.0;
    const tooltipRadius = 8.0;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: tooltipPadding,
        vertical: tooltipPadding / 2,
      ),
      decoration: BoxDecoration(
        color: tokens.colors.fg1,
        borderRadius: BorderRadius.circular(tooltipRadius),
      ),
      child: Text(
        message,
        style: tokens.typography.labelSmall.copyWith(
          color: tokens.colors.background,
        ),
      ),
    );
  }
}

/// A ValueListenable that exposes the cooldown progress from a controller.
///
/// This allows high-frequency progress updates (every ~16ms) without rebuilding
/// the entire button subtree. Only the progress indicator repaints.
class _CooldownProgressListenable implements ValueListenable<double> {
  /// The button controller that owns the cooldown state.
  final LayrzButtonController? controller;

  /// Creates a new [_CooldownProgressListenable].
  _CooldownProgressListenable(this.controller);

  @override
  double get value => controller?.cooldownProgress ?? 0.0;

  @override
  void addListener(VoidCallback listener) {
    controller?.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    controller?.removeListener(listener);
  }

  void dispose() {
    // No-op; the controller is owned by the application.
  }
}
