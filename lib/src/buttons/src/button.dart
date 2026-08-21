import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:layrz_ui/src/constants/constants.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/tokens/tokens.dart';
import 'package:layrz_ui/src/tooltips/tooltips.dart';

import 'button_content.dart' show buildButtonContent, buildFabContent, buildButtonContentSpan;
import 'button_controller.dart';
import 'button_indicator.dart';
import 'button_style.dart';
import 'button_style_spec.dart';
import 'button_type.dart';

/// A Material-free button widget in the layrz_ui design system.
///
/// [LayrzButton] supports three visual styles (elevated, outlined, outlinedTonal),
/// each with a Fab (floating action button) variant, optional loading/cooldown indicators,
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
  /// The [style] parameter determines the button's visual appearance:
  /// - [LayrzButtonStyle.elevated] (default): solid fill with shadow
  /// - [LayrzButtonStyle.outlined]: border only, no fill
  /// - [LayrzButtonStyle.outlinedTonal]: border with subtle tonal fill
  ///
  /// The [isFab] parameter switches the button to icon-only square mode. When `true`,
  /// the non-Fab [style] is automatically mapped to its Fab variant.
  /// An assertion will fail if [style] is already a Fab variant.
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
    LayrzButtonStyle style = LayrzButtonStyle.elevated,
    bool isDisabled = false,
    LayrzButtonController? controller,
    String? hintText,
    Key? key,
  }) {
    assert(
      !style.isFab,
      'Pass a non-Fab style and use isFab: true to switch to icon mode.',
    );

    return LayrzButton(
      key: key,
      labelText: labelText,
      icon: MdiIcons.contentSaveOutline,
      onTap: isDisabled ? null : onTap,
      isDisabled: isDisabled,
      controller: controller,
      type: LayrzButtonType.success,
      style: isFab ? style.asFab : style,
      hintText: hintText,
    );
  }

  /// Creates a cancel button with danger accent and optional Fab layout.
  ///
  /// The [style] parameter determines the button's visual appearance:
  /// - [LayrzButtonStyle.elevated] (default): solid fill with shadow
  /// - [LayrzButtonStyle.outlined]: border only, no fill
  /// - [LayrzButtonStyle.outlinedTonal]: border with subtle tonal fill
  ///
  /// The [isFab] parameter switches the button to icon-only square mode. When `true`,
  /// the non-Fab [style] is automatically mapped to its Fab variant.
  /// An assertion will fail if [style] is already a Fab variant.
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
    LayrzButtonStyle style = LayrzButtonStyle.elevated,
    bool isDisabled = false,
    LayrzButtonController? controller,
    String? hintText,
    Key? key,
  }) {
    assert(
      !style.isFab,
      'Pass a non-Fab style and use isFab: true to switch to icon mode.',
    );

    return LayrzButton(
      key: key,
      labelText: labelText,
      icon: MdiIcons.closeCircleOutline,
      onTap: isDisabled ? null : onTap,
      isDisabled: isDisabled,
      controller: controller,
      type: LayrzButtonType.danger,
      style: isFab ? style.asFab : style,
      hintText: hintText,
    );
  }

  /// Creates an info button with info accent and optional Fab layout.
  ///
  /// The [style] parameter determines the button's visual appearance:
  /// - [LayrzButtonStyle.elevated] (default): solid fill with shadow
  /// - [LayrzButtonStyle.outlined]: border only, no fill
  /// - [LayrzButtonStyle.outlinedTonal]: border with subtle tonal fill
  ///
  /// The [isFab] parameter switches the button to icon-only square mode. When `true`,
  /// the non-Fab [style] is automatically mapped to its Fab variant.
  /// An assertion will fail if [style] is already a Fab variant.
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
    LayrzButtonStyle style = LayrzButtonStyle.elevated,
    bool isDisabled = false,
    LayrzButtonController? controller,
    String? hintText,
    Key? key,
  }) {
    assert(
      !style.isFab,
      'Pass a non-Fab style and use isFab: true to switch to icon mode.',
    );

    return LayrzButton(
      key: key,
      labelText: labelText,
      icon: MdiIcons.informationOutline,
      onTap: isDisabled ? null : onTap,
      isDisabled: isDisabled,
      controller: controller,
      type: LayrzButtonType.info,
      style: isFab ? style.asFab : style,
      hintText: hintText,
    );
  }

  /// Creates a show button with info accent and optional Fab layout.
  ///
  /// The [style] parameter determines the button's visual appearance:
  /// - [LayrzButtonStyle.elevated] (default): solid fill with shadow
  /// - [LayrzButtonStyle.outlined]: border only, no fill
  /// - [LayrzButtonStyle.outlinedTonal]: border with subtle tonal fill
  ///
  /// The [isFab] parameter switches the button to icon-only square mode. When `true`,
  /// the non-Fab [style] is automatically mapped to its Fab variant.
  /// An assertion will fail if [style] is already a Fab variant.
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
    LayrzButtonStyle style = LayrzButtonStyle.elevated,
    bool isDisabled = false,
    LayrzButtonController? controller,
    String? hintText,
    Key? key,
  }) {
    assert(
      !style.isFab,
      'Pass a non-Fab style and use isFab: true to switch to icon mode.',
    );

    return LayrzButton(
      key: key,
      labelText: labelText,
      icon: MdiIcons.eyeOutline,
      onTap: isDisabled ? null : onTap,
      isDisabled: isDisabled,
      controller: controller,
      type: LayrzButtonType.info,
      style: isFab ? style.asFab : style,
      hintText: hintText,
    );
  }

  /// Creates an edit button with warning accent and optional Fab layout.
  ///
  /// The [style] parameter determines the button's visual appearance:
  /// - [LayrzButtonStyle.elevated] (default): solid fill with shadow
  /// - [LayrzButtonStyle.outlined]: border only, no fill
  /// - [LayrzButtonStyle.outlinedTonal]: border with subtle tonal fill
  ///
  /// The [isFab] parameter switches the button to icon-only square mode. When `true`,
  /// the non-Fab [style] is automatically mapped to its Fab variant.
  /// An assertion will fail if [style] is already a Fab variant.
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
    LayrzButtonStyle style = LayrzButtonStyle.elevated,
    bool isDisabled = false,
    LayrzButtonController? controller,
    String? hintText,
    Key? key,
  }) {
    assert(
      !style.isFab,
      'Pass a non-Fab style and use isFab: true to switch to icon mode.',
    );

    return LayrzButton(
      key: key,
      labelText: labelText,
      icon: MdiIcons.pencilOutline,
      onTap: isDisabled ? null : onTap,
      isDisabled: isDisabled,
      controller: controller,
      type: LayrzButtonType.warning,
      style: isFab ? style.asFab : style,
      hintText: hintText,
    );
  }

  /// Creates a delete button with danger accent and optional Fab layout.
  ///
  /// The [style] parameter determines the button's visual appearance:
  /// - [LayrzButtonStyle.elevated] (default): solid fill with shadow
  /// - [LayrzButtonStyle.outlined]: border only, no fill
  /// - [LayrzButtonStyle.outlinedTonal]: border with subtle tonal fill
  ///
  /// The [isFab] parameter switches the button to icon-only square mode. When `true`,
  /// the non-Fab [style] is automatically mapped to its Fab variant.
  /// An assertion will fail if [style] is already a Fab variant.
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
    LayrzButtonStyle style = LayrzButtonStyle.elevated,
    bool isDisabled = false,
    LayrzButtonController? controller,
    String? hintText,
    Key? key,
  }) {
    assert(
      !style.isFab,
      'Pass a non-Fab style and use isFab: true to switch to icon mode.',
    );

    return LayrzButton(
      key: key,
      labelText: labelText,
      icon: MdiIcons.trashCanOutline,
      onTap: isDisabled ? null : onTap,
      isDisabled: isDisabled,
      controller: controller,
      type: LayrzButtonType.danger,
      style: isFab ? style.asFab : style,
      hintText: hintText,
    );
  }

  @override
  State<LayrzButton> createState() => _LayrzButtonState();
}

