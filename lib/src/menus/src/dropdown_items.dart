import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:layrz_icons/layrz_icons.dart';
import 'package:layrz_ui/src/constants/src/menu.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/keyboard/keyboard.dart';
import 'package:layrz_ui/src/platform/platform.dart';
import 'package:layrz_ui/src/tokens/tokens.dart';

import 'dropdown_entry_style_spec.dart';

/// Private enumeration for tracking semantic button types in dropdown entries.
///
/// This is intentionally private to avoid exposing a public API enum, as requested.
/// It is used internally to resolve semantic types to their corresponding token colors
/// at build time.
enum _SemanticType {
  /// Success semantic — use tokens.colors.success
  success,

  /// Danger semantic — use tokens.colors.danger
  danger,

  /// Info semantic — use tokens.colors.info
  info,

  /// Warning semantic — use tokens.colors.warning
  warning,

  /// No semantic type applied (custom or no color)
  none,
}

/// Extension on [_SemanticType] to resolve the semantic token color.
extension _SemanticTypeResolver on _SemanticType {
  /// Returns the token color for this semantic type, or null if none is applied.
  Color? resolveColor(LayrzTokens tokens) => switch (this) {
    _SemanticType.success => tokens.colors.success,
    _SemanticType.danger => tokens.colors.danger,
    _SemanticType.info => tokens.colors.info,
    _SemanticType.warning => tokens.colors.warning,
    _SemanticType.none => null,
  };
}

/// Single source of truth for an entry's accent colour resolution.
///
/// Explicit [color] wins; otherwise the semantic type resolves against tokens;
/// null when neither applies. This function is called by both the entry's own
/// dot rendering and the button conversion, ensuring they never disagree.
Color? _resolveEntryAccent(
  Color? color,
  _SemanticType semanticType,
  LayrzTokens tokens,
) =>
    color ?? semanticType.resolveColor(tokens);

/// Base class for items that a [LayrzDropdownMenu] can render.
///
/// Only two concrete types are allowed: [LayrzDropdownEntry] and [LayrzDropdownLabel].
/// Custom widget types is impossible by construction thanks to the sealed class guarantee.
/// This ensures standardization on rendering.
sealed class LayrzDropdownItem extends StatelessWidget {
  /// Creates a new [LayrzDropdownItem].
  const LayrzDropdownItem({super.key});

  /// Whether this item can receive focus and be activated via keyboard or mouse.
  ///
  /// - [LayrzDropdownEntry]: true if enabled
  /// - [LayrzDropdownLabel]: false (non-focusable section heading)
  bool get isFocusable;
}

/// A non-interactive section heading in a dropdown menu.
///
/// [LayrzDropdownLabel] renders plain-text labels as a full-width section band with
/// a [surface3] background (or tinted with an optional accent color). Text uses the
/// [LayrzTokens.typography.body] style in the subdued foreground color ([fg3]).
/// It is non-focusable and non-interactive.
/// Casing is determined by the caller — the widget does not uppercase or transform text.
final class LayrzDropdownLabel extends LayrzDropdownItem {
  /// The text displayed as the label.
  final String labelText;

  /// Optional colour used to tint the label's band.
  ///
  /// When null, the band keeps the neutral [LayrzColorTokens.surface3] fill, so
  /// menus written before this parameter existed are unchanged. When set, the band
  /// is filled with this colour at [LayrzColorTokens.tonalOpacity], flattened over
  /// the panel surface — the same treatment as [LayrzChipStyle.filledTonal].
  final Color? color;

  /// Creates a new [LayrzDropdownLabel].
  ///
  /// The [labelText] parameter is required and contains the section heading text.
  /// Text styling and case transformation are the caller's responsibility.
  /// The [color] parameter is optional and tints the band background.
  const LayrzDropdownLabel({
    required this.labelText,
    this.color,
    super.key,
  });

  @override
  bool get isFocusable => false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    final band = color == null
        ? tokens.colors.surface3
        : color!.withOpacityValue(tokens.colors.tonalOpacity).flattenOn(tokens.colors.surface);

    return Semantics(
      header: true,
      excludeSemantics: true,
      child: Container(
        color: band,
        padding: EdgeInsets.symmetric(
          horizontal: tokens.spacing.sp12,
          vertical: tokens.spacing.sp8,
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            labelText,
            style: tokens.typography.body.copyWith(
              color: tokens.colors.fg3,
            ),
          ),
        ),
      ),
    );
  }
}

