import 'package:flutter/widgets.dart';
import 'package:layrz_icons/layrz_icons.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../common/showroom_section.dart';

/// Builds the menus section for the showroom.
///
/// Demonstrates various dropdown menu configurations including basic usage,
/// mixed item types, disabled entries, and alignment variations.
Widget buildMenusSection() {
  return ShowroomSection(
    title: 'Menus',
    description: 'Dropdown menus with standardized rendering',
    child: Column(
      children: [
        // Basic dropdown menu
        _MenuShowcaseCard(
          title: 'Basic Menu',
          child: Center(
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
                  labelText: 'View',
                  onTap: () {},
                  icon: LayrzIcons.solarOutlineEyeScan,
                ),
              ],
              builder: (context, controller) => LayrzButton(
                labelText: 'Open Menu',
                onTap: controller.open,
              ),
            ),
          ),
        ),

        // Menu with mixed types
        _MenuShowcaseCard(
          title: 'Mixed Items (Labels, Dividers, Entries)',
          child: Center(
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
                LayrzDropdownEntry(
                  labelText: 'Duplicate',
                  onTap: () {},
                  icon: LayrzIcons.solarOutlineClipboardList,
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
          ),
        ),

        // Disabled entries
        _MenuShowcaseCard(
          title: 'Disabled Entry',
          child: Center(
            child: LayrzDropdownMenu(
              items: [
                LayrzDropdownEntry(
                  labelText: 'Available',
                  onTap: () {},
                  icon: LayrzIcons.solarOutlineAddCircle,
                ),
                LayrzDropdownEntry(
                  labelText: 'Not Available',
                  onTap: () {},
                  icon: LayrzIcons.solarOutlineCloseCircle,
                  enabled: false,
                ),
                LayrzDropdownEntry(
                  labelText: 'Also Available',
                  onTap: () {},
                  icon: LayrzIcons.solarOutlineCheckCircle,
                ),
              ],
              builder: (context, controller) => LayrzButton(
                labelText: 'With Disabled',
                onTap: controller.open,
              ),
            ),
          ),
        ),

        // Alignment variations
        _MenuShowcaseCard(
          title: 'Alignment Variations',
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Start', style: TextStyle(fontSize: 12)),
                  const SizedBox(height: 8),
                  LayrzDropdownMenu(
                    alignment: LayrzDropdownMenuAlignment.start,
                    items: [
                      LayrzDropdownEntry(
                        labelText: 'Option A',
                        onTap: () {},
                      ),
                      LayrzDropdownEntry(
                        labelText: 'Option B',
                        onTap: () {},
                      ),
                    ],
                    builder: (context, controller) => LayrzButton(
                      labelText: 'Left',
                      onTap: controller.open,
                    ),
                  ),
                ],
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Center', style: TextStyle(fontSize: 12)),
                  const SizedBox(height: 8),
                  LayrzDropdownMenu(
                    alignment: LayrzDropdownMenuAlignment.center,
                    items: [
                      LayrzDropdownEntry(
                        labelText: 'Option A',
                        onTap: () {},
                      ),
                      LayrzDropdownEntry(
                        labelText: 'Option B',
                        onTap: () {},
                      ),
                    ],
                    builder: (context, controller) => LayrzButton(
                      labelText: 'Center',
                      onTap: controller.open,
                    ),
                  ),
                ],
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('End', style: TextStyle(fontSize: 12)),
                  const SizedBox(height: 8),
                  LayrzDropdownMenu(
                    alignment: LayrzDropdownMenuAlignment.end,
                    items: [
                      LayrzDropdownEntry(
                        labelText: 'Option A',
                        onTap: () {},
                      ),
                      LayrzDropdownEntry(
                        labelText: 'Option B',
                        onTap: () {},
                      ),
                    ],
                    builder: (context, controller) => LayrzButton(
                      labelText: 'Right',
                      onTap: controller.open,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// A simple card widget for showcasing individual menu features within the menus section.
class _MenuShowcaseCard extends StatelessWidget {
  /// The title of the showcase card.
  final String title;

  /// The content displayed inside the card.
  final Widget child;

  /// Creates a new [_MenuShowcaseCard].
  const _MenuShowcaseCard({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Padding(
      padding: EdgeInsets.only(bottom: tokens.spacing.sp16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: tokens.typography.label),
          SizedBox(height: tokens.spacing.sp12),
          Container(
            padding: EdgeInsets.all(tokens.spacing.sp16),
            decoration: BoxDecoration(
              color: tokens.colors.surface2,
              borderRadius: BorderRadius.circular(tokens.radius.r8),
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}
