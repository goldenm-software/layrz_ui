import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:layrz_icons/layrz_icons.dart';

import 'package:layrz_ui/constants/constants.dart';
import 'package:layrz_ui/extensions/extensions.dart';
import 'package:layrz_ui/tokens/tokens.dart';

import 'button_content.dart' show buildButtonContent, buildFabContent, buildButtonContentSpan;
import 'button_indicator.dart';
import 'button_style.dart';
import 'button_style_spec.dart';
import 'button_tooltip_position.dart';
import 'button_type.dart';

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

  /// If `true`, the button is disabled regardless of [onTap] and [isLoading].
  final bool isDisabled;

  /// A listenable that drives the loading indicator overlay.
  ///
  /// When `true`, an indeterminate progress bar renders over the button content.
  /// Ownership is external; [LayrzButton] reads but does not own the listenable.
  /// Null means no loading state.
  final ValueListenable<bool>? isLoading;

  /// A listenable that drives the cooldown overlay with automatic countdown.
  ///
  /// **Semantics:**
  /// - `null` → not in cooldown. Button behaves normally.
  /// - non-null `Duration` → cooldown begins. An internal countdown runs over that
  ///   Duration, showing determinate progress + remaining whole seconds. Button is disabled.
  /// - **When countdown reaches zero but value is still non-null** → button switches to
  ///   indeterminate busy mode (like [isLoading]), still disabled, no numeral shown.
  ///   It does **NOT** re-enable. Only the integrating developer clearing the value to
  ///   `null` ends cooldown.
  ///
  /// Ownership is external; the button listens but never clears the value itself.
  /// Null means no cooldown.
  ///
  /// **IMPORTANT GOTCHA:** `Duration` has value equality, so assigning the same
  /// Duration object twice will not trigger notification and will not restart the
  /// countdown. To re-trigger an identical cooldown, set `null` first, then set the
  /// new Duration.
  final ValueListenable<Duration?>? isCooldown;

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
    this.isLoading,
    this.isCooldown,
    this.type = LayrzButtonType.custom,
    this.color,
    this.style = LayrzButtonStyle.filledTonal,
    this.hintText,
  }) : assert(
         type == LayrzButtonType.custom || color == null,
         'color is only applied when type is LayrzButtonType.custom.',
       );

  /// Creates a save button with success accent and optional Fab layout.
  ///
  /// When [isFab] is `false`, renders as [filledTonal]; when `true`, as [filledTonalFab].
  /// This is a layout choice that applies on any platform — not a platform check.
  ///
  /// Sizing is standardised and not configurable.
  factory LayrzButton.save({
    required String labelText,
    required VoidCallback onTap,
    bool isFab = false,
    bool isDisabled = false,
    ValueListenable<bool>? isLoading,
    ValueListenable<Duration?>? isCooldown,
    Key? key,
  }) {
    return LayrzButton(
      key: key,
      labelText: labelText,
      icon: LayrzIcons.solarOutlineInboxIn,
      onTap: isDisabled ? null : onTap,
      isDisabled: isDisabled,
      isLoading: isLoading,
      isCooldown: isCooldown,
      type: LayrzButtonType.success,
      style: isFab ? LayrzButtonStyle.filledTonalFab : LayrzButtonStyle.filledTonal,
      hintText: isFab ? null : labelText,
    );
  }

  /// Creates a cancel button with danger accent and optional Fab layout.
  ///
  /// When [isFab] is `false`, renders as [outlined]; when `true`, as [outlinedFab].
  /// This is a layout choice that applies on any platform — not a platform check.
  ///
  /// Sizing is standardised and not configurable.
  factory LayrzButton.cancel({
    required String labelText,
    required VoidCallback onTap,
    bool isFab = false,
    bool isDisabled = false,
    ValueListenable<bool>? isLoading,
    ValueListenable<Duration?>? isCooldown,
    Key? key,
  }) {
    return LayrzButton(
      key: key,
      labelText: labelText,
      icon: LayrzIcons.solarOutlineCloseSquare,
      onTap: isDisabled ? null : onTap,
      isDisabled: isDisabled,
      isLoading: isLoading,
      isCooldown: isCooldown,
      type: LayrzButtonType.danger,
      style: isFab ? LayrzButtonStyle.outlinedFab : LayrzButtonStyle.outlined,
      hintText: isFab ? null : labelText,
    );
  }

  /// Creates an info button with info accent and optional Fab layout.
  ///
  /// When [isFab] is `false`, renders as [filledTonal]; when `true`, as [filledTonalFab].
  /// This is a layout choice that applies on any platform — not a platform check.
  ///
  /// Sizing is standardised and not configurable.
  factory LayrzButton.info({
    required String labelText,
    required VoidCallback onTap,
    bool isFab = false,
    bool isDisabled = false,
    ValueListenable<bool>? isLoading,
    ValueListenable<Duration?>? isCooldown,
    Key? key,
  }) {
    return LayrzButton(
      key: key,
      labelText: labelText,
      icon: LayrzIcons.solarOutlineInfoSquare,
      onTap: isDisabled ? null : onTap,
      isDisabled: isDisabled,
      isLoading: isLoading,
      isCooldown: isCooldown,
      type: LayrzButtonType.info,
      style: isFab ? LayrzButtonStyle.filledTonalFab : LayrzButtonStyle.filledTonal,
      hintText: isFab ? null : labelText,
    );
  }

  /// Creates a show button with info accent and optional Fab layout.
  ///
  /// When [isFab] is `false`, renders as [filledTonal]; when `true`, as [filledTonalFab].
  /// This is a layout choice that applies on any platform — not a platform check.
  ///
  /// Sizing is standardised and not configurable.
  factory LayrzButton.show({
    required String labelText,
    required VoidCallback onTap,
    bool isFab = false,
    bool isDisabled = false,
    ValueListenable<bool>? isLoading,
    ValueListenable<Duration?>? isCooldown,
    Key? key,
  }) {
    return LayrzButton(
      key: key,
      labelText: labelText,
      icon: LayrzIcons.solarOutlineEyeScan,
      onTap: isDisabled ? null : onTap,
      isDisabled: isDisabled,
      isLoading: isLoading,
      isCooldown: isCooldown,
      type: LayrzButtonType.info,
      style: isFab ? LayrzButtonStyle.filledTonalFab : LayrzButtonStyle.filledTonal,
      hintText: isFab ? null : labelText,
    );
  }

  /// Creates an edit button with warning accent and optional Fab layout.
  ///
  /// When [isFab] is `false`, renders as [filledTonal]; when `true`, as [filledTonalFab].
  /// This is a layout choice that applies on any platform — not a platform check.
  ///
  /// Sizing is standardised and not configurable.
  factory LayrzButton.edit({
    required String labelText,
    required VoidCallback onTap,
    bool isFab = false,
    bool isDisabled = false,
    ValueListenable<bool>? isLoading,
    ValueListenable<Duration?>? isCooldown,
    Key? key,
  }) {
    return LayrzButton(
      key: key,
      labelText: labelText,
      icon: LayrzIcons.solarOutlinePenNewSquare,
      onTap: isDisabled ? null : onTap,
      isDisabled: isDisabled,
      isLoading: isLoading,
      isCooldown: isCooldown,
      type: LayrzButtonType.warning,
      style: isFab ? LayrzButtonStyle.filledTonalFab : LayrzButtonStyle.filledTonal,
      hintText: isFab ? null : labelText,
    );
  }

  /// Creates a delete button with danger accent and optional Fab layout.
  ///
  /// When [isFab] is `false`, renders as [filledTonal]; when `true`, as [filledTonalFab].
  /// This is a layout choice that applies on any platform — not a platform check.
  ///
  /// Sizing is standardised and not configurable.
  factory LayrzButton.delete({
    required String labelText,
    required VoidCallback onTap,
    bool isFab = false,
    bool isDisabled = false,
    ValueListenable<bool>? isLoading,
    ValueListenable<Duration?>? isCooldown,
    Key? key,
  }) {
    return LayrzButton(
      key: key,
      labelText: labelText,
      icon: LayrzIcons.solarOutlineTrashBinMinimalisticN2,
      onTap: isDisabled ? null : onTap,
      isDisabled: isDisabled,
      isLoading: isLoading,
      isCooldown: isCooldown,
      type: LayrzButtonType.danger,
      style: isFab ? LayrzButtonStyle.filledTonalFab : LayrzButtonStyle.filledTonal,
      hintText: isFab ? null : labelText,
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
    _cooldownController = AnimationController(vsync: this);
    _subscribe();
    _updateCooldownTimer();
  }

  @override
  void didUpdateWidget(LayrzButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Resubscribe if loading/cooldown listenables changed identity.
    if (oldWidget.isLoading != widget.isLoading || oldWidget.isCooldown != widget.isCooldown) {
      _unsubscribe();
      _subscribe();
    }

    // Handle cooldown value changes (same notifier, new value).
    final oldCooldownValue = oldWidget.isCooldown?.value;
    final newCooldownValue = widget.isCooldown?.value;
    if (oldCooldownValue != newCooldownValue) {
      _updateCooldownTimer();
    }
  }

  @override
  void dispose() {
    _unsubscribe();
    _cooldownController.dispose();
    _statesController.dispose();
    super.dispose();
  }

  void _subscribe() {
    widget.isLoading?.addListener(_onLoadingChanged);
    widget.isCooldown?.addListener(_onCooldownChanged);
  }

  void _unsubscribe() {
    widget.isLoading?.removeListener(_onLoadingChanged);
    widget.isCooldown?.removeListener(_onCooldownChanged);
  }

  void _onLoadingChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _onCooldownChanged() {
    if (!mounted) return;
    _updateCooldownTimer();
    setState(() {});
  }

  /// Updates the cooldown timer based on the current cooldown value.
  ///
  /// - If cooldown is null: stops the animation
  /// - If cooldown is a Duration: starts a countdown animation over that duration
  /// - On animation completion: leaves animation at 1.0 to trigger indeterminate mode
  void _updateCooldownTimer() {
    final cooldownDuration = widget.isCooldown?.value;

    _cooldownController.stop();

    if (cooldownDuration == null) {
      // No cooldown; reset controller.
      _cooldownController.reset();
    } else {
      // Start countdown over the given duration.
      _cooldownController.duration = cooldownDuration;
      _cooldownController.forward(from: 0.0);
    }
  }

  /// Whether the button is disabled for interaction, visual, and semantic purposes.
  ///
  /// This includes actual disable states (onTap == null, isDisabled)
  /// and transient busy states (isLoading, isCooldown).
  /// Used to suppress taps, set cursor, control semantics.enabled, and render
  /// the disabled visual style (greyed appearance).
  bool get _effectivelyDisabled =>
      widget.onTap == null ||
      widget.isDisabled ||
      (widget.isLoading?.value ?? false) ||
      (widget.isCooldown?.value != null);

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

    final isLoading = widget.isLoading?.value ?? false;
    final isCooldownValue = widget.isCooldown?.value;
    final hasCooldown = isCooldownValue != null;

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
                      Positioned.fill(
                        child: AnimatedBuilder(
                          animation: _cooldownController,
                          builder: (context, _) {
                            // During countdown: show determinate progress.
                            // After countdown (when controller.value >= 1.0): show indeterminate.
                            final cooldownProgress = hasCooldown ? _cooldownController.value : null;
                            final isDeterminateMode = cooldownProgress != null && cooldownProgress < 1.0;

                            // Calculate remaining seconds for determinate mode.
                            int? remainingSeconds;
                            if (isDeterminateMode && isCooldownValue != null) {
                              final totalSeconds = isCooldownValue.inSeconds;
                              final elapsedSeconds = (totalSeconds * cooldownProgress).toInt();
                              remainingSeconds = totalSeconds - elapsedSeconds;
                            }

                            return LayrzButtonIndicator(
                              trackColor: spec.contentColor.withOpacityValue(0.2),
                              indicatorColor: spec.contentColor,
                              borderRadius: tokens.radius.base,
                              height: kLayrzButtonHeight,
                              progress: isDeterminateMode ? cooldownProgress : null,
                              remainingSeconds: remainingSeconds,
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
