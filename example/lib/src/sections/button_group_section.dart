import 'package:flutter/widgets.dart';
import 'package:layrz_icons/layrz_icons.dart';
import 'package:layrz_ui/layrz_ui.dart';

import '../common/showroom_section.dart';

/// Displays [LayrzButtonGroup] in both row and dropdown modes.
///
/// Demonstrates responsive layout switching, semantic type preservation,
/// custom triggers, and custom spacing.
Widget buildButtonGroupSection() {
  return const _ButtonGroupSectionContent();
}

/// Stateless widget displaying [LayrzButtonGroup] examples.
class _ButtonGroupSectionContent extends StatelessWidget {
  /// Creates a new [_ButtonGroupSectionContent].
  const _ButtonGroupSectionContent();

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
          SizedBox(height: tokens.spacing.sp12),
          LayrzButtonGroup(
            triggerHintText: 'Table actions',
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
            ],
            useDropdown: false,
          ),

          SizedBox(height: tokens.spacing.sp32),

          // 2. Row mode with custom spacing
          _SectionHeader(label: 'Row Mode with Custom Spacing', tokens: tokens),
          SizedBox(height: tokens.spacing.sp12),
          LayrzButtonGroup(
            triggerHintText: 'Row actions',
            actions: [
              LayrzButton(
                labelText: 'Action 1',
                onTap: () {},
              ),
              LayrzButton(
                labelText: 'Action 2',
                onTap: () {},
              ),
              LayrzButton(
                labelText: 'Action 3',
                onTap: () {},
              ),
            ],
            useDropdown: false,
            spacing: 16,
          ),

          SizedBox(height: tokens.spacing.sp32),

          // 3. Dropdown mode with default trigger
          _SectionHeader(label: 'Dropdown Mode (Default Trigger)', tokens: tokens),
          SizedBox(height: tokens.spacing.sp12),
          LayrzButtonGroup(
            triggerHintText: 'Table actions',
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
            ],
            useDropdown: true,
          ),

          SizedBox(height: tokens.spacing.sp32),

          // 4. Dropdown mode with custom trigger
          _SectionHeader(label: 'Dropdown Mode (Custom Trigger)', tokens: tokens),
          SizedBox(height: tokens.spacing.sp12),
          LayrzButtonGroup(
            actions: [
              LayrzButton(
                labelText: 'Create',
                icon: LayrzIcons.solarOutlineAddCircle,
                type: LayrzButtonType.success,
                onTap: () {},
              ),
              LayrzButton(
                labelText: 'Duplicate',
                icon: LayrzIcons.solarOutlineClipboardList,
                type: LayrzButtonType.info,
                onTap: () {},
              ),
              LayrzButton(
                labelText: 'Archive',
                icon: LayrzIcons.solarOutlineCheckCircle,
                type: LayrzButtonType.warning,
                onTap: () {},
              ),
              LayrzButton(
                labelText: 'Remove',
                icon: LayrzIcons.solarOutlineTrashBinMinimalistic,
                type: LayrzButtonType.danger,
                onTap: () {},
              ),
            ],
            useDropdown: true,
            triggerHintText: 'More options',
            triggerIcon: LayrzIcons.solarOutlineMenuDots,
            alignment: LayrzDropdownMenuAlignment.end,
          ),

          SizedBox(height: tokens.spacing.sp32),

          // 5. Responsive mode (automatic switching)
          _SectionHeader(label: 'Responsive Mode (Automatic)', tokens: tokens),
          SizedBox(height: tokens.spacing.sp12),
          LayrzButtonGroup(
            triggerHintText: 'Workflow actions',
            actions: [
              LayrzButton(
                labelText: 'Approve',
                type: LayrzButtonType.success,
                onTap: () {},
              ),
              LayrzButton(
                labelText: 'Review',
                type: LayrzButtonType.info,
                onTap: () {},
              ),
              LayrzButton(
                labelText: 'Reject',
                type: LayrzButtonType.danger,
                onTap: () {},
              ),
            ],
            // useDropdown is null, so switches at md breakpoint
          ),

          SizedBox(height: tokens.spacing.sp12),
          Text(
            'Resize the viewport to see automatic switching between row mode (at md breakpoint and above) and dropdown mode (below md).',
            style: tokens.typography.body.copyWith(color: tokens.colors.fg3),
          ),

          SizedBox(height: tokens.spacing.sp32),

          // 6. Builder mode with custom-styled trigger
          _SectionHeader(label: 'Builder Mode (Custom Trigger)', tokens: tokens),
          SizedBox(height: tokens.spacing.sp12),
          LayrzButtonGroup.builder(
            actions: [
              LayrzButton(
                labelText: 'Create',
                icon: LayrzIcons.solarOutlineAddCircle,
                type: LayrzButtonType.success,
                onTap: () {},
              ),
              LayrzButton(
                labelText: 'Duplicate',
                icon: LayrzIcons.solarOutlineClipboardList,
                type: LayrzButtonType.info,
                onTap: () {},
              ),
              LayrzButton(
                labelText: 'Delete',
                icon: LayrzIcons.solarOutlineTrashBinMinimalistic,
                type: LayrzButtonType.danger,
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
            alignment: LayrzDropdownMenuAlignment.end,
          ),

          SizedBox(height: tokens.spacing.sp12),
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