class _LayrzButtonState extends State<LayrzButton> with TickerProviderStateMixin {
  late WidgetStatesController _statesController;
  late AnimationController _cooldownController;

  /// Timestamp when the button was pressed via pointer-down.
  ///
  /// Used to enforce the minimum pressed-visible window [kLayrzButtonMinPressedDuration].
  /// Set when [onPointerDown] fires, cleared when pressed state is finally released.
  DateTime? _pressStartTime;

  /// Pending Timer that will clear the pressed state after the minimum window expires.
  ///
  /// When pointer-up or pointer-cancel fires before [kLayrzButtonMinPressedDuration] has elapsed,
  /// this timer is scheduled to clear the pressed state at the remainder time.
  /// If a new press arrives while this timer is pending, it is canceled and a new press cycle begins.
  /// The timer is always canceled in [dispose] to prevent callbacks after unmount.
  Timer? _releasePressedTimer;

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
    _releasePressedTimer?.cancel();
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

  /// Handles pointer-down to set the pressed state immediately.
  ///
  /// This is called directly by [Listener.onPointerDown], bypassing the gesture
  /// arena entirely. The pressed state is set only if the button is not effectively
  /// disabled.
  ///
  /// Records [_pressStartTime] to track whether the minimum pressed-visible window
  /// [kLayrzButtonMinPressedDuration] has elapsed when the pointer is released.
  void _onPointerDown(PointerDownEvent event) {
    if (_effectivelyDisabled) return;

    _pressStartTime = DateTime.now();
    _statesController.update(WidgetState.pressed, true);
  }

