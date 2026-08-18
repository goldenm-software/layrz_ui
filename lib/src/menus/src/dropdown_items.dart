import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/constants/src/menu.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/tokens/tokens.dart';

import 'dropdown_entry_style_spec.dart';

/// Base class for items that a [LayrzDropdownMenu] can render.
///
/// Only three concrete types are allowed: [LayrzDropdownEntry], [LayrzDropdownDivider],
/// and [LayrzDropdownLabel]. Custom widget types is impossible by construction thanks
/// to the sealed class guarantee. This ensures standardization on rendering.
sealed class LayrzDropdownItem extends StatelessWidget {
  /// Creates a new [LayrzDropdownItem].
  const LayrzDropdownItem({super.key});

  /// Whether this item can receive focus and be activated via keyboard or mouse.
  ///
  /// - [LayrzDropdownEntry]: true if enabled
  /// - [LayrzDropdownDivider]: false (non-focusable visual separator)
  /// - [LayrzDropdownLabel]: false (non-focusable section heading)
  bool get isFocusable;
}

/// A visual separator line in a dropdown menu.
///
/// [LayrzDropdownDivider] renders a thin horizontal hairline stroke in the
/// menu's divider color, inset horizontally, with vertical margin for spacing.
/// It is non-focusable and non-interactive.
final class LayrzDropdownDivider extends LayrzDropdownItem {
  /// Creates a new [LayrzDropdownDivider].
  const LayrzDropdownDivider({super.key});

  @override
  bool get isFocusable => false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: tokens.spacing.sp4),
      child: Container(
        height: 1.0,
        color: tokens.colors.divider,
        margin: EdgeInsets.symmetric(horizontal: tokens.spacing.sp8),
      ),
    );
  }
}

/// A non-interactive section heading in a dropdown menu.
///
/// [LayrzDropdownLabel] renders plain-text labels at the [LayrzTokens.typography.label]
/// style in the subdued foreground color ([fg3]). It is non-focusable and non-interactive.
/// Casing is determined by the caller — the widget does not uppercase or transform text.
final class LayrzDropdownLabel extends LayrzDropdownItem {
  /// The text displayed as the label.
  final String labelText;

  /// Creates a new [LayrzDropdownLabel].
  ///
  /// The [labelText] parameter is required and contains the section heading text.
  /// Text styling and case transformation are the caller's responsibility.
  const LayrzDropdownLabel({
    required this.labelText,
    super.key,
  });

  @override
  bool get isFocusable => false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Semantics(
      header: true,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: tokens.spacing.sp12,
          vertical: tokens.spacing.sp8,
        ),
        child: Text(
          labelText,
          style: tokens.typography.label.copyWith(
            color: tokens.colors.fg3,
          ),
        ),
      ),
    );
  }
}

/// An interactive entry in a dropdown menu.
///
/// [LayrzDropdownEntry] renders a selectable row with a label, optional icon, and
/// optional color override (for destructive actions). Interaction states (hovered,
/// pressed, focused) only change color, background, and icon color — geometry is fixed
/// per decision D15.
///
/// When tapped, [onTap] is called exactly once, and the menu automatically closes.
/// When [enabled] is false, the entry is visually and interactively disabled.
final class LayrzDropdownEntry extends LayrzDropdownItem {
  /// The text displayed on the entry.
  final String labelText;

  /// Called when the entry is tapped.
  ///
  /// Must be non-null. The dropdown menu closes automatically after this callback
  /// is invoked, so there is no need to manage menu state in the callback.
  final VoidCallback onTap;

  /// Optional icon displayed before the label.
  final IconData? icon;

  /// Whether this entry is interactive and accepts input.
  ///
  /// When false, the entry is visually greyed and does not respond to taps,
  /// focus, or keyboard input. Defaults to true.
  final bool enabled;

  /// Optional accent color swatch override for the entry.
  ///
  /// When null, uses the tokens.colors.primary swatch. When non-null, replaces
  /// the accent color — useful for destructive entries that pass tokens.colors.danger.
  final LayrzColorSwatch? color;

