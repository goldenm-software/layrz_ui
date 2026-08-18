import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';
import 'package:layrz_icons/layrz_icons.dart';
import 'package:layrz_ui/preview.dart';

/// Preview of [LayrzButtonGroup] in row mode.
///
/// Displays multiple buttons horizontally with default spacing.
@Preview(name: 'Row', theme: LayrzPreviewTheme.light)
Widget previewLayrzButtonGroupRow() {
  return LayrzButtonGroup(
    actions: [
      LayrzButton(
        labelText: 'Save',
        type: LayrzButtonType.success,
        onTap: () {},
      ),
      LayrzButton(
        labelText: 'Edit',
        type: LayrzButtonType.warning,
        onTap: () {},
      ),
      LayrzButton(
        labelText: 'Delete',
        type: LayrzButtonType.danger,
        onTap: () {},
      ),
      LayrzButton(
        labelText: 'Cancel',
        type: LayrzButtonType.info,
        onTap: () {},
      ),
    ],
    useDropdown: false,
  );
}

/// Preview of [LayrzButtonGroup] in dropdown mode.
///
/// Displays a single trigger button that opens a menu with action entries.
@Preview(name: 'Dropdown', theme: LayrzPreviewTheme.light)
Widget previewLayrzButtonGroupDropdown() {
  return LayrzButtonGroup(
    actions: [
      LayrzButton(
        labelText: 'Save',
        type: LayrzButtonType.success,
        onTap: () {},
      ),
      LayrzButton(
        labelText: 'Edit',
        type: LayrzButtonType.warning,
        onTap: () {},
      ),
      LayrzButton(
        labelText: 'Delete',
        type: LayrzButtonType.danger,
        onTap: () {},
      ),
      LayrzButton(
        labelText: 'More info',
        type: LayrzButtonType.info,
        onTap: () {},
      ),
    ],
    useDropdown: true,
    triggerHintText: 'Actions',
    triggerIcon: LayrzIcons.solarOutlineMenuDots,
  );
}