  /// Handles pointer-up and pointer-cancel to release the pressed state.
  ///
  /// If [kLayrzButtonMinPressedDuration] has not yet elapsed since [_onPointerDown],
  /// schedules a Timer to clear the pressed state after the remainder expires.
  /// Otherwise clears the pressed state immediately.
  ///
  /// If a pending release timer is already active (a new press arrived while one was
  /// pending), cancels the old timer before starting a fresh press cycle.
  void _releasePressedWithMinimumWindow() {
    if (!mounted) return;

    final now = DateTime.now();
    final startTime = _pressStartTime;

    if (startTime == null) return;

    final elapsed = now.difference(startTime);

    if (elapsed < kLayrzButtonMinPressedDuration) {
      // Elapsed time is less than minimum; schedule the release.
      _releasePressedTimer?.cancel();
      final remaining = kLayrzButtonMinPressedDuration - elapsed;
      _releasePressedTimer = Timer(remaining, () {
        if (!mounted) return;
        _statesController.update(WidgetState.pressed, false);
        _releasePressedTimer = null;
        _pressStartTime = null;
      });
    } else {
      // Minimum window has elapsed; clear immediately.
      _releasePressedTimer?.cancel();
      _releasePressedTimer = null;
      _statesController.update(WidgetState.pressed, false);
      _pressStartTime = null;
    }
  }

  /// Resolves the button's height, font size, and icon size based on viewport compactness.
  ///
  /// Returns a record containing:
  /// - height: 50 on compact viewports, 45 on regular viewports
  /// - fontSize: 16 on compact viewports, 14 on regular viewports
  /// - iconSize: 24 on compact viewports, 22 on regular viewports
  ///
  /// This keeps the three values coordinated and ensures they scale together
  /// as the button adapts to mobile vs desktop viewports.
  ({double height, double fontSize, double iconSize}) _resolveDimensions(BuildContext context) {
    if (context.isCompact) {
      return (
        height: kLayrzButtonCompactHeight,
        fontSize: kLayrzButtonCompactFontSize,
        iconSize: kLayrzButtonCompactIconSize,
      );
    }
    return (
      height: kLayrzButtonHeight,
      fontSize: kLayrzButtonFontSize,
      iconSize: kLayrzButtonIconSize,
    );
  }

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
    final dimensions = _resolveDimensions(context);

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
        final buttonWidth = _computeButtonWidth(
          context,
          tokens,
          constraints,
          spec,
          dimensions.fontSize,
          dimensions.iconSize,
        );