/// An interactive entry in a dropdown menu.
///
/// [LayrzDropdownEntry] renders a selectable row with a label, optional icon,
/// optional color dot, and optional keyboard shortcut. Interaction states (hovered,
/// pressed, focused) only change color, background, and icon color — geometry is fixed
/// per decision D15.
///
/// When tapped, [onTap] is called exactly once, and the menu automatically closes.
/// When [enabled] is false, the entry is visually and interactively disabled.
///
/// The color dot (when [color] is non-null) serves as a visual indicator: it echoes
/// the accent color of the action represented by the entry. The dot is independent
/// from the icon — an entry may have a dot, an icon, both, or neither.
///
/// The shortcut is display-only and never binds keys. It is formatted for the current
/// platform and renders right-aligned as muted text. On mobile platforms (iOS/Android),
/// the shortcut is hidden entirely (no reserved space).
///
/// Semantic factories (`.save()`, `.cancel()`, `.info()`, `.show()`, `.edit()`, `.delete()`)
/// provide convenience constructors that preset the icon and semantic color to match
/// [LayrzButton]'s semantic factories. These factories do not expose an enum; the semantic
/// type is resolved to a token color at build time.
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

  /// Optional colour that paints the leading dot of this entry.
  ///
  /// When null, no dot is rendered. When non-null, a small circular dot is displayed
  /// at the left edge of the entry using this exact color. The dot is independent
  /// from the icon and appears alongside or in place of it.
  ///
  /// This is a paint-only property; it does not affect backgrounds, text, or other
  /// entry styling.
  final Color? color;

  /// Optional keyboard shortcut keys displayed right-aligned in the entry.
  ///
  /// A set of [LogicalKeyboardKey] values (typically modifiers like [LogicalKeyboardKey.control]
  /// and a key like [LogicalKeyboardKey.keyS]). The set is formatted using [formatLayrzShortcut]
  /// for display.
  ///
  /// This is display-only and never binds any keys. The application owns all keyboard binding.
  /// When [LayrzPlatform.isMobile] is true, the shortcut is hidden entirely (no reserved space).
  final Set<LogicalKeyboardKey>? shortcut;

  /// Private field tracking the semantic type, used to resolve token colors at build time.
  ///
  /// When a semantic factory is used (e.g., `.save()`, `.delete()`), this field is set
  /// to indicate which semantic type the entry represents. At build time, this is resolved
  /// to the corresponding token color. This field is intentionally private to avoid
  /// exposing the internal semantic type enum in the public API.
  final _SemanticType _semanticType;

  /// Creates a new [LayrzDropdownEntry].
  ///
  /// The [labelText], [onTap], and [key] parameters are required.
  /// [icon], [enabled], [color], and [shortcut] are optional.
  const LayrzDropdownEntry({
    required this.labelText,
    required this.onTap,
    this.icon,
    this.enabled = true,
    this.color,
    this.shortcut,
    super.key,
  }) : _semanticType = _SemanticType.none;

  /// Private named constructor for semantic factories.
  ///
  /// Used internally by the semantic factory constructors to set the [_semanticType]
  /// field, which is resolved to a token color at build time.
  const LayrzDropdownEntry._semantic({
    required this.labelText,
    required this.onTap,
    this.icon,
    required this.enabled,
    this.color,
    this.shortcut,
    required _SemanticType semanticType,
    super.key,
    // ignore: prefer_initializing_formals
  }) : _semanticType = semanticType;

  /// Creates a save entry with success accent and icon.
  ///
  /// The entry is preset with:
  /// - Icon: [LayrzIcons.solarOutlineInboxIn]
  /// - Color: [LayrzTokens.colors.success]
  ///
  /// The [labelText], [onTap], and [key] parameters are required.
  /// All other parameters are optional and behave the same as the main constructor.
  /// The [icon] and [color] parameters can override the preset values if desired.
  factory LayrzDropdownEntry.save({
    required String labelText,
    required VoidCallback onTap,
    IconData? icon,
    bool enabled = true,
    Color? color,
    Set<LogicalKeyboardKey>? shortcut,
    Key? key,
  }) {
    return LayrzDropdownEntry._semantic(
      key: key,
      labelText: labelText,
      icon: icon ?? LayrzIcons.solarOutlineInboxIn,
      onTap: onTap,
      enabled: enabled,
      color: color,
      shortcut: shortcut,
      semanticType: _SemanticType.success,
    );
  }

  /// Creates a cancel entry with danger accent and icon.
  ///
  /// The entry is preset with:
  /// - Icon: [LayrzIcons.solarOutlineCloseSquare]
  /// - Color: [LayrzTokens.colors.danger]
  ///
  /// The [labelText], [onTap], and [key] parameters are required.
  /// All other parameters are optional and behave the same as the main constructor.
  /// The [icon] and [color] parameters can override the preset values if desired.
  factory LayrzDropdownEntry.cancel({
    required String labelText,
    required VoidCallback onTap,
    IconData? icon,
    bool enabled = true,
    Color? color,
    Set<LogicalKeyboardKey>? shortcut,
    Key? key,
  }) {
    return LayrzDropdownEntry._semantic(
      key: key,
      labelText: labelText,
      icon: icon ?? LayrzIcons.solarOutlineCloseSquare,
      onTap: onTap,
      enabled: enabled,
      color: color,
      shortcut: shortcut,
      semanticType: _SemanticType.danger,
    );
  }

  /// Creates an info entry with info accent and icon.
  ///
  /// The entry is preset with:
  /// - Icon: [LayrzIcons.solarOutlineInfoSquare]
  /// - Color: [LayrzTokens.colors.info]
  ///
  /// The [labelText], [onTap], and [key] parameters are required.
  /// All other parameters are optional and behave the same as the main constructor.
  /// The [icon] and [color] parameters can override the preset values if desired.
  factory LayrzDropdownEntry.info({
    required String labelText,
    required VoidCallback onTap,
    IconData? icon,
    bool enabled = true,
    Color? color,
    Set<LogicalKeyboardKey>? shortcut,
    Key? key,
  }) {
    return LayrzDropdownEntry._semantic(
      key: key,
      labelText: labelText,
      icon: icon ?? LayrzIcons.solarOutlineInfoSquare,
      onTap: onTap,
      enabled: enabled,
      color: color,
      shortcut: shortcut,
      semanticType: _SemanticType.info,
    );
  }

  /// Creates a show entry with info accent and icon.
  ///
  /// The entry is preset with:
  /// - Icon: [LayrzIcons.solarOutlineEyeScan]
  /// - Color: [LayrzTokens.colors.info]
  ///
  /// The [labelText], [onTap], and [key] parameters are required.
  /// All other parameters are optional and behave the same as the main constructor.
  /// The [icon] and [color] parameters can override the preset values if desired.
  factory LayrzDropdownEntry.show({
    required String labelText,
    required VoidCallback onTap,
    IconData? icon,
    bool enabled = true,
    Color? color,
    Set<LogicalKeyboardKey>? shortcut,
    Key? key,
  }) {
    return LayrzDropdownEntry._semantic(
      key: key,
      labelText: labelText,
      icon: icon ?? LayrzIcons.solarOutlineEyeScan,
      onTap: onTap,
      enabled: enabled,
      color: color,
      shortcut: shortcut,
      semanticType: _SemanticType.info,
    );
  }

  /// Creates an edit entry with warning accent and icon.
  ///
  /// The entry is preset with:
  /// - Icon: [LayrzIcons.solarOutlinePenNewSquare]
  /// - Color: [LayrzTokens.colors.warning]
  ///
  /// The [labelText], [onTap], and [key] parameters are required.
  /// All other parameters are optional and behave the same as the main constructor.
  /// The [icon] and [color] parameters can override the preset values if desired.
  factory LayrzDropdownEntry.edit({
    required String labelText,
    required VoidCallback onTap,
    IconData? icon,
    bool enabled = true,
    Color? color,
    Set<LogicalKeyboardKey>? shortcut,
    Key? key,
  }) {
    return LayrzDropdownEntry._semantic(
      key: key,
      labelText: labelText,
      icon: icon ?? LayrzIcons.solarOutlinePenNewSquare,
      onTap: onTap,
      enabled: enabled,
      color: color,
      shortcut: shortcut,
      semanticType: _SemanticType.warning,
    );
  }

  /// Creates a delete entry with danger accent and icon.
  ///
  /// The entry is preset with:
  /// - Icon: [LayrzIcons.solarOutlineTrashBinMinimalisticN2]
  /// - Color: [LayrzTokens.colors.danger]
  ///
  /// The [labelText], [onTap], and [key] parameters are required.
  /// All other parameters are optional and behave the same as the main constructor.
  /// The [icon] and [color] parameters can override the preset values if desired.
  factory LayrzDropdownEntry.delete({
    required String labelText,
    required VoidCallback onTap,
    IconData? icon,
    bool enabled = true,
    Color? color,
    Set<LogicalKeyboardKey>? shortcut,
    Key? key,
  }) {
    return LayrzDropdownEntry._semantic(
      key: key,
      labelText: labelText,
      icon: icon ?? LayrzIcons.solarOutlineTrashBinMinimalisticN2,
      onTap: onTap,
      enabled: enabled,
      color: color,
      shortcut: shortcut,
      semanticType: _SemanticType.danger,
    );
  }

  @override
  bool get isFocusable => enabled;

  /// Resolves this entry's accent colour against [tokens].
  ///
  /// Returns the semantic token colour when the entry came from a semantic
  /// factory (`.save()`, `.cancel()`, etc.), the explicit [color] when one
  /// was supplied, or null when the entry carries no colour at all.
  ///
  /// The precedence is: explicit [color] takes priority over semantic type.
  /// This method is used both by the entry's own dot rendering and by the
  /// row-mode button conversion, ensuring they never disagree.
  Color? resolveAccent(LayrzTokens tokens) => _resolveEntryAccent(color, _semanticType, tokens);

  @override
  Widget build(BuildContext context) => _LayrzDropdownEntryWidget(
    labelText: labelText,
    onTap: onTap,
    icon: icon,
    enabled: enabled,
    color: color,
    shortcut: shortcut,
    semanticType: _semanticType,
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

  /// Optional colour that paints the leading dot of this entry.
  final Color? color;

  /// Optional keyboard shortcut keys displayed right-aligned.
  final Set<LogicalKeyboardKey>? shortcut;

  /// Private field tracking the semantic type.
  final _SemanticType semanticType;

  /// Creates a new [_LayrzDropdownEntryWidget].
  const _LayrzDropdownEntryWidget({
    required this.labelText,
    required this.onTap,
    this.icon,
    required this.enabled,
    this.color,
    this.shortcut,
    required this.semanticType,
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
    _statesController.addListener(_onStatesChanged);
  }

  @override
  void dispose() {
    _statesController.removeListener(_onStatesChanged);
    _statesController.dispose();
    super.dispose();
  }

  /// Rebuilds the widget when the states controller changes.
  ///
  /// This ensures that hover, press, and focus state changes trigger a repaint
  /// with the updated colors and visual styles. Guarded against setState after unmount.
  void _onStatesChanged() {
    if (!mounted) return;
    setState(() {});
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
    );

    // Resolve the color dot through the same logic as resolveAccent()
    final dotColor = _resolveEntryAccent(widget.color, widget.semanticType, tokens);

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
              excludeSemantics: true,
              child: AnimatedContainer(
                duration: tokens.motion.dHover,
                curve: tokens.motion.easing,
                height: kLayrzDropdownEntryHeight,
                decoration: BoxDecoration(
                  color: spec.backgroundColor,
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: tokens.spacing.sp12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Color dot (left-aligned, when color is set)
                      if (dotColor != null) ...[
                        Container(
                          width: kLayrzDropdownDotSize,
                          height: kLayrzDropdownDotSize,
                          decoration: BoxDecoration(
                            color: dotColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: tokens.spacing.sp8),
                      ],
                      // Icon (when present)
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
                      // Label (expanded to fill available space)
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
                      // Shortcut (right-aligned, hidden on mobile)
                      if (widget.shortcut != null && !LayrzPlatform.isMobile) ...[
                        SizedBox(width: tokens.spacing.sp8),
                        Text(
                          formatLayrzShortcut(widget.shortcut),
                          style: tokens.typography.label.copyWith(
                            color: tokens.colors.fg3,
                          ),
                        ),
                      ],
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
