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
/// - **Row mode** (at or above md breakpoint): renders [LayrzDropdownEntry] items as a horizontal row of labelled buttons
/// - **Dropdown mode** (below md breakpoint): renders a single trigger opening a menu with all items
///
/// The mode is driven by the nullable [useDropdown] parameter:
/// - `null` (default): switches automatically based on viewport
/// - `true`: always show dropdown mode
/// - `false`: always show row mode
///
/// Items are expected to be [LayrzDropdownItem] instances. In dropdown mode, all items
/// (both entries and labels) pass through to [LayrzDropdownMenu] unchanged. In row mode,
/// only [LayrzDropdownEntry] items are rendered as labelled [LayrzButton] instances;
/// [LayrzDropdownLabel] items are silently skipped. An entry's [LayrzDropdownEntry.onTap]
/// is called both in row and dropdown modes. Dropdown entries close the menu automatically after tapping.
class LayrzButtonGroup extends StatelessWidget {
  /// The items rendered by this group, in order.
  ///
  /// Must be a list of [LayrzDropdownItem] instances (either [LayrzDropdownEntry]
  /// or [LayrzDropdownLabel]). The items are rendered directly in dropdown mode
  /// and in row mode, [LayrzDropdownEntry] items are converted to labelled buttons
  /// while [LayrzDropdownLabel] items are skipped. An empty list renders nothing in both modes.
  final List<LayrzDropdownItem> items;

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
  /// The [items] and [triggerHintText] parameters are required. All others
  /// are optional with sensible defaults.
  const LayrzButtonGroup({
    required this.items,
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
  /// In row mode, the builder is never called and the group renders its items
  /// as usual. Set `useDropdown: false` to see only the row and skip the builder.
  /// At the md breakpoint (automatic mode, `useDropdown: null`), the group switches
  /// to dropdown mode and calls the builder.
  const LayrzButtonGroup.builder({
    required this.items,
    required this.builder,
    this.useDropdown,
    this.spacing,
    this.alignment = LayrzDropdownMenuAlignment.start,
    super.key,
  }) : triggerHintText = null,
       triggerIcon = null;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    final tokens = context.tokens;
    final collapse = useDropdown ?? context.breakpoint.index < LayrzBreakpoint.md.index;

    if (!collapse) {
      // Row mode: convert entries to buttons, skip labels
      final buttons = <Widget>[];
      for (final item in items) {
        if (item is LayrzDropdownEntry) {
          buttons.add(_entryToButton(item));
        }
        // Labels are silently skipped in row mode
      }

      if (buttons.isEmpty) {
        return const SizedBox.shrink();
      }

      return Wrap(
        spacing: spacing ?? tokens.spacing.base,
        children: buttons,
      );
    }

    // Dropdown mode: pass items through unchanged
    final triggerBuilder =
        builder ??
        (context, controller) => LayrzButton(
          labelText: triggerHintText!,
          icon: triggerIcon ?? LayrzIcons.solarOutlineMenuDots,
          style: LayrzButtonStyle.elevatedFab,
          onTap: controller.isOpen ? controller.close : controller.open,
        );

    return LayrzDropdownMenu(
      alignment: alignment,
      items: items,
      builder: triggerBuilder,
    );
  }

  /// Converts a [LayrzDropdownEntry] to a [LayrzButton] for row mode.
  ///
  /// The entry's label, icon, enabled state, and colour dot are converted to button properties.
  /// Shortcuts are dropped (LayrzButton has no shortcut field).
  /// The resulting button is labelled (non-Fab) and uses [LayrzButtonType.custom] with
  /// the entry's colour (if present) as the button colour.
  static LayrzButton _entryToButton(LayrzDropdownEntry entry) {
    final isDisabled = !entry.enabled;

    return LayrzButton(
      labelText: entry.labelText,
      icon: entry.icon,
      onTap: isDisabled ? null : entry.onTap,
      isDisabled: isDisabled,
      type: LayrzButtonType.custom,
      color: entry.color,
      style: LayrzButtonStyle.elevated,
    );
  }
}
