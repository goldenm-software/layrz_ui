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
  /// Only applies in dropdown mode.
  final IconData? triggerIcon;

  /// Tooltip text for the collapsed trigger.
  ///
  /// When provided, overrides the trigger button's tooltip.
  /// When null, the tooltip lists the action labels (one per line).
  /// Only applies in dropdown mode.
  final String? triggerHintText;

  /// Horizontal alignment of the dropdown panel against the trigger.
  ///
  /// Defaults to [LayrzDropdownMenuAlignment.start].
  /// Only applies in dropdown mode.
  final LayrzDropdownMenuAlignment alignment;

  /// Creates a new [LayrzButtonGroup].
  ///
  /// The [actions] parameter is required and provides the list of buttons.
  /// The [useDropdown], [spacing], [triggerIcon], and [triggerHintText] parameters
  /// are optional and have sensible defaults.
  /// The [alignment] parameter defaults to [LayrzDropdownMenuAlignment.start].
  const LayrzButtonGroup({
    required this.actions,
    this.useDropdown,
    this.spacing,
    this.triggerIcon,
    this.triggerHintText,
    this.alignment = LayrzDropdownMenuAlignment.start,
    super.key,
  });

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

    return LayrzDropdownMenu(
      alignment: alignment,
      items: entries,
      builder: (context, controller) => LayrzButton(
        labelText: triggerHintText ?? actions.map((a) => a.labelText).join('\n'),
        icon: triggerIcon ?? LayrzIcons.solarOutlineMenuDots,
        style: LayrzButtonStyle.elevatedFab,
        onTap: controller.isOpen ? controller.close : controller.open,
      ),
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
