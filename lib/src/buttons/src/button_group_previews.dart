import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';
import 'package:layrz_icons/layrz_icons.dart';
import 'package:layrz_ui/layrz_ui.dart';
import 'package:layrz_ui/src/preview/preview.dart';

/// Preview of [LayrzButtonGroup] in row mode.
///
/// Displays multiple semantic buttons horizontally with default spacing.
/// Semantic factories preset the icon and colour dot to match the action's meaning.
@Preview(name: 'Row', theme: LayrzPreviewTheme.light)
Widget previewLayrzButtonGroupRow() {
  return LayrzButtonGroup(
    triggerHintText: 'Row actions',
    items: [
      LayrzDropdownEntry.save(
        labelText: 'Save',
        onTap: () {},
      ),
      LayrzDropdownEntry.edit(
        labelText: 'Edit',
        onTap: () {},
      ),
      LayrzDropdownEntry.delete(
        labelText: 'Delete',
        onTap: () {},
      ),
      LayrzDropdownEntry.info(
        labelText: 'Info',
        onTap: () {},
      ),
    ],
    useDropdown: false,
  );
}

/// Preview of [LayrzButtonGroup] in dropdown mode.
///
/// Displays a single trigger button that opens a menu with semantic entry items.
/// Labels can organize entries into logical sections; they render in dropdown mode
/// but are silently skipped in row mode.
@Preview(name: 'Dropdown', theme: LayrzPreviewTheme.light)
Widget previewLayrzButtonGroupDropdown() {
  return LayrzButtonGroup(
    items: [
      LayrzDropdownEntry.save(
        labelText: 'Save',
        onTap: () {},
      ),
      LayrzDropdownLabel(labelText: 'Modify'),
      LayrzDropdownEntry.edit(
        labelText: 'Edit',
        onTap: () {},
      ),
      LayrzDropdownLabel(labelText: 'Manage'),
      LayrzDropdownEntry.delete(
        labelText: 'Delete',
        onTap: () {},
      ),
      LayrzDropdownEntry.info(
        labelText: 'More info',
        onTap: () {},
      ),
    ],
    useDropdown: true,
    triggerHintText: 'Actions',
    triggerIcon: LayrzIcons.solarOutlineMenuDots,
  );
}

/// Preview of [LayrzButtonGroup.builder] with a custom-styled trigger.
///
/// Demonstrates how the builder pattern allows full control over the trigger's
/// appearance and behavior. This example uses an outlined FAB style instead of
/// the default elevated FAB.
@Preview(name: 'Builder (Custom Trigger)', theme: LayrzPreviewTheme.light)
Widget previewLayrzButtonGroupBuilder() {
  return LayrzButtonGroup.builder(
    items: [
      LayrzDropdownEntry.save(
        labelText: 'Create',
        icon: LayrzIcons.solarOutlineAddCircle,
        onTap: () {},
      ),
      LayrzDropdownEntry.info(
        labelText: 'Duplicate',
        icon: LayrzIcons.solarOutlineClipboardList,
        onTap: () {},
      ),
      LayrzDropdownEntry.edit(
        labelText: 'Archive',
        icon: LayrzIcons.solarOutlineCheckCircle,
        onTap: () {},
      ),
      LayrzDropdownEntry.delete(
        labelText: 'Delete',
        icon: LayrzIcons.solarOutlineTrashBinMinimalistic,
        onTap: () {},
      ),
    ],
    useDropdown: true,
    builder: (context, controller) => LayrzButton(
      labelText: 'Options',
      icon: LayrzIcons.solarOutlineSettings,
      style: LayrzButtonStyle.outlinedFab,
      onTap: controller.isOpen ? controller.close : controller.open,
    ),
  );
}
