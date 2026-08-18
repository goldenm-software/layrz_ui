import 'package:flutter/widgets.dart';
import 'package:layrz_icons/layrz_icons.dart';
import 'package:layrz_ui/src/buttons/buttons.dart';

import 'dropdown_items.dart';
import 'dropdown_menu.dart';
import 'dropdown_menu_types.dart';

/// Preview function showing a simple dropdown menu with a closed state.
///
/// Displays the trigger button only, with the menu collapsed.
Widget previewDropdownMenuClosed() {
  return Center(
    child: LayrzDropdownMenu(
      items: [
        LayrzDropdownEntry(
          labelText: 'New Item',
          onTap: () {},
          icon: LayrzIcons.solarOutlineAddCircle,
        ),
        LayrzDropdownEntry(
          labelText: 'Edit',
          onTap: () {},
          icon: LayrzIcons.solarOutlinePenNewSquare,
        ),
        LayrzDropdownEntry(
          labelText: 'Delete',
          onTap: () {},
          icon: LayrzIcons.solarOutlineTrashBinMinimalistic,
        ),
      ],
      builder: (context, controller) => LayrzButton(
        labelText: 'Open Menu',
        onTap: controller.open,
      ),
    ),
  );
}

/// Preview function showing a dropdown menu with mixed item types.
///
/// Demonstrates labels, dividers, and entries together.
Widget previewDropdownMenuMixed() {
  return Center(
    child: LayrzDropdownMenu(
      items: [
        LayrzDropdownLabel(labelText: 'Management'),
        LayrzDropdownEntry(
          labelText: 'Create',
          onTap: () {},
          icon: LayrzIcons.solarOutlineAddCircle,
        ),
        LayrzDropdownEntry(
          labelText: 'Edit',
          onTap: () {},
          icon: LayrzIcons.solarOutlinePenNewSquare,
        ),
        LayrzDropdownDivider(),
        LayrzDropdownLabel(labelText: 'Danger'),
        LayrzDropdownEntry(
          labelText: 'Delete',
          onTap: () {},
          icon: LayrzIcons.solarOutlineTrashBinMinimalistic,
        ),
      ],
      builder: (context, controller) => LayrzButton(
        labelText: 'Actions',
        onTap: controller.open,
      ),
    ),
  );
}

/// Preview function showing menu alignments side by side.
///
/// Demonstrates start (left), center, and end (right) alignment modes.
Widget previewDropdownMenuAlignments() {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: [
      Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Start', style: TextStyle(fontSize: 12)),
          const SizedBox(height: 8),
          LayrzDropdownMenu(
            alignment: LayrzDropdownMenuAlignment.start,
            items: [
              LayrzDropdownEntry(
                labelText: 'Option 1',
                onTap: () {},
              ),
              LayrzDropdownEntry(
                labelText: 'Option 2',
                onTap: () {},
              ),
            ],
            builder: (context, controller) => LayrzButton(
              labelText: 'Menu',
              onTap: controller.open,
            ),
          ),
        ],
      ),
      Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Center', style: TextStyle(fontSize: 12)),
          const SizedBox(height: 8),
          LayrzDropdownMenu(
            alignment: LayrzDropdownMenuAlignment.center,
            items: [
              LayrzDropdownEntry(
                labelText: 'Option 1',
                onTap: () {},
              ),
              LayrzDropdownEntry(
                labelText: 'Option 2',
                onTap: () {},
              ),
            ],
            builder: (context, controller) => LayrzButton(
              labelText: 'Menu',
              onTap: controller.open,
            ),
          ),
        ],
      ),
      Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('End', style: TextStyle(fontSize: 12)),
          const SizedBox(height: 8),
          LayrzDropdownMenu(
            alignment: LayrzDropdownMenuAlignment.end,
            items: [
              LayrzDropdownEntry(
                labelText: 'Option 1',
                onTap: () {},
              ),
              LayrzDropdownEntry(
                labelText: 'Option 2',
                onTap: () {},
              ),
            ],
            builder: (context, controller) => LayrzButton(
              labelText: 'Menu',
              onTap: controller.open,
            ),
          ),
        ],
      ),
    ],
  );
}
