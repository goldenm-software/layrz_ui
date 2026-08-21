import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../common/showroom_section.dart';

/// Stateless widget displaying [LayrzButtonGroup] examples.
class ButtonGroupSection extends StatelessWidget {
  /// Creates a new [ButtonGroupSection].
  const ButtonGroupSection({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return ShowroomSection(
      title: 'Button Groups',
      description: 'Responsive action groups that collapse to a dropdown menu on narrow viewports',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Row mode with default spacing
          _SectionHeader(label: 'Row Mode (Forced)', tokens: tokens),
          SizedBox(height: tokens.spacing.sp3),
          LayrzButtonGroup(
            triggerHintText: 'Table actions',
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
            ],
            useDropdown: false,
          ),

          SizedBox(height: tokens.spacing.sp5),

          // 2. Row mode with custom spacing
          _SectionHeader(label: 'Row Mode with Custom Spacing', tokens: tokens),
          SizedBox(height: tokens.spacing.sp3),
          LayrzButtonGroup(
            triggerHintText: 'Row actions',
            items: [
              LayrzDropdownEntry(
                labelText: 'Action 1',
                onTap: () {},
              ),
              LayrzDropdownEntry(
                labelText: 'Action 2',
                onTap: () {},
              ),
              LayrzDropdownEntry(
                labelText: 'Action 3',
                onTap: () {},
              ),
            ],
            useDropdown: false,
            spacing: 16,
          ),

          SizedBox(height: tokens.spacing.sp5),

          // 3. Dropdown mode with default trigger
          _SectionHeader(label: 'Dropdown Mode (Default Trigger)', tokens: tokens),
          SizedBox(height: tokens.spacing.sp3),
          LayrzButtonGroup(
            triggerHintText: 'Table actions',
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
            ],
            useDropdown: true,
          ),

          SizedBox(height: tokens.spacing.sp5),

          // 4. Dropdown mode with custom trigger
          _SectionHeader(label: 'Dropdown Mode (Custom Trigger)', tokens: tokens),
          SizedBox(height: tokens.spacing.sp3),
          LayrzButtonGroup(
            items: [
              LayrzDropdownEntry(
                labelText: 'Create',
                icon: MdiIcons.plusCircleOutline,
                onTap: () {},
              ),
              LayrzDropdownEntry(
                labelText: 'Duplicate',
                icon: MdiIcons.clipboardListOutline,
                onTap: () {},
              ),
              LayrzDropdownEntry(
                labelText: 'Archive',
                icon: MdiIcons.checkCircleOutline,
                onTap: () {},
              ),
              LayrzDropdownEntry(
                labelText: 'Remove',
                icon: MdiIcons.trashCanOutline,
                onTap: () {},
              ),
            ],
            useDropdown: true,
            triggerHintText: 'More options',
            triggerIcon: MdiIcons.dotsVertical,
            alignment: LayrzDropdownMenuAlignment.end,
          ),

          SizedBox(height: tokens.spacing.sp5),

          // 5. Responsive mode (automatic switching)
          _SectionHeader(label: 'Responsive Mode (Automatic)', tokens: tokens),
          SizedBox(height: tokens.spacing.sp3),
          LayrzButtonGroup(
            triggerHintText: 'Workflow actions',
            items: [
              LayrzDropdownEntry.save(
                labelText: 'Approve',
                onTap: () {},
              ),
              LayrzDropdownEntry(
                labelText: 'Review',
                onTap: () {},
              ),
              LayrzDropdownEntry.delete(
                labelText: 'Reject',
                onTap: () {},
              ),
            ],
            // useDropdown is null, so switches at md breakpoint
          ),

          SizedBox(height: tokens.spacing.sp3),
          Text(
            'Resize the viewport to see automatic switching between row mode (at md breakpoint and above) and dropdown mode (below md).',
            style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
          ),

          SizedBox(height: tokens.spacing.sp5),

          // 6. Builder mode with custom-styled trigger
          _SectionHeader(label: 'Builder Mode (Custom Trigger)', tokens: tokens),
          SizedBox(height: tokens.spacing.sp3),
          LayrzButtonGroup.builder(
            items: [
              LayrzDropdownEntry(
                labelText: 'Create',
                icon: MdiIcons.plusCircleOutline,
                onTap: () {},
              ),
              LayrzDropdownEntry(
                labelText: 'Duplicate',
                icon: MdiIcons.clipboardListOutline,
                onTap: () {},
              ),
              LayrzDropdownEntry(
                labelText: 'Delete',
                icon: MdiIcons.trashCanOutline,
                onTap: () {},
              ),
            ],
            useDropdown: true,
            builder: (context, controller) => LayrzButton(
              labelText: 'Options',
              icon: MdiIcons.cogOutline,
              style: LayrzButtonStyle.outlinedFab,
              onTap: controller.isOpen ? controller.close : controller.open,
            ),
            alignment: LayrzDropdownMenuAlignment.end,
          ),

          SizedBox(height: tokens.spacing.sp3),
          Text(
            'The builder pattern allows full control over the trigger widget\'s style and behavior. Here, the trigger uses an outlined style instead of the default elevated FAB.',
            style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
          ),
        ],
      ),
    );
  }
}

/// A helper widget for section headers within [LayrzButtonGroup] demonstrations.
class _SectionHeader extends StatelessWidget {
  /// The header text.
  final String label;

  /// The design tokens for consistent styling.
  final LayrzTokens tokens;

  /// Creates a new [_SectionHeader].
  const _SectionHeader({
    required this.label,
    required this.tokens,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: tokens.typography.label.copyWith(
        color: tokens.colors.fg2,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
