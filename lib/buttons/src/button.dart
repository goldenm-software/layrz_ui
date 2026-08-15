import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:layrz_icons/layrz_icons.dart';

import '../../constants/constants.dart';
import '../../extensions/extensions.dart';
import '../../tokens/tokens.dart';
import 'button_content.dart';
import 'button_indicator.dart';
import 'button_style.dart';
import 'button_style_spec.dart';
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

  /// A listenable that drives the cooldown overlay.
  ///
  /// When `true`, an indeterminate progress bar (in `fg3` tint) renders.
  /// Like [isLoading], ownership is external and null means no cooldown.
  /// Cooldown carries no duration information — there is no countdown text.
  final ValueListenable<bool>? isCooldown;

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
  /// When non-null and [tooltipEnabled] is `true`, hovering over or long-pressing
  /// the button shows this tooltip. Fab buttons always show [labelText] as tooltip.
  final String? hintText;

  /// Whether tooltips are enabled.
  ///
  /// When `false`, no tooltip is rendered even if [hintText] is provided.
  /// Fab buttons ignore this flag and always render the tooltip.
  final bool tooltipEnabled;

  /// Creates a new [LayrzButton] with the given properties.
  ///
  /// The button accent color is determined by [type]:
  /// - For [LayrzButtonType.custom], uses the explicit [color] parameter (or primary if null)
  /// - For any other type, resolves to the corresponding semantic token color
  ///
  /// The [color] parameter is only used when [type] is [LayrzButtonType.custom];
  /// passing a color with any other type triggers an assertion error.
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
    this.tooltipEnabled = true,
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
    ValueListenable<bool>? isCooldown,
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
      tooltipEnabled: !isFab,
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
    ValueListenable<bool>? isCooldown,
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
      tooltipEnabled: !isFab,
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
    ValueListenable<bool>? isCooldown,
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
      tooltipEnabled: !isFab,
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
    ValueListenable<bool>? isCooldown,
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
      tooltipEnabled: !isFab,
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
    ValueListenable<bool>? isCooldown,
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
      tooltipEnabled: !isFab,
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
    ValueListenable<bool>? isCooldown,
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
      tooltipEnabled: !isFab,
      hintText: isFab ? null : labelText,
    );
  }

  @override
  State<LayrzButton> createState() => _LayrzButtonState();
}

class _LayrzButtonState extends State<LayrzButton> {
  late WidgetStatesController _statesController;

  @override
  void initState() {
    super.initState();
    _statesController = WidgetStatesController();
    _subscribe();
  }

  @override
  void didUpdateWidget(LayrzButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Resubscribe if loading/cooldown listenables changed identity.
    if (oldWidget.isLoading != widget.isLoading || oldWidget.isCooldown != widget.isCooldown) {
      _unsubscribe();
      _subscribe();
    }
  }

  @override
  void dispose() {
    _unsubscribe();
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
    setState(() {});
  }

  /// Whether the button is disabled for interaction purposes.
  ///
  /// This includes actual disable states (onTap == null, isDisabled)
  /// and transient busy states (isLoading, isCooldown).
  /// Used to suppress taps, set cursor, and control semantics.enabled.
  bool get _effectivelyDisabled =>
      widget.onTap == null ||
      widget.isDisabled ||
      (widget.isLoading?.value ?? false) ||
      (widget.isCooldown?.value ?? false);

