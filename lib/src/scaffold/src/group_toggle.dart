import 'package:flutter/widgets.dart';
import 'package:layrz_icons/layrz_icons.dart';
import 'package:layrz_ui/src/constants/constants.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';

import 'group_mode.dart';

/// Private group toggle widget.
class GroupToggle extends StatelessWidget {
  /// The current group mode (grouped or flat).
  final LayrzScaffoldGroupMode groupMode;

  /// Callback fired when the group mode is changed.
  final ValueChanged<LayrzScaffoldGroupMode> onChanged;

  /// Creates a new [GroupToggle].
  const GroupToggle({
    super.key,
    required this.groupMode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    return Container(
      decoration: BoxDecoration(
        color: t.colors.surface3,
        borderRadius: BorderRadius.circular(kLayrzScaffoldToggleBorderRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ToggleSegment(
            icon: LayrzIcons.solarOutlineLayers,
            isActive: groupMode == LayrzScaffoldGroupMode.grouped,
            onTap: () => onChanged(LayrzScaffoldGroupMode.grouped),
          ),
          ToggleSegment(
            icon: LayrzIcons.solarOutlineList,
            isActive: groupMode == LayrzScaffoldGroupMode.flat,
            onTap: () => onChanged(LayrzScaffoldGroupMode.flat),
          ),
        ],
      ),
    );
  }
}

/// Private toggle segment widget.
class ToggleSegment extends StatelessWidget {
  /// The icon to display in this segment.
  final IconData icon;

  /// Whether this segment is currently active.
  final bool isActive;

  /// Callback fired when the segment is tapped.
  final VoidCallback onTap;

  /// Creates a new [ToggleSegment].
  const ToggleSegment({
    super.key,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isActive ? t.colors.surface : null,
          borderRadius: BorderRadius.circular(kLayrzScaffoldToggleBorderRadius - 2),
          boxShadow: isActive ? t.shadow.compact1 : null,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: kLayrzScaffoldToggleSegmentHorizontalPadding,
          vertical: kLayrzScaffoldToggleSegmentVerticalPadding,
        ),
        child: Icon(
          icon,
          size: 14,
          color: isActive ? t.colors.primary : t.colors.fg2,
        ),
      ),
    );
  }
}
