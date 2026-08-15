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

/// Semantic button marker enum for internal style resolution.
enum _LayrzButtonSemantic { save, cancel, info, show, edit, delete }

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

  /// The accent color for the button. Defaults to primary brand color if not set.
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

  /// The height of the button in logical pixels.
  ///
  /// Non-Fab buttons use this as their height; Fab buttons use it as their width
  /// and height (square).
  final double height;

  /// The width of the button in logical pixels.
  ///
  /// When `null`, the button shrink-wraps to its content. Fab buttons ignore this.
  final double? width;

  /// The size of the icon in logical pixels.
  final double iconSize;

  /// The spacing between icon and label when both are present.
  final double iconSeparatorSize;

  /// The font size of the label text.
  final double fontSize;

  /// Internal semantic marker (null for public constructor, set by factories).
  final _LayrzButtonSemantic? _semantic;

  /// Creates a new [LayrzButton] with the given properties.
  ///
  /// The button accent color defaults to [LayrzTokens.colors.primary].
  /// Use the semantic factories (`.save()`, `.cancel()`, etc.) for semantic colors.
  const LayrzButton({
    super.key,
    required this.labelText,
    this.icon,
    this.onTap,
    this.isDisabled = false,
    this.isLoading,
    this.isCooldown,
    this.color,
    this.style = LayrzButtonStyle.filledTonal,
    this.hintText,
    this.tooltipEnabled = true,
    this.height = kLayrzButtonHeight,
    this.width,
    this.iconSize = kLayrzButtonIconSize,
    this.iconSeparatorSize = kLayrzButtonIconSeparator,
    this.fontSize = kLayrzButtonFontSize,
  }) : _semantic = null;

  /// Internal constructor for semantic factories.
  // ignore_for_file: prefer_initializing_formals
  const LayrzButton._semantic({
    super.key,
    required this.labelText,
    this.icon,
    this.onTap,
    this.isDisabled = false,
    this.isLoading,
    this.isCooldown,
    this.style = LayrzButtonStyle.filledTonal,
    this.hintText,
    this.tooltipEnabled = true,
    required _LayrzButtonSemantic semantic,
  }) : _semantic = semantic,
       color = null,
       height = kLayrzButtonHeight,
       width = null,
       iconSize = kLayrzButtonIconSize,
       iconSeparatorSize = kLayrzButtonIconSeparator,
       fontSize = kLayrzButtonFontSize;

  /// Creates a save button with success accent and optional Fab layout.
  ///
  /// When [isMobile] is `false`, renders as [filledTonal]; when `true`, as [filledTonalFab].
  factory LayrzButton.save({
    required String labelText,
    required VoidCallback onTap,
    bool isMobile = false,
    bool isDisabled = false,
    ValueListenable<bool>? isLoading,
    ValueListenable<bool>? isCooldown,
    Key? key,
  }) {
    return LayrzButton._semantic(
      key: key,
      labelText: labelText,
      icon: LayrzIcons.solarOutlineInboxIn,
      onTap: isDisabled ? null : onTap,
      isDisabled: isDisabled,
      isLoading: isLoading,
      isCooldown: isCooldown,
      style: isMobile ? LayrzButtonStyle.filledTonalFab : LayrzButtonStyle.filledTonal,
      tooltipEnabled: !isMobile,
      hintText: isMobile ? null : labelText,
      semantic: _LayrzButtonSemantic.save,
    );
  }

  /// Creates a cancel button with danger accent and optional Fab layout.
  ///
  /// When [isMobile] is `false`, renders as [outlined]; when `true`, as [outlinedFab].
  factory LayrzButton.cancel({
    required String labelText,
    required VoidCallback onTap,
    bool isMobile = false,
    bool isDisabled = false,
    ValueListenable<bool>? isLoading,
    ValueListenable<bool>? isCooldown,
    Key? key,
  }) {
    return LayrzButton._semantic(
      key: key,
      labelText: labelText,
      icon: LayrzIcons.solarOutlineCloseSquare,
      onTap: isDisabled ? null : onTap,
      isDisabled: isDisabled,
      isLoading: isLoading,
      isCooldown: isCooldown,
      style: isMobile ? LayrzButtonStyle.outlinedFab : LayrzButtonStyle.outlined,
      tooltipEnabled: !isMobile,
      hintText: isMobile ? null : labelText,
      semantic: _LayrzButtonSemantic.cancel,
    );
  }

  /// Creates an info button with info accent and optional Fab layout.
  ///
  /// When [isMobile] is `false`, renders as [filledTonal]; when `true`, as [filledTonalFab].
  factory LayrzButton.info({
    required String labelText,
    required VoidCallback onTap,
    bool isMobile = false,
    bool isDisabled = false,
    ValueListenable<bool>? isLoading,
    ValueListenable<bool>? isCooldown,
    Key? key,
  }) {
    return LayrzButton._semantic(
      key: key,
      labelText: labelText,
      icon: LayrzIcons.solarOutlineInfoSquare,
      onTap: isDisabled ? null : onTap,
      isDisabled: isDisabled,
      isLoading: isLoading,
      isCooldown: isCooldown,
      style: isMobile ? LayrzButtonStyle.filledTonalFab : LayrzButtonStyle.filledTonal,
      tooltipEnabled: !isMobile,
      hintText: isMobile ? null : labelText,
      semantic: _LayrzButtonSemantic.info,
    );
  }

  /// Creates a show button with info accent and optional Fab layout.
  ///
  /// When [isMobile] is `false`, renders as [filledTonal]; when `true`, as [filledTonalFab].
  factory LayrzButton.show({
    required String labelText,
    required VoidCallback onTap,
    bool isMobile = false,
    bool isDisabled = false,
    ValueListenable<bool>? isLoading,
    ValueListenable<bool>? isCooldown,
    Key? key,
  }) {
    return LayrzButton._semantic(
      key: key,
      labelText: labelText,
      icon: LayrzIcons.solarOutlineEyeScan,
      onTap: isDisabled ? null : onTap,
      isDisabled: isDisabled,
      isLoading: isLoading,
      isCooldown: isCooldown,
      style: isMobile ? LayrzButtonStyle.filledTonalFab : LayrzButtonStyle.filledTonal,
      tooltipEnabled: !isMobile,
      hintText: isMobile ? null : labelText,
      semantic: _LayrzButtonSemantic.show,
    );
  }

  /// Creates an edit button with warning accent and optional Fab layout.
  ///
  /// When [isMobile] is `false`, renders as [filledTonal]; when `true`, as [filledTonalFab].
  factory LayrzButton.edit({
    required String labelText,
    required VoidCallback onTap,
    bool isMobile = false,
    bool isDisabled = false,
    ValueListenable<bool>? isLoading,
    ValueListenable<bool>? isCooldown,
    Key? key,
  }) {
    return LayrzButton._semantic(
      key: key,
      labelText: labelText,
      icon: LayrzIcons.solarOutlinePenNewSquare,
      onTap: isDisabled ? null : onTap,
      isDisabled: isDisabled,
      isLoading: isLoading,
      isCooldown: isCooldown,
      style: isMobile ? LayrzButtonStyle.filledTonalFab : LayrzButtonStyle.filledTonal,
      tooltipEnabled: !isMobile,
      hintText: isMobile ? null : labelText,
      semantic: _LayrzButtonSemantic.edit,
    );
  }

  /// Creates a delete button with danger accent and optional Fab layout.
  ///
  /// When [isMobile] is `false`, renders as [filledTonal]; when `true`, as [filledTonalFab].
  factory LayrzButton.delete({
    required String labelText,
    required VoidCallback onTap,
    bool isMobile = false,
    bool isDisabled = false,
    ValueListenable<bool>? isLoading,
    ValueListenable<bool>? isCooldown,
    Key? key,
  }) {
    return LayrzButton._semantic(
      key: key,
      labelText: labelText,
      icon: LayrzIcons.solarOutlineTrashBinMinimalisticN2,
      onTap: isDisabled ? null : onTap,
      isDisabled: isDisabled,
      isLoading: isLoading,
      isCooldown: isCooldown,
      style: isMobile ? LayrzButtonStyle.filledTonalFab : LayrzButtonStyle.filledTonal,
      tooltipEnabled: !isMobile,
      hintText: isMobile ? null : labelText,
      semantic: _LayrzButtonSemantic.delete,
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

  bool get _effectivelyDisabled =>
      widget.onTap == null ||
      widget.isDisabled ||
      (widget.isLoading?.value ?? false) ||
      (widget.isCooldown?.value ?? false);

  /// Resolves the accent color from explicit color parameter or semantic marker.
  Color _resolveAccent(LayrzTokens tokens) {
    // Explicit color always wins.
    if (widget.color != null) return widget.color!;

    // Resolve based on semantic marker (set by factories, null for public constructor).
    switch (widget._semantic) {
      case _LayrzButtonSemantic.save:
        return tokens.colors.success;
      case _LayrzButtonSemantic.cancel:
      case _LayrzButtonSemantic.delete:
        return tokens.colors.danger;
      case _LayrzButtonSemantic.info:
      case _LayrzButtonSemantic.show:
        return tokens.colors.info;
      case _LayrzButtonSemantic.edit:
        return tokens.colors.warning;
      case null:
        return tokens.colors.primary;
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
    final buttonHeight = isFab ? widget.height : widget.height;
    final buttonWidth = isFab ? widget.height : (widget.width ?? double.infinity);

    final isLoading = widget.isLoading?.value ?? false;
    final isCooldown = widget.isCooldown?.value ?? false;

    final buttonContent = FocusableActionDetector(
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
            height: buttonHeight,
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
                    iconSize: widget.iconSize,
                    iconSeparatorSize: widget.iconSeparatorSize,
                    fontSize: widget.fontSize,
                    spec: spec,
                    tokens: tokens,
                  )
                else
                  buildFabContent(
                    icon: widget.icon,
                    iconSize: widget.iconSize,
                    spec: spec,
                  ),

                // Indicator overlay (loading or cooldown).
                if (isLoading || isCooldown)
                  Positioned.fill(
                    child: LayrzButtonIndicator(
                      trackColor: (isLoading ? spec.contentColor : tokens.colors.fg3).withOpacityValue(0.2),
                      indicatorColor: isLoading ? spec.contentColor : tokens.colors.fg3,
                      borderRadius: tokens.radius.base,
                      height: buttonHeight,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
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
