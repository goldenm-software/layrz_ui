import 'package:flutter/widgets.dart';
import 'package:layrz_ui/src/constants/constants.dart';
import 'package:layrz_ui/src/extensions/extensions.dart';

/// Private group header widget.
class GroupHeader extends StatelessWidget {
  /// The name of the group.
  final String groupName;

  /// Creates a new [GroupHeader].
  const GroupHeader({super.key, required this.groupName});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    return Container(
      color: t.colors.surface2,
      padding: const EdgeInsets.symmetric(
        vertical: kLayrzScaffoldGroupHeaderVerticalPadding,
        horizontal: kLayrzScaffoldGroupHeaderHorizontalPadding,
      ),
      child: Text(
        groupName,
        style: TextStyle(
          fontSize: kLayrzScaffoldGroupHeaderFontSize,
          fontWeight: FontWeight.w600,
          color: t.colors.fg3,
          letterSpacing: kLayrzScaffoldGroupHeaderLetterSpacing * kLayrzScaffoldGroupHeaderFontSize,
        ),
      ),
    );
  }
}