  /// Creates a new [LayrzDropdownEntry].
  ///
  /// The [labelText], [onTap], and [key] parameters are required.
  /// [icon], [enabled], and [color] are optional.
  const LayrzDropdownEntry({
    required this.labelText,
    required this.onTap,
    this.icon,
    this.enabled = true,
    this.color,
    super.key,
  });

  @override
  bool get isFocusable => enabled;

  @override
  Widget build(BuildContext context) => _LayrzDropdownEntryWidget(
    labelText: labelText,
    onTap: onTap,
    icon: icon,
    enabled: enabled,
    color: color,
  );
}

/// Internal stateful widget for [LayrzDropdownEntry].
class _LayrzDropdownEntryWidget extends StatefulWidget {
  /// The text displayed on the entry.
  final String labelText;

  /// Called when the entry is tapped.
  final VoidCallback onTap;

  /// Optional icon displayed before the label.
  final IconData? icon;

  /// Whether this entry is interactive.
  final bool enabled;

  /// Optional accent color swatch override for the entry.
  final LayrzColorSwatch? color;

  /// Creates a new [_LayrzDropdownEntryWidget].
  const _LayrzDropdownEntryWidget({
    required this.labelText,
    required this.onTap,
    this.icon,
    required this.enabled,
    this.color,
  });

  @override
  State<_LayrzDropdownEntryWidget> createState() => _LayrzDropdownEntryState();
}

class _LayrzDropdownEntryState extends State<_LayrzDropdownEntryWidget> {
  late WidgetStatesController _statesController;

  @override
  void initState() {
    super.initState();
    _statesController = WidgetStatesController();
  }

  @override
  void dispose() {
    _statesController.dispose();
    super.dispose();
  }

  void _onTap() {
    if (!widget.enabled) return;
    widget.onTap();

    // Close the menu after the entry is tapped
    // Use the SDK's MenuController.maybeOf() which is available in the widget tree
    final controller = MenuController.maybeOf(context);
    controller?.close();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final accent = widget.color ?? tokens.colors.primary;

    // Update disabled state based on enabled flag
    final states = _statesController.value;
    if (!widget.enabled && !states.contains(WidgetState.disabled)) {
      _statesController.update(WidgetState.disabled, true);
    } else if (widget.enabled && states.contains(WidgetState.disabled)) {
      _statesController.update(WidgetState.disabled, false);
    }

    final spec = LayrzDropdownEntryStyleSpec.resolve(
      enabled: widget.enabled,
      states: states,
      tokens: tokens,
      accent: accent,
    );

    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowHoverHighlight: (show) {
        _statesController.update(WidgetState.hovered, show);
      },
      onShowFocusHighlight: (show) {
        _statesController.update(WidgetState.focused, show);
      },
      child: MouseRegion(
        cursor: widget.enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: Listener(
          onPointerDown: (event) {
            if (widget.enabled) {
              _statesController.update(WidgetState.pressed, true);
            }
          },
          onPointerUp: (event) {
            _statesController.update(WidgetState.pressed, false);
          },
          onPointerCancel: (event) {
            _statesController.update(WidgetState.pressed, false);
          },
          child: GestureDetector(
            onTap: widget.enabled ? _onTap : null,
            child: Semantics(
              button: true,
              enabled: widget.enabled,
              label: widget.labelText,
              child: AnimatedContainer(
                duration: tokens.motion.dHover,
                curve: tokens.motion.easing,
                height: kLayrzDropdownEntryHeight,
                decoration: BoxDecoration(
                  color: spec.backgroundColor,
                  borderRadius: BorderRadius.circular(tokens.radius.r8),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: tokens.spacing.sp12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.icon != null) ...[
                        SizedBox(
                          width: kLayrzDropdownIconSize,
                          height: kLayrzDropdownIconSize,
                          child: Icon(
                            widget.icon,
                            size: kLayrzDropdownIconSize,
                            color: spec.iconColor,
                          ),
                        ),
                        SizedBox(width: tokens.spacing.sp8),
                      ],
                      Expanded(
                        child: Text(
                          widget.labelText,
                          style: tokens.typography.body.copyWith(
                            color: spec.labelColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