        return FocusableActionDetector(
          onShowHoverHighlight: (show) {
            _statesController.update(WidgetState.hovered, show);
          },
          onShowFocusHighlight: (show) {
            _statesController.update(WidgetState.focused, show);
          },
          child: MouseRegion(
            cursor: _effectivelyDisabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
            child: Listener(
              onPointerDown: (event) {
                _onPointerDown(event);
              },
              onPointerUp: (event) {
                _releasePressedWithMinimumWindow();
              },
              onPointerCancel: (event) {
                _releasePressedWithMinimumWindow();
              },
              child: GestureDetector(
                onTap: _effectivelyDisabled ? null : widget.onTap,
                onTapCancel: () {
                  _releasePressedWithMinimumWindow();
                },
                child: AnimatedContainer(
                  duration: tokens.motion.dHover,
                  curve: tokens.motion.easing,
                  width: buttonWidth,
                  height: dimensions.height,
                  decoration: BoxDecoration(
                    color: spec.backgroundColor,
                    border: Border.all(
                      color: spec.borderColor,
                      width: spec.borderWidth,
                    ),
                    borderRadius: BorderRadius.circular(tokens.radius.r2),
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
                          textScaler: MediaQuery.textScalerOf(context),
                          buttonFontSize: dimensions.fontSize,
                          buttonIconSize: dimensions.iconSize,
                        )
                      else
                        buildFabContent(
                          icon: widget.icon,
                          spec: spec,
                          buttonIconSize: dimensions.iconSize,
                        ),

                      // Indicator overlay (loading or cooldown).
                      if (isLoading || hasCooldown)
                        Positioned(
                          left: spec.borderWidth + tokens.spacing.sp2,
                          right: spec.borderWidth + tokens.spacing.sp2,
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
          ),
        );
      },
    );

    final tooltipMessage = _composeTooltipMessage();
    final wrappedContent = _shouldShowTooltip()
        ? LayrzTooltip(
            contentText: tooltipMessage,
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
  ///
  /// **Parameters**:
  /// - [buttonFontSize]: The resolved font size for consistent TextPainter measurement.
  /// - [buttonIconSize]: The resolved icon size for consistent placeholder dimensions.
  double _measureButtonContentWidth(
    BuildContext context,
    LayrzTokens tokens,
    LayrzButtonStyleSpec spec,
    double buttonFontSize,
    double buttonIconSize,
  ) {
    final span = buildButtonContentSpan(
      labelText: widget.labelText,
      icon: widget.icon,
      spec: spec,
      tokens: tokens,
      buttonFontSize: buttonFontSize,
      buttonIconSize: buttonIconSize,
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
        [
          PlaceholderDimensions(
            size: Size(buttonIconSize + tokens.spacing.sp2, buttonIconSize),
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
  /// For Fab buttons: returns the button height (square).
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
  ///
  /// **Parameters**:
  /// - [buttonFontSize]: The resolved font size for proper TextPainter measurement.
  /// - [buttonIconSize]: The resolved icon size for proper placeholder dimensions.
  /// - [buttonHeight]: The resolved button height for Fab sizing.
  double _computeButtonWidth(
    BuildContext context,
    LayrzTokens tokens,
    BoxConstraints constraints,
    LayrzButtonStyleSpec spec,
    double buttonFontSize,
    double buttonIconSize,
  ) {
    final isFab = widget.style.isFab;
    final dimensions = _resolveDimensions(context);

    // Fab is always square.
    if (isFab) return dimensions.height;

    // Measure content span (icon + label together) — single source of truth.
    final contentWidth = _measureButtonContentWidth(
      context,
      tokens,
      spec,
      buttonFontSize,
      buttonIconSize,
    );

    // Horizontal padding
    double computed = contentWidth + (tokens.spacing.sp3 * 2);

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