  /// Whether the button is disabled for visual/styling purposes.
  ///
  /// This excludes transient busy states (loading, cooldown).
  /// Loading and cooldown buttons retain their normal style and only show
  /// an indicator overlay; they do not render the disabled (greyed) spec.
  /// Used to drive [WidgetState.disabled] in the style resolver.
  bool get _visuallyDisabled => widget.onTap == null || widget.isDisabled;

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
    if (_visuallyDisabled && !states.contains(WidgetState.disabled)) {
      _statesController.update(WidgetState.disabled, true);
    } else if (!_visuallyDisabled && states.contains(WidgetState.disabled)) {
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
    final isCooldown = widget.isCooldown?.value ?? false;

    final buttonContent = LayoutBuilder(
      builder: (context, constraints) {
        final buttonWidth = _computeButtonWidth(context, tokens, constraints);

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
                    if (isLoading || isCooldown)
                      Positioned.fill(
                        child: LayrzButtonIndicator(
                          trackColor: spec.contentColor.withOpacityValue(0.2),
                          indicatorColor: spec.contentColor,
                          borderRadius: tokens.radius.base,
                          height: kLayrzButtonHeight,
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

    final wrappedContent = _shouldShowTooltip()
        ? RawTooltip(
            semanticsTooltip: widget.labelText,
            tooltipBuilder: (context, animation) {
              return FadeTransition(
                opacity: animation,
                child: _buildTooltip(context, tokens),
              );
            },
            hoverDelay: Duration.zero,
            triggerMode: TooltipTriggerMode.longPress,
            child: buttonContent,
          )
        : buttonContent;

    return Semantics(
      button: true,
      label: widget.labelText,
      enabled: !_effectivelyDisabled,
      excludeSemantics: true,
      child: wrappedContent,
    );
  }

  /// Returns the exact [TextStyle] used to render the button label.
  ///
  /// This style is used by both [_measureLabelWidth] and [buildButtonContent]
  /// to ensure consistency between measurement and rendering.
  TextStyle _labelStyle(LayrzTokens tokens) {
    return tokens.typography.labelLarge.copyWith(
      fontSize: kLayrzButtonFontSize,
    );
  }

  /// Measures the width of the label text using TextPainter.
  ///
  /// Returns the width in logical pixels, accounting for the given [style],
  /// [fontSize], and the current context's text scaling.
  double _measureLabelWidth(BuildContext context, LayrzTokens tokens) {
    final painter = TextPainter(
      text: TextSpan(
        text: widget.labelText,
        style: _labelStyle(tokens),
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    return painter.width;
  }

  /// Computes the button width based on content and constraints.
  ///
  /// For Fab buttons: returns [kLayrzButtonHeight] (square).
  ///
  /// For non-Fab buttons: measures the label width and adds:
  /// - Horizontal padding (left + right)
  /// - Icon size + separator (if icon is present)
  /// - Border widths
  ///
  /// The result is clamped to available constraints. When constraints are
  /// unbounded, the full computed width is used. When bounded, it is clamped
  /// to [maxWidth]. This allows callers to constrain the button via parent
  /// (e.g. `SizedBox(width: 120)`) while still using intrinsic sizing by default.
  double _computeButtonWidth(
    BuildContext context,
    LayrzTokens tokens,
    BoxConstraints constraints,
  ) {
    final isFab = widget.style.isFab;

    // Fab is always square.
    if (isFab) return kLayrzButtonHeight;

    // Compute width from content: padding + icon (if any) + label + border.
    double computed = 0;

    // Horizontal padding
    computed += kLayrzButtonHorizontalPadding * 2;

    // Icon and separator.
    if (widget.icon != null) {
      computed += kLayrzButtonIconSize + kLayrzButtonIconSeparator;
    }

    // Measured label width.
    computed += _measureLabelWidth(context, tokens);

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
    // tooltipEnabled is a hard gate for all variants.
    if (!widget.tooltipEnabled) return false;

    // Fab shows tooltip using labelText.
    if (widget.style.isFab) return true;

    // Non-Fab shows tooltip only if hintText is provided.
    return widget.hintText != null;
  }

  Widget _buildTooltip(BuildContext context, LayrzTokens tokens) {
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
        widget.style.isFab ? widget.labelText : (widget.hintText ?? ''),
        style: tokens.typography.labelSmall.copyWith(
          color: tokens.colors.background,
        ),
      ),
    );
  }
}
