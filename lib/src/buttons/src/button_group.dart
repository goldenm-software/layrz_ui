import 'package:flutter/widgets.dart';
import 'package:layrz_icons/layrz_icons.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/menus/menus.dart';
import 'package:layrz_ui/src/tokens/tokens.dart';

import 'button.dart';
import 'button_style.dart';
import 'button_type.dart';

/// A group of actions rendered as a row of buttons or, on narrow viewports,
/// as a single trigger button opening a dropdown menu.
///
/// [LayrzButtonGroup] manages responsive layout switching based on viewport width:
/// - **Row mode** (at or above md breakpoint): renders all [actions] as a horizontal row
/// - **Dropdown mode** (below md breakpoint): renders a single trigger opening a menu
///
/// The mode is driven by the nullable [useDropdown] parameter:
/// - `null` (default): switches automatically based on viewport
/// - `true`: always show dropdown mode
/// - `false`: always show row mode
///
/// Actions are expected to be [LayrzButton] instances whose semantic type,
/// color, icon, and enabled state are preserved when converted to dropdown entries.
/// A button's [LayrzButton.onTap] is called both in row and dropdown modes.
/// Dropdown entries close the menu automatically after tapping.
class LayrzButtonGroup extends StatelessWidget {
  /// The actions rendered by this group, in order.
  ///
  /// Must be a list of [LayrzButton] instances. The buttons are rendered directly
  /// in row mode and converted to dropdown entries in dropdown mode.
  /// An empty list renders nothing in both modes.
  final List<LayrzButton> actions;

  /// Forces the render mode. When null, the mode follows the responsive breakpoint,
  /// collapsing to the dropdown below `md`.
  ///
  /// - `true`: always render dropdown mode
  /// - `false`: always render row mode
  /// - `null` (default): switch automatically at the md breakpoint
  final bool? useDropdown;

  /// Gap between buttons in row mode. Defaults to `tokens.spacing.base`.
  ///
  /// Only applies in row mode. Unused in dropdown mode.
  final double? spacing;

  /// Icon shown on the collapsed trigger. Defaults to the overflow-dots icon.
  ///
  /// Only applies in dropdown mode. Mutually exclusive with [builder].
  final IconData? triggerIcon;

  /// Accessible name and tooltip for the collapsed trigger button.
  ///
  /// Shown as the trigger's tooltip on hover and announced by screen readers.
  /// Platform overflow menus render a stable control name rather than enumerating
  /// their contents, so this is required unconditionally — even though `useDropdown`
  /// defaults to null and the group may collapse at any viewport width, the caller
  /// always knows the semantic name to assign.
  ///
  /// Mutually exclusive with [builder].
  final String? triggerHintText;

  /// Builds the trigger widget for dropdown mode.
  ///
  /// The builder receives the menu [MenuController], which should be wired to the
  /// trigger's own tap handler for toggle behavior. The caller owns the entire
  /// trigger widget and its styling.
  ///
  /// **Critical: gesture-arena warning.** [LayrzButton] keeps a non-null
  /// `onTapCancel` even when disabled, which wins the gesture arena. If you wrap
  /// your trigger in a `GestureDetector`, it will silently never open the menu.
  /// Correct usage:
  /// ```dart
  /// builder: (context, controller) => MyCustomButton(
  ///   onTap: controller.isOpen ? controller.close : controller.open,
  /// )
  /// ```
  ///
  /// Not this:
  /// ```dart
  /// // WRONG: menu will never open because GestureDetector loses the gesture arena
  /// builder: (context, controller) => GestureDetector(
  ///   onTap: controller.isOpen ? controller.close : controller.open,
  ///   child: MyCustomButton(),
  /// )
  /// ```
  ///
  /// Only applies in dropdown mode. Mutually exclusive with [triggerIcon]
  /// and [triggerHintText].
  final LayrzDropdownMenuBuilder? builder;

  /// Horizontal alignment of the dropdown panel against the trigger.
  ///
  /// Defaults to [LayrzDropdownMenuAlignment.start].
  /// Only applies in dropdown mode.
  final LayrzDropdownMenuAlignment alignment;

  /// Creates a new [LayrzButtonGroup].
  ///
  /// The [actions] and [triggerHintText] parameters are required. All others
  /// are optional with sensible defaults.
  const LayrzButtonGroup({
    required this.actions,
    required this.triggerHintText,
    this.useDropdown,
    this.spacing,
    this.triggerIcon,
    this.alignment = LayrzDropdownMenuAlignment.start,
    super.key,
  }) : builder = null;

  /// Creates a [LayrzButtonGroup] with a caller-supplied trigger widget.
  ///
  /// The [builder] receives the menu [MenuController] and must wire it to the
  /// trigger's own tap handler. This allows the caller to supply any trigger
  /// widget and style it freely, unlike the default constructor which uses a
  /// hardcoded [LayrzButtonStyle.elevatedFab] trigger.
  ///
  /// In row mode, the builder is never called and the group renders its actions
  /// as usual. Set `useDropdown: false` to see only the row and skip the builder.
  /// At the md breakpoint (automatic mode, `useDropdown: null`), the group switches
  /// to dropdown mode and calls the builder.
  const LayrzButtonGroup.builder({
    required this.actions,
    required this.builder,
    this.useDropdown,
    this.spacing,
    this.alignment = LayrzDropdownMenuAlignment.start,
    super.key,
  }) : triggerHintText = null,
       triggerIcon = null;

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) {
      return const SizedBox.shrink();
    }

    final tokens = context.tokens;
    final collapse = useDropdown ?? context.breakpoint.index < LayrzBreakpoint.md.index;

    if (!collapse) {
      // Row mode: render all buttons in a wrap for responsive overflow
      return Wrap(
        spacing: spacing ?? tokens.spacing.base,
        children: actions,
      );
    }

    // Dropdown mode: convert buttons to entries
    final entries = actions.map((button) => _buttonToEntry(button, tokens)).toList();

    // If builder is provided, use it; otherwise use the default FAB trigger.
    // If builder is null, triggerHintText must be non-null (enforced by default constructor).
    final triggerBuilder = builder ??
        (context, controller) => LayrzButton(
          labelText: triggerHintText!,
          icon: triggerIcon ?? LayrzIcons.solarOutlineMenuDots,
          style: LayrzButtonStyle.elevatedFab,
          onTap: controller.isOpen ? controller.close : controller.open,
        );

    return LayrzDropdownMenu(
      alignment: alignment,
      items: entries,
      builder: triggerBuilder,
    );
  }

  /// Converts a [LayrzButton] to a [LayrzDropdownEntry] for the dropdown menu.
  ///
  /// The button's label, icon, semantic type, and enabled state are preserved.
  /// Semantic type colors are resolved via [LayrzButtonType.semanticColor];
  /// custom buttons without an explicit color render with no color dot.
  static LayrzDropdownEntry _buttonToEntry(LayrzButton button, LayrzTokens tokens) {
    final isDisabled = button.isDisabled || button.onTap == null;
    final entryColor = button.type.semanticColor(tokens) ?? button.color;

    return LayrzDropdownEntry(
      labelText: button.labelText,
      icon: button.icon,
      onTap: button.onTap ?? () {},
      enabled: !isDisabled,
      color: entryColor,
    );
  }
}
